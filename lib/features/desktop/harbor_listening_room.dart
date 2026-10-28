import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/overlay_mode_provider.dart';
import '../../core/utils/artwork_widget.dart';
import 'harbor_artwork.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';
import 'harbor_waveform.dart';
import 'harbor_playback_clock.dart';

/// One transport surface with an adjacent queue; the shell hides its footer.
class HarborListeningRoom extends ConsumerWidget {
  final PlayerState player;
  final Widget Function(double) artwork;
  final Widget transport, progress, timer, speed;
  final Widget Function(SongModel) options;
  final ValueChanged<SongModel> onPlay;
  const HarborListeningRoom(
      {super.key,
      required this.player,
      required this.artwork,
      required this.transport,
      required this.progress,
      required this.timer,
      required this.speed,
      required this.options,
      required this.onPlay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(harborThemeProvider);
    final song = player.currentSong;
    final liked =
        song != null && ref.watch(favoritesProvider).contains(song.id);
    String t(String s) => harborText(context, s);
    return LayoutBuilder(builder: (context, bounds) {
      final queueBeside = bounds.maxWidth >= 1050;
      final queueWidth = (bounds.maxWidth * .20).clamp(266.0, 420.0);
      final mainWidth =
          bounds.maxWidth - (queueBeside ? queueWidth + 16 : 0) - 48;
      final sideBySide = mainWidth >= 620;
      final artSize = sideBySide
          ? math.min(math.min(520.0, math.max(355.0, bounds.maxHeight * .58)),
              mainWidth * .41)
          : math.min(310.0, mainWidth - 40);
      final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Text(song?.title ?? t('Nothing playing yet'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: mainWidth < 700 ? 22 : 28,
                          height: 1.3,
                          fontWeight: FontWeight.w700))),
              if (song != null) ...[
                IconButton(
                    tooltip: t('Like song'),
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(song.id),
                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? theme.accent : Colors.white60,
                        size: 21)),
                options(song),
              ],
            ]),
            const SizedBox(height: 10),
            Text(song?.artist ?? t('Choose a track to begin'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
            if (song != null && song.album != 'Unknown Album') ...[
              const SizedBox(height: 6),
              Text(song.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
            const SizedBox(height: 34),
            HarborPlaybackClock(
                builder: (live) => HarborWaveform(
                    path: song?.data,
                    duration: live.duration,
                    progress: live.duration.inMilliseconds == 0
                        ? 0
                        : live.position.inMilliseconds /
                            live.duration.inMilliseconds,
                    height: 72,
                    color: theme.accent)),
            const SizedBox(height: 14),
            progress,
            const SizedBox(height: 18),
            KeyedSubtree(
                key: const ValueKey('full-player-transport'), child: transport),
          ]);
      final cover = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            artwork(artSize),
            const SizedBox(height: 15),
            SizedBox(
                width: artSize,
                child: Text(song?.artist ?? t('Your music'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600))),
            const SizedBox(height: 5),
            Text(t('Stored on your device'),
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]);
      final main = Container(
        key: const ValueKey('listening-workspace'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: theme.surface.withAlpha(90),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (sideBySide)
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              cover,
              const SizedBox(width: 28),
              Expanded(child: details)
            ])
          else ...[Center(child: cover), const SizedBox(height: 24), details],
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                        width: sideBySide ? 200 : 160,
                        child: Row(children: [
                          const Icon(Icons.volume_up_outlined,
                              size: 19, color: Colors.white60),
                          Expanded(
                              child: Slider(
                                  key: const ValueKey('full-player-volume'),
                                  value: player.volume.clamp(0, 1),
                                  onChanged: (value) => ref
                                      .read(audioPlayerProvider.notifier)
                                      .setVolume(value))),
                        ])),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      timer,
                      Text(t('Sleep timer'),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70))
                    ]),
                    speed,
                    OutlinedButton.icon(
                        onPressed: () =>
                            OverlayModeManager.enableOverlay(ref, context),
                        icon: const Icon(Icons.picture_in_picture_alt_rounded,
                            size: 17),
                        label: Text(t('Mini player'),
                            style: const TextStyle(fontSize: 12))),
                  ])),
        ]),
      );
      final queueHeight = sideBySide ? math.max(510.0, artSize + 155) : 340.0;
      final queue = _queue(context, theme, height: queueHeight);
      return SingleChildScrollView(
        key: const ValueKey('full-player-page'),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
        child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: math.max(0.0, bounds.maxHeight - 54)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('NOW PLAYING'),
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.6,
                          color: Colors.white60)),
                  const SizedBox(height: 20),
                  if (queueBeside)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: main),
                          const SizedBox(width: 16),
                          SizedBox(width: queueWidth, child: queue)
                        ])
                  else ...[main, const SizedBox(height: 16), queue],
                ])),
      );
    });
  }

  Widget _queue(BuildContext context, HarborTheme theme,
      {required double height}) {
    final start = (player.currentIndex + 1).clamp(0, player.queue.length);
    final count = player.queue.length - start;
    String t(String s) => harborText(context, s);
    return Container(
        key: const ValueKey('full-player-queue'),
        height: height,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        decoration: BoxDecoration(
            color: theme.surface.withAlpha(90),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border)),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(t('Next up'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600))),
            const SizedBox(width: 10),
            Text('$count', style: TextStyle(color: theme.accent, fontSize: 12))
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
              child: count == 0
                  ? Center(
                      child: Text(t('Your queue will appear here.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)))
                  : ListView.separated(
                      itemCount: count,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final song = player.queue[start + i];
                        return InkWell(
                            key: ValueKey('full-queue-track-${song.id}'),
                            onTap: () => onPlay(song),
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(children: [
                                  PlatformArtworkWidget(
                                      id: song.id,
                                      path: song.data,
                                      size: 38,
                                      nullArtworkWidget: HarborArtwork(
                                          size: 38, seed: song.id)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        const SizedBox(height: 5),
                                        Text(song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white54)),
                                      ])),
                                  const SizedBox(width: 4),
                                  Text(song.durationFormatted,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white54)),
                                  SizedBox(width: 28, child: options(song)),
                                ])));
                      })),
        ]));
  }
}
