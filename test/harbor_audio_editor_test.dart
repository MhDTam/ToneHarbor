import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/data/models/playlist_model.dart';
import 'package:toneharbor/data/repositories/playlist_repository.dart';
import 'package:toneharbor/data/repositories/song_repository.dart';
import 'package:toneharbor/services/audio/audio_player_service.dart';
import 'package:toneharbor/services/audio/artwork_provider.dart';
import 'package:toneharbor/features/desktop/harbor_audio_editor.dart';
import 'package:toneharbor/features/desktop/harbor_audio_effects.dart';
import 'package:toneharbor/features/desktop/harbor_editor_preview.dart';
import 'package:toneharbor/features/desktop/harbor_media_engine.dart';
import 'package:toneharbor/features/desktop/harbor_waveform.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/l10n/app_localizations.dart';

class _Engine extends HarborMediaEngine {
  Completer<void>? pending;
  final calls = <({
    String output,
    double start,
    double? end,
    AudioEditEffects effects
  })>[];
  @override
  Future<double?> duration(String input) async => 60;
  @override
  Future<void> export(
      {required String input,
      required String output,
      double start = 0,
      double? end,
      double volume = 1,
      double fadeIn = 0,
      double fadeOut = 0,
      bool spatial = false,
      double rotation = .125,
      double depth = 1,
      double reverb = .3,
      AudioEditEffects effects = const AudioEditEffects(),
      void Function(double)? onProgress}) async {
    calls.add((output: output, start: start, end: end, effects: effects));
    onProgress?.call(.5);
    if (pending != null) await pending!.future;
  }

  @override
  void cancel() {
    super.cancel();
    final gate = pending;
    pending = null;
    if (gate != null && !gate.isCompleted) {
      gate.completeError(const MediaExportCancelled());
    }
  }
}

class _Preview extends HarborEditorPreview {
  String? path;
  @override
  Future<void> play(String value) async {
    path = value;
    playing.value = true;
  }
}

