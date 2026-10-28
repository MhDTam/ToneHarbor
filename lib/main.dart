import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'core/router.dart';
import 'features/desktop/toneharbor_desktop.dart';
import 'features/desktop/harbor_shortcuts.dart';
import 'features/desktop/harbor_window_frame.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/app_toast.dart';
import 'core/utils/platform_utils.dart';
import 'data/models/song_model.dart';
import 'services/audio/audio_handler.dart';
import 'services/audio/audio_player_service.dart';
import 'services/audio/audio_routing_service.dart';
import 'services/audio/desktop_media_open.dart';
import 'services/overlay_mode_provider.dart';
import 'l10n/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'services/selection_mode_provider.dart';
import 'services/cache_cleanup_service.dart';

// Conditionally import mobile-only packages
import 'services/audio/audio_service_init.dart' as audio_init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    PaintingBinding.instance.imageCache
      ..maximumSize = 192
      ..maximumSizeBytes = 48 * 1024 * 1024;
  }

  // Show errors brightly
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Build Error:\n${details.exceptionAsString()}\n\nStack:\n${details.stack}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  };

  // Mobile-only UI overlays
  if (isMobile) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Desktop window setup
  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1500, 900),
      minimumSize: Size(900, 650),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'ToneHarbor',
    );
    // Await so failures surface here rather than as an unhandled async error.
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await configureHarborWindowFrame();
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const _AppInitializer());
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();
  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isLoading = true;
  String _error = '';
  late ToneHarborAudioHandler _audioHandler;
  late String _savedTheme;
  late String _savedLocale;
  bool _isFirstRun = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // FlutterDisplayMode - Android only - enable 120Hz
      if (Platform.isAndroid) {
        try {
          final modes = await FlutterDisplayMode.supported;
          final highestMode = modes.reduce(
            (a, b) => (a.refreshRate > b.refreshRate) ? a : b,
          );
          await FlutterDisplayMode.setPreferredMode(highestMode);
        } catch (_) {}
      }

      // Read preferences first: the system media notification's accent colour
      // is taken from the saved theme at startup.
      final prefs = await SharedPreferences.getInstance();
      _savedTheme = prefs.getString('theme_id') ?? 'darkOcean';
      final localeStr = prefs.getString('app_locale');

      _savedLocale = localeStr ?? 'en';
      _isFirstRun = localeStr == null;

      // Initialize audio handler
      if (isMobile) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        final normalizedTheme = _savedTheme == 'ashura2'
            ? 'royalRed'
            : _savedTheme;
        final themeId = AppThemeId.values.firstWhere(
          (e) => e.name == normalizedTheme,
          orElse: () => AppThemeId.darkOcean,
        );
        _audioHandler = await audio_init.initAudioService(
          notificationColor: kAppThemes[themeId]!.primary,
        );
      } else {
        // On desktop, create handler directly without AudioService wrapper
        _audioHandler = ToneHarborAudioHandler();
      }

      // Automatically clean up any stale temporary files from previous sessions
      CacheCleanupService.clearAllCache().catchError((e) {
        debugPrint('Startup cache cleanup error: $e');
      });

      setState(() => _isLoading = false);
    } catch (e, st) {
      setState(() {
        _error = 'Init Error: $e\n\n$st';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF121212),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(_audioHandler),
        localeProvider.overrideWith(
          (ref) => LocaleNotifier(initialLocale: Locale(_savedLocale)),
        ),
      ],
      child: ToneHarborApp(
        initialTheme: AppThemeId.values.firstWhere(
          (e) =>
              e.name == (_savedTheme == 'ashura2' ? 'royalRed' : _savedTheme),
          orElse: () => AppThemeId.darkOcean,
        ),
        initialLocale: _savedLocale,
        isFirstRun: _isFirstRun,
      ),
    );
  }
}

class ToneHarborApp extends ConsumerStatefulWidget {
  final AppThemeId initialTheme;
  final String initialLocale;
  final bool isFirstRun;

  const ToneHarborApp({
    super.key,
    required this.initialTheme,
    required this.initialLocale,
    required this.isFirstRun,
  });

  @override
  ConsumerState<ToneHarborApp> createState() => _ToneHarborAppState();
}

class _ToneHarborAppState extends ConsumerState<ToneHarborApp> {
  static const _mediaOpenChannel = MethodChannel(
    'com.musiconvert.mp3noads/media_open',
  );

  bool _initialized = false;
  int _openRevision = 0;
  _AppBackButtonDispatcher? _backDispatcher;

