import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:collection';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/data/models/playlist_model.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/data/repositories/playlist_repository.dart';
import 'package:toneharbor/data/repositories/song_repository.dart';
import 'package:toneharbor/data/repositories/favorites_repository.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/features/desktop/harbor_studio.dart';
import 'package:toneharbor/features/desktop/harbor_mini_player.dart';
import 'package:toneharbor/features/desktop/harbor_playlists.dart';
import 'package:toneharbor/features/desktop/harbor_themes.dart';
import 'package:toneharbor/features/desktop/harbor_settings.dart';
import 'package:toneharbor/features/desktop/harbor_shortcuts.dart';
import 'dart:convert';
import 'package:toneharbor/features/desktop/harbor_waveform.dart';
import 'package:toneharbor/features/desktop/harbor_track_list.dart';
import 'package:toneharbor/core/utils/app_toast.dart';
import 'package:toneharbor/l10n/app_localizations.dart';
import 'package:toneharbor/services/audio/audio_player_service.dart';

class _Player extends StateNotifier<PlayerState>
    implements AudioPlayerNotifier {
  _Player() : super(const PlayerState());
  @override
  Future<void> playSong(
    SongModel song, {
    List<SongModel>? queue,
    int index = 0,
  }) async {
    selectForTest(queue ?? [song], index);
  }

  void selectForTest(List<SongModel> songs, int index, {bool preview = false}) {
    state = state.copyWith(
      queue: songs,
      currentIndex: index,
      duration: Duration(milliseconds: songs[index].duration),
      position: preview ? const Duration(seconds: 48) : Duration.zero,
      isPlaying: preview,
    );
  }

  @override
  void setSleepBoundary({bool track = false, bool queue = false}) {}
  @override
  Future<void> setVolume(double volume) async =>
      state = state.copyWith(volume: volume);
  @override
  Future<void> seek(Duration position) async =>
      state = state.copyWith(position: position);
  @override
  void toggleRepeatMode() => state = state.copyWith(
    repeatMode: RepeatState
        .values[(state.repeatMode.index + 1) % RepeatState.values.length],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Playlists extends StateNotifier<AsyncValue<List<PlaylistModel>>>
    implements PlaylistRepositoryNotifier {
  _Playlists() : super(const AsyncData([]));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PlaylistsWithData extends StateNotifier<AsyncValue<List<PlaylistModel>>>
    implements PlaylistRepositoryNotifier {
  _PlaylistsWithData()
    : super(
        AsyncData([
          PlaylistModel()
            ..id = 42
            ..name = 'My collection'
            ..createdAt = DateTime(2026)
            ..songIds = [1, 2],
        ]),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecentPlaylists extends StateNotifier<AsyncValue<List<PlaylistModel>>>
    implements PlaylistRepositoryNotifier {
  _RecentPlaylists()
    : super(
        AsyncData([
          PlaylistModel()
            ..id = 50
            ..name = 'system_recently_played'
            ..createdAt = DateTime(2026)
            ..songIds = List.generate(15, (i) => i + 1),
        ]),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountedSongs extends ListBase<SongModel> {
  final List<SongModel> songs;
  int reads = 0;
  _CountedSongs(this.songs);
  @override
  int get length => songs.length;
  @override
  set length(int value) => throw UnsupportedError('read only');
  @override
  SongModel operator [](int index) {
    reads++;
    return songs[index];
  }

  @override
  void operator []=(int index, SongModel value) =>
      throw UnsupportedError('read only');
}

final _songs = [
  SongModel(
    id: 1,
    title: 'Morning Light',
    artist: 'Harbor',
    album: 'Quiet',
    data: r'C:\Music\morning.mp3',
    duration: 240000,
    dateAdded: 2,
  ),
  SongModel(
    id: 2,
    title: 'Night Rain',
    artist: 'Forest',
    album: 'Quiet',
    data: r'C:\Music\night.mp3',
    duration: 120000,
    dateAdded: 1,
  ),
];

Future<GoRouter> _mount(
  WidgetTester tester,
  Size size, {
  bool empty = false,
  Locale locale = const Locale('en'),
  _Player? player,
  List<SongModel>? librarySongs,
  List<double> waveform = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: '/library',
    routes: [
      // Match the production router: one desktop shell survives page changes.
      ShellRoute(
        builder: (_, __, child) => ToneHarborDesktop(child: child),
        routes: [
          for (final path in ['/library', '/', '/now-playing'])
            GoRoute(
              path: path,
              pageBuilder: (_, __) => const NoTransitionPage(child: SizedBox()),
            ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HarborSettings()),
          ),
          GoRoute(
            path: '/playlists',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HarborPlaylists()),
          ),
          GoRoute(
            path: '/converter',
            pageBuilder: (_, state) => NoTransitionPage(
              child: HarborStudio(
                mode: StudioMode.converter,
                initialFiles: state.extra as List<String>?,
              ),
            ),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('harbor-preview'),
      child: ProviderScope(
        overrides: [
          waveformProvider.overrideWith((_, __) async => waveform),
          waveformWindowProvider.overrideWith((_, __) async => waveform),
          songLibraryProvider.overrideWith(
            (_) async => empty ? [] : librarySongs ?? _songs,
          ),
          audioPlayerProvider.overrideWith((_) => player ?? _Player()),
          playlistRepositoryProvider.overrideWith((_) => _Playlists()),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildHarborTheme(),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets(
    'desktop track overflow plays the exact row through the new menu',
    (tester) async {
      final player = _Player();
      final router = await _mount(
        tester,
        const Size(1500, 900),
        player: player,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('library-row-2')),
          matching: find.byTooltip('Song options'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('track-menu-delete'))).bottom -
            tester.getRect(find.byKey(const ValueKey('track-menu-play'))).top,
        lessThan(420),
      );
      await tester.tap(find.byKey(const ValueKey('track-menu-play')));
      await tester.pumpAndSettle();
      expect(player.state.currentSong?.id, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets(
    'selection reuses library ordering and search still invalidates it',
    (tester) async {
      final songs = _CountedSongs(
        List.generate(
          1000,
          (i) => SongModel(
            id: i + 1,
            title: 'Track $i',
            artist: 'Harbor',
            album: '',
            data: 'C:/Music/$i.mp3',
            duration: 60000,
            dateAdded: 1000 - i,
          ),
        ),
      );
      final router = await _mount(
        tester,
        const Size(1500, 900),
        librarySongs: songs,
      );
      songs.reads = 0;
      await tester.tap(find.text('Select tracks'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('select-track-1')));
      await tester.pumpAndSettle();
      expect(
        songs.reads,
        0,
        reason: 'Selection must not rescan or sort the source catalogue',
      );
      await tester.enterText(find.byType(TextField).first, 'Track 999');
      await tester.pumpAndSettle();
      expect(songs.reads, greaterThan(0));
      expect(find.byKey(const ValueKey('library-row-1000')), findsOneWidget);
      expect(find.byKey(const ValueKey('library-row-1')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('mini player ticks rebuild only the seek clock', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(480, 105);
    tester.view.devicePixelRatio = 1;
    final player = _Player();
    player.selectForTest(_songs, 0);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioPlayerProvider.overrideWith((_) => player)],
        child: const MaterialApp(home: HarborMiniPlayer()),
      ),
    );
    await tester.pumpAndSettle();
    final previous = debugOnRebuildDirtyWidget;
    final builds = <String, int>{};
    debugOnRebuildDirtyWidget = (element, built) {
      final type = element.widget.runtimeType.toString();
      builds[type] = (builds[type] ?? 0) + 1;
      previous?.call(element, built);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previous);
    for (var i = 1; i <= 60; i++) {
      await player.seek(Duration(milliseconds: i * 200));
      await tester.pump(const Duration(milliseconds: 16));
    }
    debugOnRebuildDirtyWidget = previous;
    expect(builds['HarborMiniPlayer'] ?? 0, 0);
    expect(builds['PlatformArtworkWidget'] ?? 0, 0);
    expect(builds['HarborArtwork'] ?? 0, 0);
    expect(builds['HarborPlaybackClock'], 60);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 12000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'repeat badges distinguish every mode and follow the player between views',
    (tester) async {
      final player = _Player();
      final router = await _mount(
        tester,
        const Size(1500, 900),
        player: player,
      );
      player.selectForTest(_songs, 0);
      await tester.pumpAndSettle();
      final control = find.byKey(const ValueKey('repeat-mode-control'));
      for (final (badge, tooltip) in [
        ('0', 'Repeat off'),
        ('1', 'Repeat once'),
        ('3', 'Repeat 3 times'),
        ('∞', 'Repeat forever'),
      ]) {
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('repeat-mode-badge')))
              .data,
          badge,
        );
        expect(find.byTooltip(tooltip), findsOneWidget);
        if (badge != '∞') {
          await tester.tap(control);
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.byTooltip('Full player'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Repeat forever'), findsOneWidget);
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(player.state.repeatMode, RepeatState.off);
      await tester.tap(find.byKey(const ValueKey('navigation-back')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('repeat-mode-badge')))
            .data,
        '0',
      );
      expect(player.state.currentSong?.id, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets(
    'position ticks update seek without rebuilding covers or the listening workspace',
    (tester) async {
      final player = _Player();
      final router = await _mount(
        tester,
        const Size(1500, 900),
        player: player,
        waveform: List.filled(240, .4),
      );
      player.selectForTest(_songs, 0);
      router.go('/now-playing');
      await tester.pumpAndSettle();
      final previous = debugOnRebuildDirtyWidget;
      final builds = <String, int>{};
      debugOnRebuildDirtyWidget = (element, built) {
        final type = element.widget.runtimeType.toString();
        builds[type] = (builds[type] ?? 0) + 1;
        previous?.call(element, built);
      };
      addTearDown(() => debugOnRebuildDirtyWidget = previous);
      final watch = Stopwatch()..start();
      for (var i = 1; i <= 60; i++) {
        await player.seek(Duration(milliseconds: i * 200));
        await tester.pump(const Duration(milliseconds: 16));
      }
      watch.stop();
      debugOnRebuildDirtyWidget = previous;
      expect(builds['HarborListeningRoom'] ?? 0, 0);
      expect(builds['HarborArtwork'] ?? 0, 0);
      expect(builds['PlatformArtworkWidget'] ?? 0, 0);
      expect(builds['HarborPlaybackClock'], greaterThanOrEqualTo(60));
      final seek = tester.widget<Slider>(
        find.byWidgetPredicate((w) => w is Slider && w.max > 1),
      );
      expect(seek.value, 12000);
      if (const bool.fromEnvironment('HARBOR_PREVIEW')) {
        await tester.runAsync(() async {
          await Directory('output').create(recursive: true);
          await File('output/playback-build-metrics.json').writeAsString(
            jsonEncode({
              'positionUpdates': 60,
              'elapsedTestMilliseconds': watch.elapsedMilliseconds,
              'clockBuilds': builds['HarborPlaybackClock'],
              'listeningRoomBuilds': builds['HarborListeningRoom'] ?? 0,
              'coverBuilds':
                  (builds['HarborArtwork'] ?? 0) +
                  (builds['PlatformArtworkWidget'] ?? 0),
              'seekPositionMs': seek.value,
              'note':
                  'Flutter widget build counter in test mode; not a hardware FPS benchmark.',
            }),
          );
        });
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'ultrawide workspaces fit large libraries and Windows display scaling',
    (tester) async {
      final largeLibrary = List.generate(
        10000,
        (i) => SongModel(
          id: i + 1,
          title: 'Audio $i',
          artist: 'Artist ${i % 20}',
          album: 'Album ${i % 40}',
          data: 'missing-$i.mp3',
          duration: 240000,
          dateAdded: i,
        ),
      );
      for (final (size, ratio, locale) in [
        (const Size(2560, 1080), 1.25, const Locale('en')),
        (const Size(3440, 1440), 1.0, const Locale('en')),
        (const Size(5120, 1440), 1.0, const Locale('ar')),
      ]) {
        final player = _Player();
        final router = await _mount(
          tester,
          size,
          player: player,
          locale: locale,
          librarySongs: largeLibrary,
        );
        tester.view.devicePixelRatio = ratio;
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('library-row-10000')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('library-row-10000'))).width,
          lessThanOrEqualTo(2200),
        );
        expect(
          find.byType(HarborTrackHighlight).evaluate().length,
          lessThan(100),
        );
        player.selectForTest(largeLibrary, 0);
        router.go('/now-playing');
        await tester.pumpAndSettle();
        expect(
          tester
              .getSize(find.byKey(const ValueKey('listening-workspace')))
              .width,
          lessThan(2200),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('full-player-queue'))).width,
          lessThanOrEqualTo(420),
        );
        expect(tester.takeException(), isNull);
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('desktop-settings'))).width,
          lessThanOrEqualTo(1600),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
  testWidgets(
    'Arabic desktop pages fit narrow and wide windows with a live queue',
    (tester) async {
      for (final size in [const Size(900, 650), const Size(1500, 900)]) {
        final player = _Player();
        final router = await _mount(
          tester,
          size,
          player: player,
          locale: const Locale('ar'),
        );
        player.selectForTest(_songs, 0);
        router.go('/now-playing');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final queue = tester.getTopLeft(
          find.byKey(const ValueKey('full-player-queue')),
        );
        final workspace = tester.getTopLeft(
          find.byKey(const ValueKey('listening-workspace')),
        );
        if (size.width == 900) {
          expect(queue.dy, greaterThan(workspace.dy));
        } else {
          expect(queue.dx, lessThan(workspace.dx));
        }
        router.go('/settings');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('settings-category-1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        router.go('/library');
        await tester.pumpAndSettle();
        await tester.tap(find.text('المجلدات'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('desktop-folder-browser')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets(
    'full player has one transport and plays the exact next queue row',
    (tester) async {
      final player = _Player();
      final router = await _mount(
        tester,
        const Size(1500, 900),
        player: player,
      );
      player.selectForTest(_songs, 0);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Full player'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('desktop-player-footer')), findsNothing);
      expect(
        find.byKey(const ValueKey('full-player-transport')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('full-player-queue')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('full-player-volume'))).width,
        lessThan(220),
      );
      await tester.tap(find.byKey(const ValueKey('full-queue-track-2')));
      await tester.pumpAndSettle();
      expect(player.state.currentSong?.id, 2);
      expect(player.state.queue.map((s) => s.id), [1, 2]);
      await tester.drag(
        find.byKey(const ValueKey('full-player-volume')),
        const Offset(-60, 0),
      );
      await tester.pumpAndSettle();
      expect(player.state.volume, lessThan(1));
      await tester.tap(find.byKey(const ValueKey('navigation-back')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('desktop-player-footer')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'folder browser separates equal names by full path and plays only that folder',
    (tester) async {
      final songs = [
        SongModel(
          id: 11,
          title: 'First folder one',
          artist: 'A',
          album: 'A',
          data: r'C:\Music\Sessions\one.mp3',
          duration: 10000,
          dateAdded: 3,
        ),
        SongModel(
          id: 12,
          title: 'Other folder',
          artist: 'A',
          album: 'A',
          data: r'D:\Archive\Sessions\two.mp3',
          duration: 240000,
          dateAdded: 2,
        ),
        SongModel(
          id: 13,
          title: 'First folder two',
          artist: 'A',
          album: 'A',
          data: r'C:\Music\Sessions\three.mp3',
          duration: 19000,
          dateAdded: 1,
        ),
      ];
      final player = _Player();
      final router = await _mount(
        tester,
        const Size(900, 650),
        player: player,
        librarySongs: songs,
      );
      await tester.tap(find.text('Folders'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('desktop-folder-browser')),
        findsOneWidget,
      );
      expect(find.text('Sessions'), findsNWidgets(2));
      expect(find.text('00:29'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('play-folder-D:/Archive/Sessions')),
      );
      await tester.pumpAndSettle();
      expect(player.state.queue.map((s) => s.id), [12]);
      await tester.tap(
        find.byKey(const ValueKey('folder-path-C:/Music/Sessions')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library-row-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('library-row-13')), findsOneWidget);
      expect(find.byKey(const ValueKey('library-row-12')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('settings edits a shortcut inline and saves the actual binding', (
    tester,
  ) async {
    const channel = MethodChannel('toneharbor/hotkeys');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => true);
    final router = await _mount(tester, const Size(900, 650));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('now-playing-panel')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-category-2')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final keyButton = find.byKey(const ValueKey('shortcut-binding-next'));
    await tester.ensureVisible(keyButton);
    await tester.tap(keyButton);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HarborSettings)),
    );
    expect(
      container.read(harborShortcutsProvider)[HarborAction.next]!.key,
      0x4b,
    );
    expect(
      (await SharedPreferences.getInstance()).getString('toneharbor_shortcuts'),
      contains('[3,75]'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'global back follows sidebar visits, pushed settings and local library groups',
    (tester) async {
      final router = await _mount(tester, const Size(1500, 900));
      final back = find.byKey(const ValueKey('navigation-back'));
      expect(tester.widget<IconButton>(back).onPressed, isNull);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Converter'));
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-dashboard')), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-dashboard')), findsOneWidget);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library-row-1')), findsOneWidget);
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library-row-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('track titles do not create a hover tooltip', (tester) async {
    final router = await _mount(tester, const Size(1500, 900));
    final title = find.text('Morning Light');
    expect(
      find.ancestor(of: title, matching: find.byType(Tooltip)),
      findsNothing,
    );
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(title));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Morning Light'), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'playing row highlight fades between choices without moving hit targets',
    (tester) async {
      final player = _Player();
      final router = await _mount(
        tester,
        const Size(1500, 900),
        player: player,
      );
      final rowPosition = tester.getTopLeft(
        find.byKey(const ValueKey('library-row-1')),
      );
      final nextPosition = tester.getTopLeft(find.byTooltip('Next'));
      final theme = ProviderScope.containerOf(
        tester.element(find.byType(ToneHarborDesktop)),
      ).read(harborThemeProvider);
      Color background(int id) =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.descendant(
                                of: find.byKey(ValueKey('library-row-$id')),
                                matching: find.byType(HarborTrackHighlight),
                              ),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      final idle = [background(1), background(2)];
      final activeColor = theme.accent.withAlpha(24);
      await tester.tap(find.byKey(const ValueKey('library-row-1')));
      await tester.pumpAndSettle();
      expect(background(1), activeColor);
      expect(background(2), idle[1]);

      await tester.tap(find.byKey(const ValueKey('library-row-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      expect(player.state.currentSong?.id, 2);
      // Both the outgoing and incoming highlight are mid-transition.
      expect(background(1), isNot(activeColor));
      expect(background(1), isNot(idle[0]));
      expect(background(2), isNot(idle[1]));
      expect(background(2), isNot(activeColor));

      for (final id in [1, 2, 1, 2]) {
        await tester.tap(find.byKey(ValueKey('library-row-$id')));
        await tester.pump(const Duration(milliseconds: 35));
        expect(player.state.currentSong?.id, id);
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('library-row-1'))),
          rowPosition,
        );
        expect(tester.getTopLeft(find.byTooltip('Next')), nextPosition);
        expect(
          find.descendant(
            of: find.byKey(ValueKey('library-row-$id')),
            matching: find.byType(HarborTrackHighlight),
          ),
          findsOneWidget,
        );
      }
      await tester.pumpAndSettle();
      expect(background(1), idle[0]);
      expect(background(2), activeColor);
      // Progress updates do not restart the playing-row animation.
      player.selectForTest(_songs, 1, preview: true);
      await tester.pump();
      expect(background(2), activeColor);
      expect(
        find.byKey(const ValueKey('panel-track-transition')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('footer-track-transition')),
        findsNothing,
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('library-row-1')));
      await tester.pump();
      expect(background(1), activeColor);
      expect(background(2), idle[1]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('collection cards open and play their actual local subsets', (
    tester,
  ) async {
    final player = _Player();
    final router = await _mount(tester, const Size(1500, 900), player: player);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('play-collection-Long listens')),
    );
    await tester.pumpAndSettle();
    expect(player.state.queue.map((s) => s.id), [1]);
    await tester.tap(find.byKey(const ValueKey('collection-Long listens')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-row-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-row-2')), findsNothing);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToneHarborDesktop)),
    );
    await container.read(favoritesProvider.notifier).setMany([2], true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('play-collection-Liked Songs')));
    await tester.pumpAndSettle();
    expect(player.state.queue.map((s) => s.id), [2]);
    expect(player.state.currentSong?.id, 2);
    await tester.tap(find.byKey(const ValueKey('collection-Liked Songs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-row-1')), findsNothing);
    expect(find.byKey(const ValueKey('library-row-2')), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collection-Playlists')));
    await tester.pumpAndSettle();
    expect(find.text('Your playlists'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets(
    'selection keeps row hit targets fixed and the panel has no duplicate transport',
    (tester) async {
      final router = await _mount(tester, const Size(1500, 900));
      final row = find.byKey(const ValueKey('library-row-1'));
      final position = tester.getTopLeft(row);
      await tester.tap(find.text('Select tracks'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(row), position);
      expect(find.byKey(const ValueKey('home-collections')), findsNothing);
      expect(find.byKey(const ValueKey('home-listening-header')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('now-playing-panel')),
          matching: find.byType(Slider),
        ),
        findsNothing,
      );
      expect(find.byType(Slider), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets(
    'mouse clicks play the exact library row, including repeat clicks',
    (tester) async {
      final player = _Player();
      final router = await _mount(
        tester,
        const Size(1500, 900),
        player: player,
      );
      for (final id in [1, 2, 1, 2, 2, 1]) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(ValueKey('library-row-$id'))),
          kind: ui.PointerDeviceKind.mouse,
        );
        await gesture.up();
        await tester.pumpAndSettle();
        expect(player.state.currentSong?.id, id);
      }
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets(
    'selection actions invert the selection and open batch conversion',
    (tester) async {
      final router = await _mount(tester, const Size(1500, 900));
      await tester.tap(find.text('Select tracks'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('select-track-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Selection actions'));
      await tester.pumpAndSettle();
      expect(find.text('Play next'), findsOneWidget);
      expect(find.text('Add to queue'), findsOneWidget);
      expect(find.text('Copy file paths'), findsOneWidget);
      await tester.tap(find.text('Invert selection'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('select-track-1')))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('select-track-2')))
            .value,
        isTrue,
      );
      await tester.tap(find.byTooltip('Convert selected'));
      await tester.pumpAndSettle();
      expect(find.text('Conversion'), findsOneWidget);
      expect(find.text('night.mp3'), findsOneWidget);
      expect(find.text('1 file'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('long press activates selection and Escape hides it', (
    tester,
  ) async {
    final router = await _mount(tester, const Size(1500, 900));
    expect(find.byKey(const ValueKey('select-track-1')), findsNothing);
    final press = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('library-row-1'))),
      kind: ui.PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await press.up();
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(
      tester
          .widget<Checkbox>(find.byKey(const ValueKey('select-track-1')))
          .value,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('select-track-1')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('press and drag selects a range without playing it', (
    tester,
  ) async {
    final player = _Player();
    final router = await _mount(tester, const Size(1500, 900), player: player);
    final start = tester.getCenter(find.byKey(const ValueKey('library-row-1')));
    final end = tester.getCenter(find.byKey(const ValueKey('library-row-2')));
    final gesture = await tester.startGesture(
      start,
      kind: ui.PointerDeviceKind.mouse,
    );
    await gesture.moveTo(end + const Offset(30, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete tracks'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from library'), findsOneWidget);
    expect(find.text('Delete permanently'), findsOneWidget);
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This deletes the original files from your device.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(player.state.currentSong, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('drag selection continues through edge scrolling', (
    tester,
  ) async {
    final songs = List.generate(
      30,
      (i) => SongModel(
        id: i + 1,
        title: 'Track $i',
        artist: '',
        album: '',
        data: '$i.mp3',
        duration: 10000,
        dateAdded: 30 - i,
      ),
    );
    final router = await _mount(
      tester,
      const Size(1500, 900),
      librarySongs: songs,
    );
    final list = find.byType(HarborTrackList);
    final bottom = tester.getBottomRight(list);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('library-row-1'))),
      kind: ui.PointerDeviceKind.mouse,
    );
    await gesture.moveTo(Offset(bottom.dx - 50, bottom.dy - 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await gesture.up();
    await tester.pumpAndSettle();
    final labels = tester
        .widgetList<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text && RegExp(r'^\d+ selected$').hasMatch(w.data ?? ''),
          ),
        )
        .map((w) => w.data!)
        .toList();
    expect(int.parse(labels.single.split(' ').first), greaterThan(10));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('sort menu changes the actual order and direction', (
    tester,
  ) async {
    final router = await _mount(tester, const Size(1500, 900));
    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duration'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Morning Light')).dy,
      lessThan(tester.getTopLeft(find.text('Night Rain')).dy),
    );
    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ascending'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Night Rain')).dy,
      lessThan(tester.getTopLeft(find.text('Morning Light')).dy),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('library checkboxes appear only after selection is enabled', (
    tester,
  ) async {
    final router = await _mount(tester, const Size(1500, 900));
    final row = find.byKey(const ValueKey('select-track-1'));
    expect(row, findsNothing);
    expect(find.byKey(const ValueKey('select-all-tracks')), findsNothing);
    await tester.tap(find.text('Select tracks'));
    await tester.pumpAndSettle();
    expect(row, findsOneWidget);
    final titleStyle = DefaultTextStyle.of(
      tester.element(find.text('Morning Light')),
    ).style;
    expect(titleStyle.fontSize, greaterThanOrEqualTo(15));
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('select-all-tracks')));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel selection'));
    await tester.pumpAndSettle();
    expect(row, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('track selection does not rebuild the desktop shell', (
    tester,
  ) async {
    final player = _Player();
    final router = await _mount(tester, const Size(1500, 900), player: player);
    final searchBefore = tester.widget<TextField>(find.byType(TextField));
    player.selectForTest(_songs, 1);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)),
      same(searchBefore),
    );
    expect(find.byIcon(Icons.graphic_eq), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('recently played displays only the latest ten existing entries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    final songs = List.generate(
      15,
      (i) => SongModel(
        id: i + 1,
        title: 'Track ${i + 1}',
        artist: 'Artist',
        album: 'Album',
        data: 'path$i',
        duration: 1000,
        dateAdded: i,
      ),
    );
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (_, __) => const ToneHarborDesktop(child: SizedBox()),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          songLibraryProvider.overrideWith((_) async => songs),
          audioPlayerProvider.overrideWith((_) => _Player()),
          playlistRepositoryProvider.overrideWith((_) => _RecentPlaylists()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recently Played'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('10 tracks'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('control-click selects multiple tracks', (tester) async {
    final router = await _mount(tester, const Size(1500, 900));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text('Morning Light'));
    await tester.tap(find.text('Night Rain'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('hidden player has a visible restore button', (tester) async {
    final router = await _mount(tester, const Size(1500, 900));
    expect(find.byTooltip('View'), findsNothing);
    expect(find.text('Full player'), findsNothing);
    expect(find.byKey(const ValueKey('app-brand-mark')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('now-playing-panel'))).width,
      greaterThan(350),
    );
    await tester.tap(find.byTooltip('Hide player panel').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show player panel'), findsOneWidget);
    await tester.tap(find.byTooltip('Show player panel'));
    await tester.pumpAndSettle();
    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('desktop playlist opens its track list', (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(
      initialLocation: '/playlists',
      routes: [
        GoRoute(
          path: '/playlists',
          builder: (_, __) => const Scaffold(body: HarborPlaylists()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => Scaffold(
                body: HarborPlaylists(
                  playlistId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistRepositoryProvider.overrideWith((_) => _PlaylistsWithData()),
          songLibraryProvider.overrideWith((_) async => _songs),
          playlistSongsProvider(42).overrideWith((_) async => _songs),
          audioPlayerProvider.overrideWith((_) => _Player()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My collection'), findsOneWidget);
    await tester.tap(find.text('My collection'));
    await tester.pumpAndSettle();
    expect(find.text('Morning Light'), findsOneWidget);
    expect(find.text('Play all'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('selects multiple tracks and opens a desktop context menu', (
    tester,
  ) async {
    final router = await _mount(tester, const Size(1500, 900));
    await tester.tap(find.text('Select tracks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning Light'));
    await tester.tap(find.text('Night Rain'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Play selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel selection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Song options').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Permanently'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('theme selector offers five palettes', (tester) async {
    final router = await _mount(tester, const Size(1500, 900));
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Refresh library'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Ocean'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('settings-theme-violet')));
    await tester.pumpAndSettle();
    final previousTint = tester
        .widget<ColorFiltered>(find.byKey(const ValueKey('app-brand-tint')))
        .colorFilter;
    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HarborSettings)),
    );
    expect(container.read(harborThemeProvider), HarborTheme.ocean);
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('app-brand-mark')),
    );
    expect(
      ((logo.image as ResizeImage).imageProvider as AssetImage).assetName,
      endsWith('brand-glossy-v9.png'),
    );
    expect(
      tester
          .widget<ColorFiltered>(find.byKey(const ValueKey('app-brand-tint')))
          .colorFilter,
      isNot(previousTint),
    );
    await tester.tap(find.text('Pictures'));
    await tester.pumpAndSettle();
    expect(find.text('Default track cover'), findsOneWidget);
    expect(find.text('Default playlist cover'), findsOneWidget);
    expect(find.byKey(const ValueKey('change-home:header')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('playback-cover-waveform')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keyboard shortcuts'));
    await tester.pumpAndSettle();
    expect(find.text('Edit shortcuts'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final artwork = tester.widgetList<Image>(
      find.byKey(const ValueKey('harbor-audio-artwork')),
    );
    expect(artwork, isNotEmpty);
    expect(
      artwork.every(
        (image) =>
            image.image is ResizeImage &&
            ((image.image as ResizeImage).imageProvider as AssetImage).assetName
                .contains('ocean-track'),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('title drag area requests a native window move', (tester) async {
    const channel = MethodChannel('window_manager');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'isFullScreen' ? false : null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final router = await _mount(tester, const Size(1500, 900));
    await tester.drag(
      find.byKey(const ValueKey('window-drag-area')),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();
    expect(calls, contains('startDragging'));
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('full player opens at the minimum window size', (tester) async {
    final router = await _mount(tester, const Size(900, 650));
    await tester.tap(find.byTooltip('Open player'));
    await tester.pumpAndSettle();
    expect(find.text('Mini player'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('converter and editor present desktop controls', (tester) async {
    tester.view.physicalSize = const Size(900, 650);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HarborStudio(mode: StudioMode.converter)),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Conversion'), findsOneWidget);
    expect(find.text('Choose files'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HarborStudio(mode: StudioMode.editor)),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Audio editing'), findsOneWidget);
    expect(find.text('Start (seconds)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('editor-tab-Space')));
    await tester.tap(find.byKey(const ValueKey('editor-tab-Space')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('8D audio'));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Rotation speed'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('mini player is usable with no selected track', (tester) async {
    tester.view.physicalSize = const Size(480, 105);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioPlayerProvider.overrideWith((_) => _Player())],
        child: const MaterialApp(
          home: HarborMiniPlayer(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing playing yet'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('mini-window-opacity')),
    );
    expect(opacity.opacity, closeTo(160 / 255, .001));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('mini-window-opacity')),
        matching: find.byType(Slider),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('home is a distinct dashboard and links to the library', (
    tester,
  ) async {
    final router = await _mount(tester, const Size(1500, 900));
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Open library'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-listening-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-collections')), findsOneWidget);
    expect(find.text('Select tracks'), findsNothing);
    expect(find.text('Albums'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-resume-play')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToneHarborDesktop)),
    );
    expect(container.read(audioPlayerProvider).currentSong?.id, 1);
    await tester.tap(find.text('Open library'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-row-1')), findsOneWidget);
    expect(find.text('Select tracks'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-listening-header')), findsNothing);
    expect(find.byKey(const ValueKey('home-collections')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('desktop labels respond to Arabic locale', (tester) async {
    final router = await _mount(
      tester,
      const Size(1500, 900),
      locale: const Locale('ar'),
    );
    expect(find.text('المكتبة'), findsWidgets);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-listening-header')), findsOneWidget);
    expect(find.text('أهلاً بعودتك'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  if (const bool.fromEnvironment('HARBOR_PREVIEW')) {
    testWidgets('export desktop preview using the production widgets', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.runAsync(() async {
        final font = FontLoader('Segoe UI')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                await File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytes(),
              ),
            ),
          );
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
      const titles = [
        'أم الغرباء',
        'Qadartuna Shuhada (Epic Latmiya)',
        'حديث الروح',
        'بين السكون والصدى — جلسة استماع هادئة',
        'Morning light — instrumental session',
        'دعاء الفرج',
        'على ضفاف الذاكرة',
        'Evening reflections',
      ];
      final catalog = List.generate(
        16,
        (i) => SongModel(
          id: 101 + i,
          title: titles[i % titles.length],
          artist: i.isEven ? 'Local collection' : 'ToneHarbor Sessions',
          album: 'Quiet',
          data:
              'C:/Music/${['Sessions', 'Poetry', 'Studio'][i % 3]}/preview-${101 + i}.mp3',
          duration: 245000 + i * 17000,
          dateAdded: 100 - i,
        ),
      );
      final previewPlayer = _Player();
      final router = await _mount(
        tester,
        const Size(1500, 900),
        player: previewPlayer,
        librarySongs: catalog,
        waveform: List.generate(
          240,
          (i) => [.2, .35, .5, .68, .82, .56, .38][(i ~/ 5) % 7],
        ),
      );
      previewPlayer.selectForTest(catalog, 3, preview: true);
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/harbor/window-cover-v2.webp'),
          tester.element(find.byType(ToneHarborDesktop)),
        );
      });
      await tester.pumpAndSettle();
      Future<void> capture(String filename) async {
        // Await each rendered image size, not only the unresized source cache.
        await tester.runAsync(() async {
          await Future.wait(
            tester
                .elementList(find.byType(Image))
                .map(
                  (element) =>
                      precacheImage((element.widget as Image).image, element),
                ),
          );
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('harbor-preview')),
          );
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('output').create(recursive: true);
          await File(
            'output/$filename',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('ToneHarbor-preview.png');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('library-row-102')),
          matching: find.byTooltip('Song options'),
        ),
      );
      await tester.pumpAndSettle();
      final rootContext = tester.element(find.byType(ToneHarborDesktop));
      AppToast.success(rootContext, '3 tracks added to queue');
      await capture('ToneHarbor-desktop-library-v23.png');
      await tester.tapAt(const Offset(600, 100));
      AppToast.dismiss();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select tracks'));
      await tester.pumpAndSettle();
      for (final song in catalog.take(3)) {
        await tester.tap(find.byKey(ValueKey('select-track-${song.id}')));
      }
      await tester.pumpAndSettle();
      await capture('ToneHarbor-library-selected.png');
      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Folders'));
      await tester.pumpAndSettle();
      await capture('ToneHarbor-folders.png');
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await capture('ToneHarbor-home.png');
      expect(find.byType(Scrollbar), findsWidgets);
      await capture('ToneHarbor-desktop-home-v23.png');
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await capture('ToneHarbor-settings.png');
      await tester.tap(find.text('Pictures'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(ToneHarborDesktop));
        await precacheImage(
          const ResizeImage(
            AssetImage('assets/images/harbor/defaults/forest-playlist.png'),
            width: 64,
          ),
          context,
        );
        for (final name in [
          'green-studio-v2',
          'mountain-listens',
          'city-favorites',
          'leaves-playlists',
        ]) {
          if (context.mounted) {
            await precacheImage(
              AssetImage('assets/images/harbor/$name.webp'),
              context,
            );
          }
        }
      });
      await tester.pumpAndSettle();
      await capture('ToneHarbor-pictures.png');
      await tester.tap(find.byKey(const ValueKey('settings-category-2')));
      await tester.pumpAndSettle();
      await capture('ToneHarbor-shortcuts.png');
      await tester.tap(find.byKey(const ValueKey('settings-category-3')));
      await tester.pumpAndSettle();
      await capture('ToneHarbor-language.png');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Full player'));
      await tester.pumpAndSettle();
      await capture('ToneHarbor-full-player.png');
      tester.view.physicalSize = const Size(3440, 1440);
      await tester.pumpAndSettle();
      await capture('ToneHarbor-ultrawide.png');
      tester.view.physicalSize = const Size(1500, 900);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('harbor-preview'),
          child: MaterialApp(
            theme: buildHarborTheme(),
            home: const Scaffold(
              body: HarborStudio(
                mode: StudioMode.converter,
                initialFile: r'C:\Media\Example.mp4',
              ),
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture('ToneHarbor-converter.png');
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  for (final size in [
    const Size(900, 650),
    const Size(1250, 650),
    const Size(1600, 650),
    const Size(1500, 900),
  ]) {
    testWidgets('library fits ${size.width} x ${size.height}', (tester) async {
      final router = await _mount(tester, size);
      expect(find.text('Morning Light'), findsOneWidget);
      expect(find.text('Downloaded'), findsNothing);
      expect(
        tester.getSize(find.byType(TextField)).width,
        lessThanOrEqualTo(300),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-listening-header')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  testWidgets('search matches artist and displays an empty result honestly', (
    tester,
  ) async {
    final router = await _mount(tester, const Size(1500, 900));
    await tester.enterText(find.byType(TextField), 'forest');
    await tester.pumpAndSettle();
    expect(find.text('Night Rain'), findsOneWidget);
    expect(find.text('Morning Light'), findsNothing);
    await tester.enterText(find.byType(TextField), 'missing-song');
    await tester.pumpAndSettle();
    expect(find.text('No matching tracks'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('album groups open real tracks', (tester) async {
    final router = await _mount(tester, const Size(1500, 900));
    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();
    expect(find.text('Quiet'), findsOneWidget);
    await tester.tap(find.text('Quiet'));
    await tester.pumpAndSettle();
    expect(find.text('Morning Light'), findsOneWidget);
    expect(find.text('Night Rain'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
