import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/platform_utils.dart';
import '../../data/models/song_model.dart';
import '../../services/audio/audio_player_service.dart';
import 'harbor_strings.dart';
import '../../core/utils/app_toast.dart';

/// Play the exact successful output inside the existing audio session. This
/// does not import the source video or automatically add anything to Library.
class HarborOutputPlayButton extends ConsumerStatefulWidget {
  final String path;
  final bool compact;
  const HarborOutputPlayButton(
      {super.key, required this.path, this.compact = false});
  @override
  ConsumerState<HarborOutputPlayButton> createState() =>
      _HarborOutputPlayButtonState();
}

class _HarborOutputPlayButtonState
    extends ConsumerState<HarborOutputPlayButton> {
  bool pending = false;
  Future<void> _play() async {
    if (pending) return;
    setState(() => pending = true);
    try {
      if (!await File(widget.path).exists()) {
        throw const FileSystemException('Output file is missing');
      }
      if (!mounted) return;
      final song = SongModel(
          id: stablePathId(widget.path),
          title: p.basenameWithoutExtension(widget.path),
          artist: 'Unknown Artist',
          album: 'Converted audio',
          data: widget.path,
          duration: 0,
          dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000);
      await ref
          .read(audioPlayerProvider.notifier)
          .playSong(song, queue: [song], index: 0);
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, '${harborText(context, 'Could not play audio')}: $e');
      }
    } finally {
      if (mounted) setState(() => pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = harborText(context, 'Play audio');
    return widget.compact
        ? IconButton(
            tooltip: label,
            onPressed: pending ? null : _play,
            icon: const Icon(Icons.play_circle_outline_rounded, size: 24))
        : TextButton.icon(
            onPressed: pending ? null : _play,
            icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
            label: Text(label));
  }
}
