import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio/audio_player_service.dart';

/// Position ticks must not rebuild covers, metadata, menus or queue rows.
Object harborPlaybackLayout(PlayerState p) => (
      p.queue,
      p.currentIndex,
      p.isPlaying,
      p.isShuffle,
      p.repeatMode,
      p.duration,
      p.playbackSpeed,
      p.volume,
    );

class HarborPlaybackClock extends ConsumerWidget {
  final Widget Function(PlayerState) builder;
  const HarborPlaybackClock({super.key, required this.builder});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(audioPlayerProvider
        .select((p) => (p.position, p.duration, p.currentIndex, p.queue)));
    return builder(ref.read(audioPlayerProvider));
  }
}

class HarborContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const HarborContentWidth(
      {super.key, required this.child, this.maxWidth = 2200});
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
              width: double.infinity, height: double.infinity, child: child)));
}
