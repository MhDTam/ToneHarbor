import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/audio/sleep_timer_service.dart';
import '../../core/utils/song_options_modal.dart';
import '../../core/utils/app_icons.dart';
import '../../data/repositories/song_repository.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDefaultPlayerPrompt();
      _initPermissionsAndAutoScan();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isMobile) {
      _checkPermissionAndAutoScanOnResume();
    }
  }

  Future<void> _checkPermissionAndAutoScanOnResume() async {
    final granted = await checkAudioPermission();
    if (granted && mounted) {
      final currentSongs = ref.read(songLibraryProvider).valueOrNull;
      if (currentSongs == null || currentSongs.isEmpty) {
        await scanMediaStoreForNewFiles();
        ref.invalidate(songLibraryProvider);
        ref.read(songLibraryProvider.future);
      }
    }
  }

  Future<void> _initPermissionsAndAutoScan() async {
    if (!isMobile) return;
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
    final hasAudio = await checkAudioPermission();
    if (!hasAudio) {
      final granted = await requestAudioPermission();
      if (granted && mounted) {
        await scanMediaStoreForNewFiles();
        ref.invalidate(songLibraryProvider);
        ref.read(songLibraryProvider.future);
      }
    } else {
      ref.read(songLibraryProvider.future);
    }
  }

  Future<void> _checkDefaultPlayerPrompt() async {
    if (!isDesktop) return;
    try {
      final l = AppLocalizations.of(context)!;
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('prompted_default_player') ?? false;
      if (!hasPrompted) {
        if (!mounted) return;
        await prefs.setBool('prompted_default_player', true);
        if (!mounted) return; // context is used after the await above
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.defaultPlayer),
            content: Text(l.defaultPlayerMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.noThanks),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (Platform.isWindows) {
                    Process.run('explorer.exe', ['ms-settings:defaultapps']);
                  }
                },
                child: Text(l.yesOpenSettings),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final currentSong =
        ref.watch(audioPlayerProvider.select((s) => s.currentSong));
    final timerState = ref.watch(sleepTimerProvider);
    final playlistsAsync = ref.watch(playlistRepositoryProvider);

    return Material(
      color: Colors.transparent,
      child: AppBackground(
        theme: theme,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        child: SafeArea(
          top: isMobile,
          child: CustomScrollView(
            slivers: [
              // App Bar (hide on desktop since it's in the sidebar)
              if (!isDesktop)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.primary.withAlpha(25),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: theme.primary.withAlpha(80)),
                          ),
                          child: Icon(Icons.music_note_rounded,
                              color: theme.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Musi',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w300,
                                  color: theme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: 'Convert',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded,
                              color: Colors.red),
                          onPressed: () => context.push(AppRoutes.favorites),
                        ),
                        IconButton(
                          icon: Icon(Icons.search_rounded,
                              color: theme.onSurface),
                          onPressed: () => context.go(AppRoutes.library),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_rounded,
                              color: theme.onSurface),
                          onPressed: () => context.push(AppRoutes.settings),
                        ),
                      ],
                    ),
                  ),
                ),

              // Desktop: simple greeting header
              if (isDesktop)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: Text(
                      AppLocalizations.of(context)!.welcomeBack,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 28 : 20, 24, isDesktop ? 28 : 20, 0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: theme.isDark
                            ? [
                                Color.lerp(theme.surface, theme.primary, 0.22)!
                                    .withAlpha(240),
                                Color.lerp(theme.surface, Colors.black, 0.25)!
                                    .withAlpha(245),
                              ]
                            : [
                                Color.lerp(theme.surface, theme.primary, 0.35)!,
                                Color.lerp(theme.surface, theme.primary, 0.18)!,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            theme.primary.withAlpha(theme.isDark ? 150 : 100),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.primary.withAlpha(theme.isDark ? 30 : 20),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push(AppRoutes.converter),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_collection_rounded,
                              color:
                                  theme.isDark ? Colors.white : theme.onSurface,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.convertVideoBtn,
                              style: TextStyle(
                                color: theme.isDark
                                    ? Colors.white
                                    : theme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Playlists
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 28 : 20, 28, isDesktop ? 28 : 20, 12),
                  child: Text(
                    AppLocalizations.of(context)!.quickPlaylists,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: playlistsAsync.when(
                    data: (playlists) => playlists.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 28 : 20),
                            child: _EmptyCard(
                              icon: AppIcons.queueMusic,
                              label: AppLocalizations.of(context)!.noPlaylists,
                              theme: theme,
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 28 : 20),
                            itemCount: playlists.length,
                            itemBuilder: (ctx, i) {
                              final pl = playlists[i];
                              final isSystem =
                                  pl.name == 'system_recently_played';
                              final displayName = isSystem
                                  ? AppLocalizations.of(ctx)!.recentlyPlayed
                                  : pl.name;
                              return GestureDetector(
                                onTap: () => ctx.push('/playlists/${pl.id}'),
                                child: Container(
                                  width: isDesktop ? 140 : 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: theme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: theme.primary.withAlpha(40)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(AppIcons.queueMusic,
                                          color: theme.primary, size: 32),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          displayName,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: theme.onSurface,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    loading: () => const Center(
                        child: CircularProgressIndicator.adaptive()),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ),

              // Now Playing Card
              if (currentSong != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 28 : 20, 24, isDesktop ? 28 : 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.nowPlaying,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _NowPlayingCard(theme: theme, timerState: timerState),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Now Playing Card
// ─────────────────────────────────────────────────────────────────────────────
class _NowPlayingCard extends ConsumerWidget {
  final dynamic theme;
  final SleepTimerState timerState;

  const _NowPlayingCard({required this.theme, required this.timerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(audioPlayerProvider.select((s) => s.currentSong));
    if (song == null) return const SizedBox();

    return GestureDetector(
      onTap: () => context.push(AppRoutes.player),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primary.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timerState.isActive)
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.primary.withAlpha(80), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bedtime_rounded,
                          color: theme.primary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.sleepTimerRemaining(
                            timerState.remainingSeconds ~/ 60),
                        style: TextStyle(
                            color: theme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.music_note_rounded,
                      color: theme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded,
                      color: theme.onSurface.withAlpha(180)),
                  onPressed: () => SongOptionsModal.show(
                      context: context, ref: ref, song: song, theme: theme),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Single Track Mode
            Consumer(
              builder: (ctx, ref, _) {
                final isSingle = ref
                    .watch(audioPlayerProvider.select((s) => s.isSingleTrack));
                final player = ref.read(audioPlayerProvider.notifier);
                return GestureDetector(
                  onTap: () => player.toggleSingleTrackMode(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat_one_rounded,
                          size: 16,
                          color: isSingle
                              ? theme.primary
                              : theme.onSurface.withAlpha(100),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.singleTrackMode,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSingle
                                ? theme.primary
                                : theme.onSurface.withAlpha(100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Progress bar
            Consumer(
              builder: (ctx, ref, _) {
                final position =
                    ref.watch(audioPlayerProvider.select((s) => s.position));
                final duration =
                    ref.watch(audioPlayerProvider.select((s) => s.duration));
                final isPlaying =
                    ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
                final player = ref.read(audioPlayerProvider.notifier);

                final totalSec = duration.inSeconds;
                final posSec = position.inSeconds;
                final progress = totalSec > 0 ? posSec / totalSec : 0.0;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) {
                          final newPos =
                              Duration(seconds: (v * totalSec).round());
                          player.seek(newPos);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(position.toHms(),
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(duration.toHms(),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.skip_previous_rounded, size: 32),
                          color: theme.onSurface,
                          onPressed: player.previous,
                        ),
                        GestureDetector(
                          onTap: () =>
                              isPlaying ? player.pause() : player.play(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: theme.primary.withAlpha(80),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: theme.onPrimary,
                              size: 30,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 32),
                          color: theme.onSurface,
                          onPressed: player.next,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic theme;

  const _EmptyCard(
      {required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primary.withAlpha(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.primary.withAlpha(100), size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: theme.onSurface.withAlpha(120))),
        ],
      ),
    );
  }
}

extension DurationFormat on Duration {
  String toHms() {
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