class _Player extends StateNotifier<PlayerState>
    implements AudioPlayerNotifier {
  _Player()
      : super(PlayerState(queue: [
          SongModel(
              id: 999,
              title: 'Main queue',
              artist: '',
              album: '',
              data: 'queue.mp3',
              duration: 60000,
              dateAdded: 0)
        ]));
  @override
  void setSleepBoundary({bool track = false, bool queue = false}) {}
  @override
  Future<void> pause() async {
    state = state.copyWith(isPlaying: false);
  }

  @override
  Future<void> play() async {
    state = state.copyWith(isPlaying: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Lists extends StateNotifier<AsyncValue<List<PlaylistModel>>>
    implements PlaylistRepositoryNotifier {
  _Lists() : super(const AsyncData([]));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Picker extends FilePicker {
  @override
  Future<String?> saveFile(
          {String? dialogTitle,
          String? fileName,
          String? initialDirectory,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          Uint8List? bytes,
          bool lockParentWindow = false}) async =>
      'C:/Exports/edited.mp3';
}

Future<GoRouter> _mount(
    WidgetTester tester, _Engine engine, _Preview preview, _Player player,
    {Size size = const Size(1600, 1000),
    Locale locale = const Locale('en')}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final router = GoRouter(initialLocation: '/editing', routes: [
    ShellRoute(
        builder: (_, __, child) => ToneHarborDesktop(child: child),
        routes: [
          GoRoute(
              path: '/editing',
              pageBuilder: (_, __) => NoTransitionPage(
                  child: HarborAudioEditor(
                      initialFile: r'C:\Music\جلسة هادئة.wav',
                      engine: engine,
                      preview: preview))),
        ])
  ]);
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('editor-capture'),
      child: ProviderScope(
          overrides: [
            waveformProvider.overrideWith((_, __) async =>
                List.generate(1536, (i) => .08 + (i % 93) / 130)),
            waveformWindowProvider.overrideWith((_, __) async => const []),
            artworkBytesProvider.overrideWith((_, __) async => null),
            songLibraryProvider.overrideWith((_) async => const []),
            playlistRepositoryProvider.overrideWith((_) => _Lists()),
            audioPlayerProvider.overrideWith((_) => player),
          ],
          child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: buildHarborTheme(),
              routerConfig: router,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales))));
  await tester.pumpAndSettle();
  return router;
}

Future<void> unmount(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  router.dispose();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  testWidgets(
      'editor selection, undo, effects and export are wired to the actual draft',
      (tester) async {
    final engine = _Engine(), preview = _Preview(), player = _Player();
    FilePicker.platform = _Picker();
    final router = await _mount(tester, engine, preview, player);
    expect(
        find.byKey(const ValueKey('editor-selection-range')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('editor-start')), '5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('editor-end')), '45');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Undo'));
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('editor-end')))
            .controller!
            .text,
        '60.000');
    await tester.tap(find.byTooltip('Redo'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('editor-end')))
            .controller!
            .text,
        '45.000');
    final speed = tester
        .widget<Slider>(find.byKey(const ValueKey('editor-control-Speed')));
    speed.onChanged!(2);
    await tester.pumpAndSettle();
    expect(find.text('Output duration: 0:20.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Export audio'));
    await tester.tap(find.text('Export audio'));
    await tester.pumpAndSettle();
    expect(engine.calls.single.start, 5);
    expect(engine.calls.single.end, 45);
    expect(engine.calls.single.effects.speed, 2);
    expect(engine.calls.single.effects.sampleRate, 48000);
    expect(engine.calls.single.output, 'C:/Exports/edited.mp3');
    expect(find.text('Play audio'), findsOneWidget);
    expect(player.state.currentSong?.id, 999);
    expect(tester.takeException(), isNull);
    await unmount(tester, router);
  });

  testWidgets('preview is bounded and leaves the main playback queue intact',
      (tester) async {
    final engine = _Engine(), preview = _Preview(), player = _Player();
    final router = await _mount(tester, engine, preview, player);
    await tester.tap(find.byKey(const ValueKey('editor-preview')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pumpAndSettle();
    expect(engine.calls.single.start, 0);
    expect(engine.calls.single.end, 30);
    expect(engine.calls.single.output, endsWith('.wav'));
    expect(preview.path, engine.calls.single.output);
    expect(player.state.currentSong?.id, 999);
    expect(find.text('Pause preview'), findsOneWidget);
    await player.play();
    await tester.pumpAndSettle();
    expect(preview.playing.value, isFalse);
    await tester.tap(find.byKey(const ValueKey('editor-preview')));
    await tester.pumpAndSettle();
    expect(player.state.isPlaying, isFalse);
    expect(engine.calls, hasLength(1),
        reason: 'Resume reuses the rendered preview');
    await unmount(tester, router);
  });

  testWidgets(
      'cancel preview releases the render job and keeps the editor usable',
      (tester) async {
    final engine = _Engine(), preview = _Preview(), player = _Player();
    final router = await _mount(tester, engine, preview, player);
    engine.pending = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('editor-preview')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel preview'));
    await tester.tap(find.text('Cancel preview'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(preview.path, isNull);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('editor-preview')))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
    await unmount(tester, router);
  });

  testWidgets('invalid trim bounds are reported before starting preview/export',
      (tester) async {
    final engine = _Engine(), preview = _Preview(), player = _Player();
    final router = await _mount(tester, engine, preview, player);
    await tester.enterText(find.byKey(const ValueKey('editor-end')), '1000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Selection must fit inside the source.'), findsOneWidget);
    expect(engine.calls, isEmpty);
    expect(tester.takeException(), isNull);
    await unmount(tester, router);
  });

  for (final size in [const Size(900, 650), const Size(3440, 1440)]) {
    testWidgets('Arabic editor fits ${size.width} x ${size.height}',
        (tester) async {
      final router = await _mount(tester, _Engine(), _Preview(), _Player(),
          size: size, locale: const Locale('ar'));
      expect(find.text('تعديل الصوت'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('editor-selection-range')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester, router);
    });
  }

  if (const bool.fromEnvironment('HARBOR_PREVIEW')) {
    testWidgets('export production editor preview with a sample waveform',
        (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('Segoe UI')
          ..addFont(File(r'C:\Windows\Fonts\segoeui.ttf')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
      final router = await _mount(tester, _Engine(), _Preview(), _Player());
      await tester.runAsync(() async {
        await Future.wait(find
            .byType(Image)
            .evaluate()
            .map((e) => precacheImage((e.widget as Image).image, e)));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('editor-capture')));
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('output').create(recursive: true);
        await File('output/ToneHarbor-audio-editor-v22.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await unmount(tester, router);
    });
  }
}
