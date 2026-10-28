import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/features/desktop/harbor_batch_studio.dart';
import 'package:toneharbor/features/desktop/harbor_media_engine.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/features/desktop/harbor_themes.dart';
import 'package:toneharbor/features/library/widgets/restore_excluded_sheet.dart';
import 'package:toneharbor/l10n/app_localizations.dart';
import 'package:toneharbor/services/audio/audio_player_service.dart';

class _OutputPicker extends FilePicker {
  final String folder;
  _OutputPicker(this.folder);
  @override
  Future<String?> getDirectoryPath(
          {String? dialogTitle,
          bool lockParentWindow = false,
          String? initialDirectory}) async =>
      folder;
}

class _Player extends StateNotifier<PlayerState>
    implements AudioPlayerNotifier {
  _Player() : super(const PlayerState());
  @override
  Future<void> playSong(SongModel song,
      {List<SongModel>? queue, int index = 0}) async {
    state = state.copyWith(queue: queue ?? [song], currentIndex: index);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('completed video conversion exposes playback of the exact output',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late Directory folder;
    late String input;
    await tester.runAsync(() async {
      folder = await Directory.systemTemp.createTemp('toneharbor-output-ui-');
      input = '${folder.path}/source.mp4';
      final generated = await Process.run(HarborMediaEngine.executable(), [
        '-hide_banner',
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'color=c=black:s=32x32:r=10',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440',
        '-t',
        '0.4',
        '-c:v',
        'mpeg4',
        '-c:a',
        'aac',
        input
      ]);
      expect(generated.exitCode, 0, reason: '${generated.stderr}');
    });
    FilePicker.platform = _OutputPicker(folder.path);
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    final player = _Player();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          audioPlayerProvider.overrideWith((_) => player),
        ],
        child: MaterialApp(
            theme: buildHarborTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: HarborBatchStudio(initialFile: input)))));
    await tester.pumpAndSettle();
    expect(find.text('Play audio'), findsNothing);
    await tester.ensureVisible(find.text('Convert all'));
    await tester.tap(find.text('Convert all'));
    for (var i = 0;
        i < 100 && find.text('Play audio').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Play audio'), findsOneWidget);
    await tester.ensureVisible(find.text('Play audio'));
    await tester.tap(find.text('Play audio'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(player.state.currentSong?.data, endsWith('source_toneharbor.mp3'));
    expect(player.state.queue.length, 1);
    expect(player.state.currentSong?.data, isNot(input));
    expect(File(player.state.currentSong!.data).existsSync(), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.runAsync(() async {
      expect(folder.path, contains('toneharbor-output-ui-'));
      await folder.delete(recursive: true);
    });
  });

  testWidgets(
      'restore action uses a muted surface and returns the selected tracks',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final song = SongModel(
        id: 1,
        title: 'Hidden track',
        artist: 'Artist',
        album: '',
        data: 'hidden.mp3',
        duration: 2000,
        dateAdded: 1);
    List<SongModel>? restored;
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            theme: buildHarborTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () async {
                          restored =
                              await RestoreExcludedSheet.show(context, [song]);
                        },
                        child: const Text('Restore')))))));
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    final button = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('restore-library-action')));
    final background = button.style!.backgroundColor!.resolve({});
    expect(background, isNot(HarborTheme.forest.accent));
    expect(background!.computeLuminance(), lessThan(.12));
    await tester.tap(find.byKey(const ValueKey('restore-library-action')));
    await tester.pumpAndSettle();
    expect(restored?.single.data, song.data);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
