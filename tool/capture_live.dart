// Development entry point: real Windows app, native audio, disk-backed data.
// No widget-test bindings, mock playback, fake waveforms or user library access.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';
import 'package:window_manager/window_manager.dart';
import 'package:toneharbor/main.dart' as app;
import 'package:toneharbor/core/router.dart';
import 'package:toneharbor/core/localization/locale_provider.dart';
import 'package:toneharbor/data/database/isar_service.dart';
import 'package:toneharbor/data/repositories/song_repository.dart';
import 'package:toneharbor/data/repositories/playlist_repository.dart';
import 'package:toneharbor/data/repositories/favorites_repository.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/features/desktop/harbor_waveform.dart';
import 'package:toneharbor/services/audio/audio_player_service.dart';

late Directory _root;

/// Redirect real disk-backed storage; never open the user's database/preferences.
class _CapturePaths extends PathProviderWindows {
  Future<String> folder(String name) async =>
      (await Directory(p.join(_root.path, name)).create(recursive: true)).path;
  @override
  Future<String?> getApplicationDocumentsPath() => folder('database');
  @override
  Future<String?> getApplicationSupportPath() => folder('preferences');
  @override
  Future<String?> getApplicationCachePath() => folder('cache');
  @override
  Future<String?> getTemporaryPath() => folder('temporary');
  @override
  Future<String?> getDownloadsPath() => folder('Downloads');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = Platform.environment['HARBOR_CAPTURE_ROOT'];
  if (directory == null || directory.isEmpty) {
    throw StateError(
      'HARBOR_CAPTURE_ROOT is required for isolated live capture',
    );
  }
  _root = Directory(p.normalize(p.absolute(directory)));
  // The normal scanner uses USERPROFILE for Music/Downloads. Require the same
  // isolated root before starting any production repositories.
  if (p.normalize(Platform.environment['USERPROFILE'] ?? '').toLowerCase() !=
      _root.path.toLowerCase()) {
    throw StateError(
      'USERPROFILE must point to the isolated capture directory',
    );
  }
  await _root.create(recursive: true);
  final paths = _CapturePaths();
  PathProviderPlatform.instance = paths;
  final preferences = SharedPreferencesWindows()..pathProvider = paths;
  SharedPreferencesStorePlatform.instance = preferences;
  final prefs = await SharedPreferences.getInstance();
  final media = Directory(p.join(_root.path, 'media'));
  final files =
      media
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.mp3'))
          .map((file) => file.path)
          .toList()
        ..sort();
  if (files.length < 6) {
    throw StateError('Generate at least six demo audio files');
  }
  await prefs.setString('app_locale', 'en');
  await prefs.setString('harbor_theme', 'ocean');
  await prefs.setBool('harbor_ocean_default_v1', true);
  await prefs.setStringList('custom_music_files', files);
  await app.startToneHarbor(wrap: (child) => _CaptureRoot(child: child));
}

class _CaptureRoot extends StatefulWidget {
  final Widget child;
  const _CaptureRoot({required this.child});
  @override
  State<_CaptureRoot> createState() => _CaptureRootState();
}

class _CaptureRootState extends State<_CaptureRoot> {
  final _boundary = GlobalKey();
  final _records = <Map<String, Object?>>[];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  BuildContext? _shell() {
    BuildContext? result;
    void visit(Element element) {
      if (element.widget is ToneHarborDesktop) {
        result = element;
        return;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  Future<void> _settle([int milliseconds = 1500]) async {
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _save(String name) async {
    await _settle();
    final box =
        _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await box.toImage(pixelRatio: 1.5);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File(p.join(_root.path, 'screenshots', '$name.png'));
      await output.parent.create(recursive: true);
      await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      _records.add({
        'file': '$name.png',
        'width': image.width,
        'height': image.height,
        'source': 'running Windows application',
        'audio': 'generated demo audio decoded by native playback/FFmpeg',
      });
    } finally {
      image.dispose();
    }
  }

  Future<void> _capture() async {
    try {
      BuildContext? shell;
      for (var i = 0; i < 120 && shell == null; i++) {
        await _settle(250);
        shell = _shell();
      }
      if (shell == null) throw StateError('Application did not initialize');
      if (!shell.mounted) return;
      final container = ProviderScope.containerOf(shell, listen: false);
      final songs = await container.read(songLibraryProvider.future);
      if (songs.length < 6) {
        throw StateError('Demo audio library was not scanned');
      }
      await container
          .read(favoritesProvider.notifier)
          .setMany(songs.take(3).map((s) => s.id), true);
      final playlists = container.read(playlistRepositoryProvider.notifier);
      await playlists.refresh();
      final existing =
          container.read(playlistRepositoryProvider).valueOrNull ?? [];
      for (final name in [
        'Evening Sessions',
        'Deep Listening',
        'Quiet Moments',
        'Studio Picks',
        'Morning Light',
        'بين السكون والصدى',
      ]) {
        if (!existing.any((playlist) => playlist.name == name)) {
          await playlists.createPlaylist(name);
        }
      }
      for (final playlist
          in container.read(playlistRepositoryProvider).valueOrNull ?? []) {
        if (playlist.name != 'system_recently_played') {
          await playlists.addSongs(playlist.id, songs.take(6).map((s) => s.id));
        }
      }
      final player = container.read(audioPlayerProvider.notifier);
      await player.setVolume(0);
      for (final song in songs.take(3)) {
        await player.playSong(song, queue: songs, index: songs.indexOf(song));
        await _settle(200);
      }
      await player.seek(const Duration(seconds: 48));
      await player.pause();
      await player.setVolume(.7);
      final router = container.read(routerProvider);
      for (final page in [
        (AppRoutes.home, 'home'),
        (AppRoutes.library, 'library'),
        (AppRoutes.desktopPlayer, 'full-player'),
        (AppRoutes.playlists, 'playlists'),
        (AppRoutes.settings, 'settings'),
      ]) {
        router.go(page.$1);
        await _save(page.$2);
      }
      final editorSong = songs.reduce(
        (a, b) => a.duration < b.duration ? a : b,
      );
      router.go(AppRoutes.editor, extra: editorSong);
      // The editor route uses its existing initial-file contract.
      await _settle(500);
      final overview = await container
          .read(waveformProvider(editorSong.data).future)
          .timeout(const Duration(minutes: 2));
      if (overview.isEmpty) throw StateError('Editor waveform did not decode');
      await _save('audio-editor');
      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('ar'));
      router.go(AppRoutes.home);
      await _save('home-ar');
      await File(p.join(_root.path, 'capture.json')).writeAsString(
        const JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'complete', 'captures': _records}),
        flush: true,
      );
      await player.pause();
      await IsarService.close();
      await windowManager.close();
    } catch (error, stack) {
      await File(p.join(_root.path, 'capture.json')).writeAsString(
        jsonEncode({
          'status': 'error',
          'error': '$error',
          'stack': '$stack',
          'captures': _records,
        }),
        flush: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: _boundary, child: widget.child);
}
