import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/desktop/toneharbor_desktop.dart';
import '../features/library/library_screen.dart';
import '../features/player/full_player_screen.dart';
import '../features/playlists/playlists_screen.dart';
import '../features/playlists/playlist_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/desktop/harbor_settings.dart';
import '../features/onboarding/language_setup_screen.dart';
import '../features/playlists/favorites_screen.dart';
import '../features/player/mini_player_card.dart';
import '../features/player/overlay_mini_player.dart';
import '../features/desktop/harbor_mini_player.dart';
import '../features/desktop/harbor_studio.dart';
import '../features/desktop/harbor_playlists.dart';
import '../features/converter/video_converter_screen.dart';
import '../features/editor/audio_editor_screen.dart';
import '../features/editor/editing_hub_screen.dart';
import '../features/metadata_editor/metadata_editor_screen.dart';
import '../core/utils/platform_utils.dart';
import '../core/utils/app_icons.dart';
import '../l10n/app_localizations.dart';
import '../data/models/song_model.dart';
import 'theme/theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route paths
// ─────────────────────────────────────────────────────────────────────────────
abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/';
  static const library = '/library';
  static const player = '/player';
  static const desktopPlayer = '/now-playing';
  static const playlists = '/playlists';
  static const settings = '/settings';
  static const languageSetup = '/language-setup';
  static const favorites = '/favorites';
  static const overlay = '/overlay';
  static const converter = '/converter';
  static const editor = '/editor';
  static const metadataEditor = '/metadata-editor';
  static const editing = '/editing';
}

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: isDesktop ? AppRoutes.library : AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (ctx, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (ctx, state) => _shellPage(state, const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (ctx, state) =>
                _shellPage(state, const LibraryScreen()),
          ),
          GoRoute(
            path: AppRoutes.playlists,
            pageBuilder: (ctx, state) => _shellPage(state,
                isDesktop ? const HarborPlaylists() : const PlaylistsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (ctx, state) {
                  // A malformed deep link used to throw here.
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return _shellPage(
                        state,
                        _RouterMessageScreen(
                          icon: AppIcons.queueMusic,
                          title: AppLocalizations.of(ctx)?.pageNotFound ??
                              'Page not found',
                          message: state.uri.toString(),
                        ));
                  }
                  return _shellPage(
                      state,
                      isDesktop
                          ? HarborPlaylists(playlistId: id)
                          : PlaylistDetailScreen(playlistId: id));
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.converter,
            pageBuilder: (ctx, state) => _shellPage(
                state,
                isDesktop
                    ? HarborStudio(
                        mode: StudioMode.converter,
                        initialFiles: state.extra is List<String>
                            ? state.extra as List<String>
                            : null)
                    : const VideoConverterScreen()),
          ),
          GoRoute(
            path: AppRoutes.editing,
            pageBuilder: (ctx, state) => _shellPage(
                state,
                isDesktop
                    ? const HarborStudio(mode: StudioMode.editor)
                    : const EditingHubScreen()),
          ),
          GoRoute(
              path: AppRoutes.desktopPlayer,
              pageBuilder: (_, state) =>
                  _shellPage(state, const SizedBox.shrink())),
        ],
      ),
      GoRoute(
        path: AppRoutes.player,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          child: const FullPlayerScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (ctx, _) => _desktopPage(
            isDesktop ? const HarborSettings() : const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.languageSetup,
        builder: (ctx, _) => const LanguageSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (ctx, _) => _desktopPage(const FavoritesScreen()),
      ),
      GoRoute(
        path: AppRoutes.overlay,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          child:
              isDesktop ? const HarborMiniPlayer() : const OverlayMiniPlayer(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editor,
        builder: (ctx, state) {
          // `extra` is null when the route is opened without arguments (deep
          // link, state restore, hot restart) - previously a hard crash.
          final song = state.extra;
          if (song is! SongModel) return const _MissingSongScreen();
          return _desktopPage(isDesktop
              ? HarborStudio(mode: StudioMode.editor, initialFile: song.data)
              : AudioEditorScreen(song: song));
        },
      ),
      GoRoute(
        path: AppRoutes.metadataEditor,
        builder: (ctx, state) {
          final song = state.extra;
          if (song is! SongModel) return const _MissingSongScreen();
          return _desktopPage(MetadataEditorScreen(song: song));
        },
      ),
    ],
    errorBuilder: (context, state) => _RouterMessageScreen(
      icon: Icons.error_outline_rounded,
      title: AppLocalizations.of(context)?.pageNotFound ?? 'Page not found',
      message: state.uri.toString(),
    ),
  );
});

Page<void> _shellPage(GoRouterState state, Widget child) => isDesktop
    ? NoTransitionPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

Widget _desktopPage(Widget child) =>
    isDesktop ? ToneHarborDesktop(child: child) : child;

/// Fallback screen for unknown routes and broken deep links.
class _RouterMessageScreen extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? message;

  const _RouterMessageScreen({
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeDataProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.onSurface.withAlpha(140),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: Text(l?.home ?? 'Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when a screen needs a song that the route did not provide.
class _MissingSongScreen extends StatelessWidget {
  const _MissingSongScreen();

  @override
  Widget build(BuildContext context) {
    return _RouterMessageScreen(
      icon: Icons.music_off_rounded,
      title:
          AppLocalizations.of(context)?.songUnavailable ?? 'Song unavailable',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Scaffold – Responsive: NavigationRail on desktop, BottomNav on mobile
// ─────────────────────────────────────────────────────────────────────────────
class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int selectedIndex = 0;
    if (location.startsWith('/library')) selectedIndex = 1;
    if (location.startsWith('/playlists')) selectedIndex = 2;
    if (location.startsWith('/editing')) selectedIndex = 3;
    if (location.startsWith('/converter')) selectedIndex = 4;

    if (isDesktop) {
      return ToneHarborDesktop(child: widget.child);
    }

    // Mobile layout
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: MiniPlayerCard(),
            ),
            _BottomNav(selectedIndex: selectedIndex),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int selectedIndex;
  const _BottomNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.home);
            break;
          case 1:
            context.go(AppRoutes.library);
            break;
          case 2:
            context.go(AppRoutes.playlists);
            break;
          case 3:
            context.go(AppRoutes.editing);
            break;
          case 4:
            context.go(AppRoutes.converter);
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded), label: l.home),
        BottomNavigationBarItem(
            icon: const Icon(Icons.library_music_rounded), label: l.library),
        BottomNavigationBarItem(
            icon: const Icon(AppIcons.queueMusic), label: l.playlists),
        BottomNavigationBarItem(
            icon: const Icon(Icons.auto_fix_high_rounded), label: l.editing),
        BottomNavigationBarItem(
            icon: const Icon(Icons.video_collection_rounded),
            label: l.convertVideo),
      ],
    );
  }
}
