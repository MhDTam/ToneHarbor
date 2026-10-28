import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/audio/audio_player_service.dart';
import '../../core/utils/artwork_widget.dart';
import '../../l10n/app_localizations.dart';

class MiniPlayerCard extends ConsumerWidget {
  const MiniPlayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(audioPlayerProvider.select((s) => s.currentSong));
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final isMiniPlayerVisible =
        ref.watch(audioPlayerProvider.select((s) => s.isMiniPlayerVisible));
    final player = ref.read(audioPlayerProvider.notifier);
    final theme = ref.watch(currentThemeDataProvider);

    // If no song is loaded or user dismissed the player, hide it
    if (song == null || !isMiniPlayerVisible) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey('miniplayer_${song.id}'),
      direction: DismissDirection.down, // Swipe down to close
      onDismissed: (direction) {
        player.dismissMiniPlayer();
        player.pause();
      },
      child: isDesktop
          ? _SidebarPlayer(
              theme: theme, song: song, isPlaying: isPlaying, player: player)
          : _MobileMiniPlayerOuter(
              theme: theme, song: song, isPlaying: isPlaying, player: player),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Mobile Mini Player
// ─────────────────────────────────────────────────────────────────────────────
class _MobileMiniPlayerOuter extends ConsumerWidget {
  final dynamic theme;
  final dynamic song;
  final bool isPlaying;
  final dynamic player;

  const _MobileMiniPlayerOuter(
      {required this.theme,
      required this.song,
      required this.isPlaying,
      required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration = ref.watch(audioPlayerProvider.select((s) => s.duration));

    final progress = duration.inSeconds > 0
        ? (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    final primary = theme.primary as Color;
    final surface = theme.surface as Color;
    final onSurface = theme.onSurface as Color;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.player),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            player.next(); // Swipe left for next
          } else if (details.primaryVelocity! > 0) {
            player.previous(); // Swipe right for previous
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: surface
                    .withAlpha(brightness == Brightness.dark ? 180 : 220),
                child: Stack(
                  children: [
                    // Thin progress line tracking along the absolute bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: "transparent" == "transparent"
                            ? Colors.transparent
                            : null, // Fix syntax trick to set to transparent
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          // Artwork
                          PlatformArtworkWidget(
                            id: song.id,
                            path: song.data,
                            size: 50,
                          ),
                          const SizedBox(width: 14),

                          // Track Info
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (song.artist == null ||
                                          song.artist!.trim().toLowerCase() ==
                                              '<unknown>')
                                      ? AppLocalizations.of(context)!
                                          .unknownArtist
                                      : song.artist!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: onSurface.withAlpha(150),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Controls
                          _PlayPauseAnimButton(
                            isPlaying: isPlaying,
                            onTap: () =>
                                isPlaying ? player.pause() : player.play(),
                            color: onSurface,
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next_rounded,
                                color: onSurface, size: 26),
                            onPressed: player.next,
                            splashRadius: 24,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseAnimButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final Color color;

  const _PlayPauseAnimButton(
      {required this.isPlaying, required this.onTap, required this.color});

  @override
  State<_PlayPauseAnimButton> createState() => _PlayPauseAnimButtonState();
}

class _PlayPauseAnimButtonState extends State<_PlayPauseAnimButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    if (widget.isPlaying) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _PlayPauseAnimButton old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _ctrl,
        color: widget.color,
        size: 28,
      ),
      onPressed: widget.onTap,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      splashRadius: 24,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Player (Desktop)
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarPlayer extends ConsumerWidget {
  final dynamic theme;
  final dynamic song;
  final bool isPlaying;
  final dynamic player;

  const _SidebarPlayer(
      {required this.theme,
      required this.song,
      required this.isPlaying,
      required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration = ref.watch(audioPlayerProvider.select((s) => s.duration));
    final volume = ref.watch(audioPlayerProvider.select((s) => s.volume));

    final progress =
        duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0;

    return GestureDetector(
        onTap: () => context.push(AppRoutes.player),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface.withAlpha(150),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primary.withAlpha(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  PlatformArtworkWidget(
                    id: song.id,
                    path: song.data,
                    size: 44,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          (song.artist == null ||
                                  song.artist!.trim().toLowerCase() ==
                                      '<unknown>')
                              ? AppLocalizations.of(context)!.unknownArtist
                              : song.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.onSurface.withAlpha(140)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: theme.primary,
                  inactiveTrackColor: theme.primary.withAlpha(20),
                  thumbColor: theme.primary,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (v) {
                    final targetMillis = (v * duration.inMilliseconds).round();
                    player.seek(Duration(milliseconds: targetMillis));
                  },
                ),
              ),
              const SizedBox(height: 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(position.toHmsCompact(),
                      style: const TextStyle(fontSize: 9)),
                  Text(duration.toHmsCompact(),
                      style: const TextStyle(fontSize: 9)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: player.previous,
                      icon: const Icon(Icons.skip_previous_rounded, size: 22),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => isPlaying ? player.pause() : player.play(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: theme.primary, shape: BoxShape.circle),
                      child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: theme.onPrimary,
                          size: 22),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                      onPressed: player.next,
                      icon: const Icon(Icons.skip_next_rounded, size: 22),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.volume_up_rounded,
                      color: theme.onSurface.withAlpha(100), size: 14),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 4),
                        activeTrackColor: theme.primary,
                        inactiveTrackColor: theme.primary.withAlpha(20),
                        thumbColor: theme.primary,
                      ),
                      child: Slider(
                        value: volume,
                        onChanged: (v) => player.setVolume(v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

extension _DurationFmt on Duration {
  String toHmsCompact() {
    final m = inMinutes.remainder(60).toString();
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
