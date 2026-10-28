import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/utils/artwork_widget.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/overlay_mode_provider.dart';
import '../../services/audio/sleep_timer_service.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';
import 'harbor_artwork.dart';
import 'harbor_playback_clock.dart';

/// An always-on-top compact view of the same player and queue.
class HarborMiniPlayer extends ConsumerStatefulWidget {
  const HarborMiniPlayer({super.key});
  @override
  ConsumerState<HarborMiniPlayer> createState() => _HarborMiniPlayerState();
}

class _HarborMiniPlayerState extends ConsumerState<HarborMiniPlayer> {
  bool _settings = false;
  Future<void> _toggleSettings() async {
    setState(() => _settings = !_settings);
    await windowManager.setSize(Size(480, _settings ? 165 : 105));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(audioPlayerProvider.select(harborPlaybackLayout));
    final player = ref.read(audioPlayerProvider);
    final audio = ref.read(audioPlayerProvider.notifier);
    final settings = ref.watch(overlaySettingsProvider);
    final palette = ref.watch(harborThemeProvider);
    final timerActive = ref.watch(sleepTimerProvider.select((s) => s.isActive));
    final song = player.currentSong;
    String t(String s) => harborText(context, s);
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Opacity(
            key: const ValueKey('mini-window-opacity'),
            opacity: settings.transparency.clamp(60, 255) / 255,
            child: Container(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Expanded(
                    child: Row(children: [
                  Expanded(
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (_) => windowManager.startDragging(),
                          child: Row(children: [
                            const SizedBox(width: 10),
                            if (song != null)
                              PlatformArtworkWidget(
                                  id: song.id,
                                  path: song.data,
                                  size: 56,
                                  nullArtworkWidget: HarborArtwork(
                                      size: 56, seed: song.id, playback: true))
                            else
                              const HarborArtwork(size: 56, playback: true),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(song?.title ?? t('Nothing playing yet'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(song?.artist ?? 'ToneHarbor',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFB1C2BA))),
                                ])),
                          ]))),
                  IconButton(
                      tooltip: t('Previous'),
                      onPressed: song == null ? null : audio.previous,
                      icon: const Icon(Icons.skip_previous_rounded)),
                  IconButton(
                      tooltip: t('Play / pause'),
                      onPressed: song == null
                          ? null
                          : () =>
                              player.isPlaying ? audio.pause() : audio.play(),
                      icon: Icon(
                          player.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: palette.accent,
                          size: 32)),
                  IconButton(
                      tooltip: t('Next'),
                      onPressed: song == null ? null : audio.next,
                      icon: const Icon(Icons.skip_next_rounded)),
                  SizedBox(
                      width: 36,
                      child: PopupMenuButton<int>(
                        padding: EdgeInsets.zero,
                        tooltip: t('Sleep timer'),
                        icon: Icon(Icons.timer_outlined,
                            size: 18,
                            color:
                                timerActive ? palette.accent : Colors.white70),
                        onSelected: (v) {
                          final timer = ref.read(sleepTimerProvider.notifier);
                          if (v == 0) {
                            timer.cancel();
                          } else if (song != null) {
                            timer.startTimer(
                                mode: v == -1
                                    ? SleepTimerMode.trackEndLock
                                    : v == -2
                                        ? SleepTimerMode.playlistEndLock
                                        : SleepTimerMode.timeEndLock,
                                minutes: v > 0 ? v : 15);
                          }
                        },
                        itemBuilder: (_) => [
                          for (final minutes in [15, 30, 60])
                            PopupMenuItem(
                                value: minutes,
                                child: Text('$minutes ${t('minutes')}')),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                              value: -1,
                              child: Text(t('Stop after current track'))),
                          PopupMenuItem(
                              value: -2, child: Text(t('Stop after playlist'))),
                          if (timerActive)
                            PopupMenuItem(
                                value: 0, child: Text(t('Cancel timer')))
                        ],
                      )),
                  IconButton(
                      tooltip: t('Settings'),
                      onPressed: _toggleSettings,
                      icon: const Icon(Icons.tune_rounded, size: 19)),
                  IconButton(
                      tooltip: t('Open player'),
                      onPressed: () =>
                          OverlayModeManager.disableOverlay(ref, context),
                      icon: const Icon(Icons.open_in_full_rounded, size: 19)),
                  const SizedBox(width: 4),
                ])),
                if (_settings)
                  SizedBox(
                      height: 55,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(children: [
                            const Icon(Icons.opacity, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Slider(
                                    min: 60,
                                    max: 255,
                                    value: settings.transparency.clamp(60, 255),
                                    onChanged: ref
                                        .read(overlaySettingsProvider.notifier)
                                        .updateTransparency)),
                            Text(
                                '${(settings.transparency / 255 * 100).round()}%',
                                style: const TextStyle(fontSize: 11)),
                          ]))),
                SizedBox(
                    height: 16,
                    child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            activeTrackColor: palette.accent,
                            inactiveTrackColor: Colors.white38,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 4),
                            overlayShape: SliderComponentShape.noOverlay),
                        child: HarborPlaybackClock(
                            builder: (clock) => Slider(
                                  value: clock.position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                          0,
                                          clock.duration.inMilliseconds > 0
                                              ? clock.duration.inMilliseconds
                                                  .toDouble()
                                              : 1),
                                  max: clock.duration.inMilliseconds > 0
                                      ? clock.duration.inMilliseconds.toDouble()
                                      : 1,
                                  onChanged: song == null
                                      ? null
                                      : (v) => audio.seek(
                                          Duration(milliseconds: v.round())),
                                )))),
              ]),
            )));
  }
}
