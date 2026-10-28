import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/audio/sleep_timer_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/artwork_widget.dart';
import '../../services/overlay_mode_provider.dart';
import '../../l10n/app_localizations.dart';

class OverlayMiniPlayer extends ConsumerStatefulWidget {
  const OverlayMiniPlayer({super.key});

  @override
  ConsumerState<OverlayMiniPlayer> createState() => _OverlayMiniPlayerState();
}

class _OverlayMiniPlayerState extends ConsumerState<OverlayMiniPlayer> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final player = ref.read(audioPlayerProvider.notifier);
    final theme = ref.watch(currentThemeDataProvider);
    // Only watch the fields this widget actually renders: watching the whole
    // player state rebuilt the overlay on every playback position tick.
    final song = ref.watch(audioPlayerProvider.select((s) => s.currentSong));
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final repeatMode =
        ref.watch(audioPlayerProvider.select((s) => s.repeatMode));

    final timerState = ref.watch(sleepTimerProvider);
    final timerService = ref.read(sleepTimerProvider.notifier);

    final overlaySettings = ref.watch(overlaySettingsProvider);
    final overlayNotifier = ref.read(overlaySettingsProvider.notifier);
    final transparency = overlaySettings.transparency;
    final isBlurEnabled = overlaySettings.blur;

    if (song == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onPanStart: (_) => windowManager.startDragging(),
          child: Container(
            decoration: BoxDecoration(
              color: theme.surface.withAlpha(transparency.toInt()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () =>
                    OverlayModeManager.disableOverlay(ref, context),
              ),
            ),
          ),
        ),
      );
    }

    // --- Settings Panel ---
    if (_showSettings) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildBody(
          isBlurEnabled: isBlurEnabled,
          transparency: transparency,
          theme: theme,
          child: GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded,
                            color: theme.onSurface, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _showSettings = false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            AppLocalizations.of(context)!.overlaySettings,
                            style: TextStyle(
                                color: theme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.opacity_rounded,
                          color: theme.onSurface.withAlpha(150), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onPanStart: (_) {}, // block drag on slider
                          child: Slider(
                            value: transparency,
                            min: 0,
                            max: 255,
                            activeColor: theme.primary,
                            inactiveColor: theme.primary.withAlpha(50),
                            onChanged: (val) =>
                                overlayNotifier.updateTransparency(val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.blur_on_rounded,
                              color: theme.onSurface.withAlpha(150), size: 16),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.backgroundBlur,
                              style: TextStyle(
                                  color: theme.onSurface, fontSize: 12)),
                        ],
                      ),
                      GestureDetector(
                        onPanStart: (_) {},
                        child: Switch(
                          value: isBlurEnabled,
                          activeThumbColor: theme.primary,
                          onChanged: (val) => overlayNotifier.updateBlur(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      overlayNotifier.resetToDefault();
                      setState(() => _showSettings = false);
                    },
                    icon: Icon(Icons.restore_rounded,
                        size: 14, color: theme.primary),
                    label: Text(AppLocalizations.of(context)!.resetToDefault,
                        style: TextStyle(color: theme.primary, fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // --- Main Player ---
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(
        isBlurEnabled: isBlurEnabled,
        transparency: transparency,
        theme: theme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 70,
              child: Row(
                children: [
                  // ---- Drag Zone: Artwork + Title ----
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) => windowManager.startDragging(),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: PlatformArtworkWidget(
                                id: song.id,
                                path: song.data,
                                size: 54,
                                backgroundColor: theme.primary.withAlpha(30),
                                iconColor: theme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: theme.onSurface),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: theme.onSurface.withAlpha(140),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ---- Controls: NOT inside any drag handler ----
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.skip_previous_rounded,
                        color: theme.onSurface, size: 22),
                    onPressed: () => player.previous(),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.primary,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          player.pause();
                        } else {
                          player.play();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.skip_next_rounded,
                        color: theme.onSurface, size: 22),
                    onPressed: () => player.next(),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      repeatMode == RepeatState.infinite
                          ? Icons.repeat_rounded
                          : repeatMode == RepeatState.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                      color: repeatMode == RepeatState.off
                          ? theme.onSurface.withAlpha(100)
                          : theme.primary,
                      size: 16,
                    ),
                    onPressed: () => player.toggleRepeatMode(),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<int>(
                    tooltip: AppLocalizations.of(context)!.sleepTimer,
                    color: theme.surface,
                    icon: Icon(
                      Icons.timer_outlined,
                      color: timerState.isActive
                          ? theme.primary
                          : theme.onSurface.withAlpha(100),
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (minutes) {
                      if (minutes == 0) {
                        timerService.cancel();
                      } else {
                        timerService.startTimer(
                            mode: SleepTimerMode.timeEndLock, minutes: minutes);
                      }
                    },
                    itemBuilder: (context) => [
                      if (timerState.isActive) ...[
                        PopupMenuItem(
                          value: 0,
                          child: Text(
                            AppLocalizations.of(context)!.cancelTimer,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        const PopupMenuDivider(),
                      ],
                      for (final item in [15, 30, 45, 60, 90, 120])
                        PopupMenuItem(
                            value: item,
                            child: Text(
                                '$item ${AppLocalizations.of(context)!.minutes}')),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // ---- Action buttons ----
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.settings_rounded,
                                  color: theme.onSurface.withAlpha(150),
                                  size: 14),
                              tooltip:
                                  AppLocalizations.of(context)!.overlaySettings,
                              onPressed: () =>
                                  setState(() => _showSettings = true),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.open_in_full_rounded,
                                  color: theme.onSurface.withAlpha(150),
                                  size: 14),
                              tooltip:
                                  AppLocalizations.of(context)!.expandToFullApp,
                              onPressed: () =>
                                  OverlayModeManager.disableOverlay(
                                      ref, context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.orangeAccent, size: 14),
                          tooltip: AppLocalizations.of(context)!.closeApp,
                          onPressed: () => windowManager.close(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ---- Interactive progress bar (own widget so only it rebuilds
            //      on every position tick) ----
            _OverlayProgressBar(theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isBlurEnabled,
    required double transparency,
    required dynamic theme,
    required Widget child,
  }) {
    Widget container = Container(
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(transparency.toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );

    Widget visual = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isBlurEnabled
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: container,
            )
          : container,
    );

    // Stack: content determines size, resize edges overlay on top
    const double e = 3;
    return Stack(
      children: [
        visual, // ← This child sizes the Stack naturally
        // Resize edges on top (translucent = taps pass through to buttons below)
        Positioned.fill(
          child: Column(
            children: [
              Row(children: [
                _resizeHandle(
                    ResizeEdge.topLeft, SystemMouseCursors.resizeUpLeft,
                    w: e, h: e),
                Expanded(
                    child: _resizeHandle(
                        ResizeEdge.top, SystemMouseCursors.resizeUp,
                        h: e)),
                _resizeHandle(
                    ResizeEdge.topRight, SystemMouseCursors.resizeUpRight,
                    w: e, h: e),
              ]),
              Expanded(
                  child: Row(children: [
                _resizeHandle(ResizeEdge.left, SystemMouseCursors.resizeLeft,
                    w: e, h: double.infinity),
                const Expanded(child: SizedBox.shrink()),
                _resizeHandle(ResizeEdge.right, SystemMouseCursors.resizeRight,
                    w: e, h: double.infinity),
              ])),
              Row(children: [
                _resizeHandle(
                    ResizeEdge.bottomLeft, SystemMouseCursors.resizeDownLeft,
                    w: e, h: e),
                Expanded(
                    child: _resizeHandle(
                        ResizeEdge.bottom, SystemMouseCursors.resizeDown,
                        h: e)),
                _resizeHandle(
                    ResizeEdge.bottomRight, SystemMouseCursors.resizeDownRight,
                    w: e, h: e),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resizeHandle(ResizeEdge edge, MouseCursor cursor,
      {double? w, double? h}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startResizing(edge),
      child: MouseRegion(
        cursor: cursor,
        child: SizedBox(width: w, height: h),
      ),
    );
  }
}

/// Interactive progress bar for the overlay. Kept in its own widget so the
/// frequent position updates only rebuild this small widget.
class _OverlayProgressBar extends ConsumerWidget {
  final dynamic theme;
  const _OverlayProgressBar({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration = ref.watch(audioPlayerProvider.select((s) => s.duration));
    final player = ref.read(audioPlayerProvider.notifier);

    final totalMs = duration.inMilliseconds;
    final value =
        totalMs > 0 ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: SizedBox(
        height: 6,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
            activeTrackColor: theme.primary,
            inactiveTrackColor: theme.onSurface.withAlpha(30),
            thumbColor: Colors.transparent,
          ),
          child: GestureDetector(
            onPanStart: (_) {}, // Block window drag on the slider
            child: Slider(
              value: value,
              onChanged: (val) {
                if (totalMs <= 0) return;
                player.seek(Duration(milliseconds: (val * totalMs).round()));
              },
            ),
          ),
        ),
      ),
    );
  }
}
