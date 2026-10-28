import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/data/repositories/custom_library_repository.dart';
import 'package:toneharbor/data/repositories/song_repository.dart';
import 'package:toneharbor/core/utils/platform_utils.dart';

void main() {
  test('early bulk import retains saved library and emits one update',
      () async {
    SharedPreferences.setMockInitialValues({
      'custom_music_files': ['saved.mp3'],
      'custom_music_folders': ['Saved music'],
      'custom_music_excluded': ['restored.mp3', 'hidden.mp3'],
    });
    final library = CustomLibraryNotifier();
    addTearDown(library.dispose);
    var updates = 0;
    library.addListener((_) => updates++, fireImmediately: false);
    // Start before initial preferences have completed.
    final importing = library.addFiles([
      for (var i = 0; i < 100; i++) 'batch-$i.mp3',
      'restored.mp3',
      'restored.mp3',
      'saved.mp3',
    ]);
    await library.ready;
    updates = 0;
    await importing;
    expect(updates, 1);
    expect(library.state.files, hasLength(102));
    expect(library.state.files, contains('saved.mp3'));
    expect(library.state.folders, ['Saved music']);
    expect(library.state.excludedFiles.map(normalizePath), ['hidden.mp3']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('custom_music_files'), library.state.files);
    final before = updates;
    await library.addFiles(['saved.mp3', 'restored.mp3']);
    expect(updates, before, reason: 'Duplicate imports should not rescan');
    final reloaded = CustomLibraryNotifier();
    addTearDown(reloaded.dispose);
    await reloaded.ready;
    expect(reloaded.state.files, library.state.files);
    expect(reloaded.state.excludedFiles, library.state.excludedFiles);
  });

  test('bulk import skips directories and merges overlapping imports',
      () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('harbor-import-');
    addTearDown(() => directory.delete(recursive: true));
    final library = CustomLibraryNotifier();
    addTearDown(library.dispose);
    await Future.wait([
      library.addFiles([directory.path, 'one.mp3', 'two.mp3']),
      library.addFiles(['two.mp3', 'three.mp3']),
    ]);
    expect(library.state.files.toSet(), {'one.mp3', 'two.mp3', 'three.mp3'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('custom_music_files')!.toSet(),
        library.state.files.toSet());
  });

  test('excluded track remains on disk and can be discovered and restored',
      () async {
    SharedPreferences.setMockInitialValues({});
    final directory =
        await Directory.systemTemp.createTemp('toneharbor-library-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}sample.mp3');
    await file.writeAsString('test data');
    final library = CustomLibraryNotifier();
    addTearDown(library.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await library.addFile(file.path);
    await library.excludeFile(file.path);
    expect(await file.exists(), isTrue);
    expect(library.state.excludedFiles, isNotEmpty);
    final found = await getExcludedSongsOnDevice(library.state.excludedFiles);
    expect(found, hasLength(1));
    await library.addFile(found.single.data);
    expect(library.state.excludedFiles, isEmpty);
    expect(library.state.files, isNotEmpty);
    expect(await file.exists(), isTrue);
  });
}
