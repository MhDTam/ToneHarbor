import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
import 'package:toneharbor/features/desktop/harbor_playlists.dart';
import 'package:toneharbor/features/desktop/harbor_waveform.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/l10n/app_localizations.dart';
import 'package:toneharbor/services/audio/artwork_provider.dart';
import 'package:toneharbor/services/audio/audio_player_service.dart';

final _songs = List.generate(
  16,
  (i) => SongModel(
    id: i + 1,
    title:
        '${['Night Sessions', 'First Light', 'Echoes', 'حديث الروح'][i % 4]} ${i + 1}',
    artist: i.isEven ? 'Harbor Sessions' : 'Local collection',
    album: 'Quiet evenings',
    data: 'preview-$i.mp3',
    duration: 180000 + i * 17000,
    dateAdded: 20 - i,
  ),
);
final _names = [
  'Evening sessions',
  'Deep listening',
  'على ضفاف الذاكرة',
  'Quiet moments',
  'Studio favorites',
  'Long listens',
];
final _lists = List.generate(
  6,
  (i) => PlaylistModel()
    ..id = 200 + i
    ..name = _names[i]
    ..createdAt = DateTime(2026, 10, 27 - i)
    ..songIds = _songs.skip(i).take(10).map((s) => s.id).toList(),
);

class _Lists extends StateNotifier<AsyncValue<List<PlaylistModel>>>
    implements PlaylistRepositoryNotifier {
  _Lists() : super(AsyncData(_lists));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Player extends StateNotifier<PlayerState>
    implements AudioPlayerNotifier {
  _Player() : super(const PlayerState());
  @override
  void setSleepBoundary({bool track = false, bool queue = false}) {}
  @override
  Future<void> playSong(
    SongModel song, {
    List<SongModel>? queue,
    int index = 0,
  }) async {
    state = state.copyWith(queue: queue ?? [song], currentIndex: index);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _mount(
  WidgetTester tester,
  _Player player,
  Size size, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: '/playlists',
    routes: [
      GoRoute(
        path: '/playlists',
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: const ToneHarborDesktop(child: HarborPlaylists()),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: ToneHarborDesktop(
                child: HarborPlaylists(
                  playlistId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('playlist-preview'),
      child: ProviderScope(
        overrides: [
          songLibraryProvider.overrideWith((_) async => _songs),
          playlistRepositoryProvider.overrideWith((_) => _Lists()),
          playlistSongsProvider.overrideWith((_, id) async {
            final ids = _lists.firstWhere((p) => p.id == id).songIds;
            return ids
                .map((id) => _songs.firstWhere((s) => s.id == id))
                .toList();
          }),
          waveformProvider.overrideWith((_, __) async => []),
          waveformWindowProvider.overrideWith((_, __) async => []),
          artworkBytesProvider.overrideWith((_, __) async => null),
          audioPlayerProvider.overrideWith((_) => player),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: buildHarborTheme(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'playlist gallery and filtered clicks fit a compact desktop in ${locale.languageCode}',
      (tester) async {
        final player = _Player();
        final router = await _mount(
          tester,
          player,
          const Size(900, 650),
          locale: locale,
        );
        await tester.tap(find.byKey(const ValueKey('playlist-card-200')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Filtering moves the second song into the first visual row.
        final field = find.descendant(
          of: find.byType(HarborPlaylists),
          matching: find.byType(TextField),
        );
        await tester.enterText(field, 'First Light 2');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('playlist-track-2')));
        await tester.pumpAndSettle();
        expect(player.state.currentSong?.id, 2);
        expect(player.state.currentIndex, 1);
        expect(player.state.queue.length, 10);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  }
  if (const bool.fromEnvironment('HARBOR_PREVIEW')) {
    testWidgets('export playlist gallery and detail from production widgets', (
      tester,
    ) async {
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
      final router = await _mount(tester, _Player(), const Size(1500, 900));
      Future<void> capture(String filename) async {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('playlist-preview')),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('output').create(recursive: true);
          await File(
            'output/$filename',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/harbor/window-cover-v2.webp'),
          tester.element(find.byType(HarborPlaylists)),
        );
      });
      await tester.pumpAndSettle();
      await capture('ToneHarbor-playlists.png');
      router.go('/playlists/200');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(
          ResizeImage.resizeIfNeeded(
            142,
            null,
            const AssetImage('assets/images/harbor/window-cover-v2.webp'),
          ),
          tester.element(find.byType(HarborPlaylists).last),
        );
      });
      await tester.pumpAndSettle();
      await capture('ToneHarbor-playlist-detail.png');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}