  @override
  void initState() {
    super.initState();
    if (isMobile) {
      _backDispatcher = _AppBackButtonDispatcher(ref);
    }
    if (isMobile || Platform.isWindows) {
      _mediaOpenChannel.setMethodCallHandler(_handleMediaOpen);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized) return;
      _initialized = true;
      final audioHandler = ref.read(audioHandlerProvider);
      ref
          .read(themeProvider.notifier)
          .setTheme(widget.initialTheme, audioHandler);
      ref.read(localeProvider.notifier).setLocale(Locale(widget.initialLocale));

      if (isMobile) {
        ref.read(audioRoutingProvider); // Trigger routing (mobile only)
      }
      if (widget.isFirstRun && isMobile) {
        ref.read(routerProvider).go(AppRoutes.languageSetup);
      }
      _openInitialMedia();
    });
  }

  @override
  void dispose() {
    if (isMobile || Platform.isWindows) {
      _mediaOpenChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  /// Called when the app is used as the "Open with" handler for an audio file.
  Future<void> _handleMediaOpen(MethodCall call) async {
    if (call.method != 'openMedia') return;
    await _playMediaPayload(call.arguments);
  }

  /// A cold start launched through "Open with" reports the file once Flutter is
  /// ready.
  Future<void> _openInitialMedia() async {
    if (!isMobile && !Platform.isWindows) return;
    try {
      final result = await _mediaOpenChannel.invokeMethod<dynamic>(
        'getInitialMedia',
      );
      await _playMediaPayload(result);
    } catch (_) {}
  }

  Future<void> _playMediaPayload(dynamic payload) async {
    if (Platform.isWindows) {
      final revision = ++_openRevision;
      final songs = await desktopOpenedSongs(payload);
      if (!mounted || revision != _openRevision || songs.isEmpty) return;
      final router = ref.read(routerProvider);
      if (ref.read(isOverlayModeProvider)) {
        final ctx = router.routerDelegate.navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          await OverlayModeManager.disableOverlay(ref, ctx);
        }
      }
      if (!mounted || revision != _openRevision) return;
      try {
        await ref
            .read(audioPlayerProvider.notifier)
            .playSong(songs.first, queue: songs);
        if (mounted && revision == _openRevision) {
          router.go(AppRoutes.desktopPlayer);
        }
      } catch (e) {
        final ctx = router.routerDelegate.navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          AppToast.error(ctx, 'Could not open audio: $e');
        }
      }
      return;
    }
    if (payload is! Map) return;
    final path = payload['path'];
    if (path is! String || path.isEmpty) return;
    final title = payload['title'];
    await _playOpenedFile(
      path,
      title is String && title.isNotEmpty ? title : null,
    );
  }

  Future<void> _playOpenedFile(String path, String? title) async {
    final base = path.split(RegExp(r'[\\/]')).last;
    final resolvedTitle = title ?? base.replaceAll(RegExp(r'\.[^.]+$'), '');
    final song = SongModel(
      id: stablePathId(path),
      title: resolvedTitle,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      data: path,
      duration: 0,
      dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await ref.read(audioPlayerProvider.notifier).playSong(song);
    ref.read(routerProvider).push(AppRoutes.player);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) ref.watch(harborShortcutsProvider);
    final themeId = ref.watch(themeProvider);
    final themeData = kAppThemes[themeId]!;
    final builtTheme = buildThemeData(themeData);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ToneHarbor',
      theme: isDesktop ? buildHarborTheme() : builtTheme,
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      backButtonDispatcher: _backDispatcher,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Central back button handler — mobile only
class _AppBackButtonDispatcher extends RootBackButtonDispatcher {
  final WidgetRef _ref;
  DateTime? _lastBackPressTime;

  _AppBackButtonDispatcher(this._ref);

  @override
  Future<bool> didPopRoute() async {
    // 1. If songs are selected, clear selection
    final selection = _ref.read(selectedSongIdsProvider);
    if (selection.isNotEmpty) {
      _ref.read(selectedSongIdsProvider.notifier).state = {};
      return true;
    }

    // 2. Let GoRouter handle the pop (one step back) if possible
    final router = _ref.read(routerProvider);
    if (router.canPop()) {
      return super.didPopRoute();
    }

    // 3. Fallback: If we cannot pop and we are not on the home screen, go home.
    final location = router.routerDelegate.currentConfiguration.uri.path;
    if (location != '/') {
      router.go('/');
      return true;
    }

    // 4. Home tab: double press to minimize (not exit)
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      final ctx = router.routerDelegate.navigatorKey.currentContext;
      if (ctx != null) {
        AppToast.info(
          ctx,
          AppLocalizations.of(ctx)?.pressBackAgainToExit ??
              'Press back again to exit',
        );
      }
      return true;
    }

    // 5. Minimize app (move to background, don't kill)
    const platform = MethodChannel('com.musiconvert.mp3noads/lock');
    try {
      await platform.invokeMethod('minimizeApp');
    } catch (_) {}
    return true;
  }
}
