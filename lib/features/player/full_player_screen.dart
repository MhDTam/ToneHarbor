import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/audio/sleep_timer_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/audio/artwork_provider.dart';
import 'sleep_timer_bottom_sheet.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../core/utils/song_options_modal.dart';
import '../../core/utils/app_icons.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeDataProvider);
    final song = ref.watch(audioPlayerProvider.select((s) => s.currentSong));
    final isFavorite =
        song != null ? ref.watch(favoritesProvider).contains(song.id) : false;
    final screenWidth = MediaQuery.of(context).size.width;

    if (song == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off_rounded, color: theme.primary, size: 64),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.noSongPlaying,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(AppLocalizations.of(context)!.back),
              ),
            ],
          ),
        ),
      );
    }

    // Artwork size: capped on desktop
    final artworkSize = isDesktop
        ? min(screenWidth * 0.35, 350.0)
        : screenWidth * 0.75; // Shrunk slightly from 0.8 to create more room

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isDesktop
          ? _desktopPlayerLayout(
              context, ref, theme, song, isFavorite, artworkSize)
          : _mobilePlayerLayout(
              context, ref, theme, song, isFavorite, artworkSize),
    );
  }

  Widget _mobilePlayerLayout(BuildContext context, WidgetRef ref, dynamic theme,
      dynamic song, bool isFavorite, double artworkSize) {
    return Dismissible(
      key: const Key('full_player'),
      direction: DismissDirection.down,
      onDismissed: (_) => context.pop(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppBackground(
            theme: theme,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            child: const SizedBox.expand(),
          ),
          Container(
            color: theme.background
                .withAlpha(theme.backgroundImage != null ? 60 : 180),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(theme: theme, song: song, ref: ref),
                const Spacer(),
                _ArtworkBox(
                    theme: theme,
                    size: artworkSize,
                    songPath: song.data,
                    songId: song.id),
                const Spacer(),
                _SongInfo(
                    theme: theme, song: song, isFavorite: isFavorite, ref: ref),
                const Spacer(),
                _PlaybackProgress(theme: theme),
                const SizedBox(height: 16),
                _ModeToggles(theme: theme),
                const SizedBox(height: 24),
                _PlaybackControls(theme: theme),
                const SizedBox(height: 16),
                _VolumeSlider(theme: theme),
                const Spacer(
                    flex: 3), // Increased bottom flex to push controls higher
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopPlayerLayout(BuildContext context, WidgetRef ref,
      dynamic theme, dynamic song, bool isFavorite, double artworkSize) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppBackground(
          theme: theme,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          child: const SizedBox.expand(),
        ),
        Container(
          color: theme.background
              .withAlpha(theme.backgroundImage != null ? 60 : 180),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _TopBar(theme: theme, song: song, ref: ref),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Artwork on the left
                    _ArtworkBox(
                        theme: theme,
                        size: artworkSize,
                        songPath: song.data,
                        songId: song.id),
                    const SizedBox(width: 48),
                    // Controls on the right
                    SizedBox(
                      width: 350,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SongInfo(
                              theme: theme,
                              song: song,
                              isFavorite: isFavorite,
                              ref: ref),
                          const SizedBox(height: 24),
                          _PlaybackProgress(theme: theme),
                          const SizedBox(height: 16),
                          _PlaybackControls(theme: theme),
                          const SizedBox(height: 20),
                          _VolumeSlider(theme: theme),
                          const SizedBox(height: 20),
                          _ModeToggles(theme: theme),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final dynamic theme;
  final dynamic song;
  final WidgetRef ref;

  const _TopBar({required this.theme, required this.song, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: theme.onSurface, size: 32),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.nowPlaying,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: theme.onSurface),
            onPressed: () => SongOptionsModal.show(
              context: context,
              ref: ref,
              song: song,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Artwork Box – shows album art or animated visualizer
// ═════════════════════════════════════════════════════════════════════════════
class _ArtworkBox extends ConsumerWidget {
  final dynamic theme;
  final double size;
  final String songPath;
  final int songId;

  const _ArtworkBox({
    required this.theme,
    required this.size,
    required this.songPath,
    required this.songId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mobile: MediaStore lookup by id; desktop: embedded picture. Songs without
    // a real MediaStore id fall back to the embedded picture.
    final artworkAsync = (isMobile && isValidMediaStoreId(songId))
        ? ref.watch(artworkBytesByIdProvider(songId))
        : ref.watch(artworkBytesProvider(songPath));

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (theme.primary as Color).withAlpha(60),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: artworkAsync.when(
            data: (bytes) {
              if (bytes != null && bytes.isNotEmpty) {
                // Show actual album art
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (_, __, ___) =>
                      _VisualizerFallback(theme: theme, size: size),
                );
              }
              return _VisualizerFallback(theme: theme, size: size);
            },
            loading: () => Container(
              color: theme.surface,
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
            error: (_, __) => _VisualizerFallback(theme: theme, size: size),
          ),
        ),
      ),
    );
  }
}

/// Animated audio visualizer with gradient background for when no art is available
class _VisualizerFallback extends ConsumerStatefulWidget {
  final dynamic theme;
  final double size;
  const _VisualizerFallback({required this.theme, required this.size});

  @override
  ConsumerState<_VisualizerFallback> createState() =>
      _VisualizerFallbackState();
}

class _VisualizerFallbackState extends ConsumerState<_VisualizerFallback>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final primary = widget.theme.primary as Color;

    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _pulseController]),
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withAlpha(40),
                (widget.theme.surface as Color),
                primary.withAlpha(25),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _AudioVisualizerPainter(
              animationValue: _waveController.value,
              pulseValue: _pulseController.value,
              primaryColor: primary,
              isPlaying: isPlaying,
            ),
            child: Center(
              child: AnimatedScale(
                scale: isPlaying ? 1.0 + (_pulseController.value * 0.06) : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: widget.size * 0.22,
                  height: widget.size * 0.22,
                  decoration: BoxDecoration(
                    color: primary.withAlpha(isPlaying ? 35 : 20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: primary.withAlpha(isPlaying ? 200 : 120),
                    size: widget.size * 0.12,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the audio visualizer wave bars
class _AudioVisualizerPainter extends CustomPainter {
  final double animationValue;
  final double pulseValue;
  final Color primaryColor;
  final bool isPlaying;

  _AudioVisualizerPainter({
    required this.animationValue,
    required this.pulseValue,
    required this.primaryColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const barCount = 28;
    final maxBarHeight = size.height * 0.32;
    final barWidth = size.width * 0.012;
    final radius = size.width * 0.30;

    for (int i = 0; i < barCount; i++) {
      final angle = (2 * pi * i / barCount) - (pi / 2);
      final phase = animationValue * 2 * pi;

      // Create varied heights using multiple sine waves
      double heightFactor;
      if (isPlaying) {
        heightFactor = (0.3 +
            0.25 * sin(phase + i * 0.8) +
            0.2 * cos(phase * 1.5 + i * 1.2) +
            0.15 * sin(phase * 2.3 + i * 0.5) +
            0.1 * pulseValue);
      } else {
        // Idle: gentle breathing
        heightFactor = 0.15 + 0.08 * sin(pulseValue * pi + i * 0.3);
      }

      final barHeight = maxBarHeight * heightFactor.clamp(0.08, 1.0);

      // Position bars in a circle
      final innerX = centerX + radius * cos(angle);
      final innerY = centerY + radius * sin(angle);
      final outerX = centerX + (radius + barHeight) * cos(angle);
      final outerY = centerY + (radius + barHeight) * sin(angle);

      final alpha =
          isPlaying ? (80 + (heightFactor * 120)).round().clamp(40, 200) : 35;

      final paint = Paint()
        ..color = primaryColor.withAlpha(alpha)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AudioVisualizerPainter oldDelegate) => true;
}

// ═════════════════════════════════════════════════════════════════════════════
// Song Info – handles <unknown> text elegantly
// ═════════════════════════════════════════════════════════════════════════════
class _SongInfo extends StatelessWidget {
  final dynamic theme;
  final dynamic song;
  final bool isFavorite;
  final WidgetRef ref;

  const _SongInfo(
      {required this.theme,
      required this.song,
      required this.isFavorite,
      required this.ref});

  String _cleanArtist(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty ||
        lower == '<unknown>' ||
        lower == 'unknown' ||
        lower == 'unknown artist' ||
        lower == '<unknown artist>') {
      return '';
    }
    return raw.trim();
  }

  @override
  Widget build(BuildContext context) {
    final displayArtist = _cleanArtist(song.artist);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (displayArtist.isNotEmpty)
                  Text(
                    displayArtist,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: theme.onSurface.withAlpha(180)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    AppLocalizations.of(context)!.unknownArtist,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: theme.onSurface.withAlpha(80),
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.red : theme.onSurface.withAlpha(140),
              size: 28,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(song.id),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final bool active;
  final dynamic theme;
  final VoidCallback onTap;

  const _ModeButton({
    this.icon,
    this.customIcon,
    required this.label,
    required this.active,
    required this.theme,
    required this.onTap,
  }) : assert(icon != null || customIcon != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.primary.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? theme.primary : Colors.transparent, width: 1),
        ),
        child: Column(
          children: [
            customIcon ??
                Icon(icon,
                    color:
                        active ? theme.primary : theme.onSurface.withAlpha(120),
                    size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? theme.primary : theme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackProgress extends ConsumerStatefulWidget {
  final dynamic theme;
  const _PlaybackProgress({required this.theme});

  @override
  ConsumerState<_PlaybackProgress> createState() => _PlaybackProgressState();
}

class _PlaybackProgressState extends ConsumerState<_PlaybackProgress> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration = ref.watch(audioPlayerProvider.select((s) => s.duration));
    final player = ref.read(audioPlayerProvider.notifier);

    final totalSec = duration.inSeconds.toDouble();
    final currentValue = _isDragging
        ? _dragValue
        : (totalSec > 0 ? position.inSeconds.toDouble() / totalSec : 0.0)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: widget.theme.primary,
              inactiveTrackColor: widget.theme.primary.withAlpha(40),
              thumbColor: widget.theme.primary,
              overlayColor: widget.theme.primary.withAlpha(30),
            ),
            child: Slider(
              value: currentValue,
              onChangeStart: (v) => setState(() {
                _isDragging = true;
                _dragValue = v;
              }),
              onChanged: (v) => setState(() => _dragValue = v),
              onChangeEnd: (v) {
                player.seek(Duration(seconds: (v * totalSec).round()));
                setState(() => _isDragging = false);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    _isDragging
                        ? Duration(seconds: (_dragValue * totalSec).round())
                            .toHms2()
                        : position.toHms2(),
                    style: Theme.of(context).textTheme.bodySmall),
                Text(duration.toHms2(),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggles extends ConsumerWidget {
  final dynamic theme;
  const _ModeToggles({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSingle =
        ref.watch(audioPlayerProvider.select((s) => s.isSingleTrack));
    final isShuffle = ref.watch(audioPlayerProvider.select((s) => s.isShuffle));
    final repeatMode =
        ref.watch(audioPlayerProvider.select((s) => s.repeatMode));
    final speed = ref.watch(audioPlayerProvider.select((s) => s.playbackSpeed));
    final timerState = ref.watch(sleepTimerProvider);
    final player = ref.read(audioPlayerProvider.notifier);

    final l = AppLocalizations.of(context)!;

    String repeatLabel = l.repeat;
    if (repeatMode == RepeatState.one) repeatLabel = '${l.repeat} (1)';
    if (repeatMode == RepeatState.three) repeatLabel = '${l.repeat} (3)';
    if (repeatMode == RepeatState.infinite) {
      repeatLabel = '${l.repeat} (\u221E)';
    }

    String timerLabel = l.timer;
    if (timerState.isActive) {
      if (timerState.mode == SleepTimerMode.timeEndLock) {
        timerLabel = '${timerState.remainingSeconds ~/ 60}m';
      } else if (timerState.mode == SleepTimerMode.trackEndLock) {
        timerLabel = l.track;
      } else {
        timerLabel = l.list;
      }
    }

    Widget timerIcon = Icon(Icons.bedtime_rounded,
        color: timerState.isActive
            ? theme.primary
            : theme.onSurface.withAlpha(120),
        size: 20);

    if (timerState.isActive) {
      if (timerState.mode == SleepTimerMode.timeEndLock &&
          timerState.totalSeconds > 0) {
        final progress = timerState.remainingSeconds / timerState.totalSeconds;
        timerIcon = SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                backgroundColor: theme.primary.withAlpha(50),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
              Icon(Icons.bedtime_rounded, color: theme.primary, size: 14),
            ],
          ),
        );
      } else {
        final iconData = timerState.mode == SleepTimerMode.trackEndLock
            ? Icons.music_off_rounded
            : AppIcons.queueMusic;
        timerIcon = Icon(iconData, color: theme.primary, size: 20);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ModeButton(
              icon: Icons.repeat_one_rounded,
              label: l.single,
              active: isSingle,
              theme: theme,
              onTap: () => player.toggleSingleTrackMode()),
          _ModeButton(
              icon: Icons.shuffle_rounded,
              label: l.shuffle,
              active: isShuffle,
              theme: theme,
              onTap: () => player.toggleShuffleMode()),
          _ModeButton(
              icon: Icons.repeat_rounded,
              label: repeatLabel,
              active: repeatMode != RepeatState.off,
              theme: theme,
              onTap: () => player.toggleRepeatMode()),
          _ModeButton(
              icon: Icons.speed_rounded,
              label: '${speed}x',
              active: speed != 1.0,
              theme: theme,
              onTap: () => _showSpeedSelector(context, ref, speed)),
          _ModeButton(
              customIcon: timerIcon,
              label: timerLabel,
              active: timerState.isActive,
              theme: theme,
              onTap: () => _showSleepTimer(context)),
        ],
      ),
    );
  }

  void _showSpeedSelector(
      BuildContext context, WidgetRef ref, double currentSpeed) {
    final player = ref.read(audioPlayerProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(AppLocalizations.of(context)!.playbackSpeed,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((s) => ListTile(
                title: Text('${s}x', textAlign: TextAlign.center),
                selected: currentSpeed == s,
                selectedColor: theme.primary,
                onTap: () {
                  player.setSpeed(s);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSleepTimer(BuildContext ctx) {
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SleepTimerBottomSheet());
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Playback Controls – with animated play/pause icon
// ═════════════════════════════════════════════════════════════════════════════
class _PlaybackControls extends ConsumerStatefulWidget {
  final dynamic theme;
  const _PlaybackControls({required this.theme});

  @override
  ConsumerState<_PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends ConsumerState<_PlaybackControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Initialize to current state
    final isPlaying = ref.read(audioPlayerProvider).isPlaying;
    if (isPlaying) _animController.value = 1.0;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final player = ref.read(audioPlayerProvider.notifier);

    // Smoothly animate icon
    if (isPlaying) {
      _animController.forward();
    } else {
      _animController.reverse();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10_rounded,
                  color: widget.theme.onSurface.withAlpha(200), size: 28),
              onPressed: () =>
                  player.seekRelative(const Duration(seconds: -10)),
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.theme.surface.withAlpha(100),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: widget.theme.onSurface.withAlpha(20)),
                ),
                child: Icon(Icons.stop_rounded,
                    color: widget.theme.onSurface.withAlpha(200), size: 24),
              ),
              onPressed: () async {
                await player.pause();
                await player.seek(Duration.zero);
              },
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: Icon(Icons.forward_10_rounded,
                  color: widget.theme.onSurface.withAlpha(200), size: 28),
              onPressed: () => player.seekRelative(const Duration(seconds: 10)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.skip_previous_rounded,
                  color: widget.theme.onSurface, size: 36),
              onPressed: player.previous,
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () => isPlaying ? player.pause() : player.play(),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      (widget.theme.primary as Color).withAlpha(255),
                      (widget.theme.primary as Color).withAlpha(200),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.theme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: (widget.theme.primary as Color).withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4)),
                    BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: CurvedAnimation(
                      parent: _animController,
                      curve: Curves.easeInOut,
                    ),
                    color: widget.theme.onPrimary.withAlpha(235),
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: Icon(Icons.skip_next_rounded,
                  color: widget.theme.onSurface, size: 36),
              onPressed: player.next,
            ),
          ],
        ),
      ],
    );
  }
}

class _VolumeSlider extends ConsumerStatefulWidget {
  final dynamic theme;
  const _VolumeSlider({required this.theme});

  @override
  ConsumerState<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends ConsumerState<_VolumeSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final trueVolume = ref.watch(audioPlayerProvider.select((s) => s.volume));
    final player = ref.read(audioPlayerProvider.notifier);

    final displayVolume = _dragValue ?? trueVolume;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Icon(
            displayVolume == 0
                ? Icons.volume_off_rounded
                : displayVolume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
            color: widget.theme.onSurface.withAlpha(150),
            size: 20,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: widget.theme.primary.withAlpha(200),
                inactiveTrackColor: widget.theme.primary.withAlpha(40),
                thumbColor: widget.theme.primary,
                overlayColor: widget.theme.primary.withAlpha(30),
              ),
              child: Slider(
                value: displayVolume,
                onChangeStart: (v) => setState(() => _dragValue = v),
                onChanged: (v) {
                  setState(() => _dragValue = v);
                },
                onChangeEnd: (v) {
                  player.setVolume(v);
                  setState(() => _dragValue = null);
                },
              ),
            ),
          ),
          Text(
            '${(displayVolume * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.theme.onSurface.withAlpha(150),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

extension _DurationFmt on Duration {
  String toHms2() {
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
