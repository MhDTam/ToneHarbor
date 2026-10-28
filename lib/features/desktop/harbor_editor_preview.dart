import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// A separate, lazy audio session: auditioning an edit never replaces the user's
/// main playback queue. Position ticks update only the cursor and time readout.
class HarborEditorPreview {
  final AudioPlayer Function() createPlayer;
  AudioPlayer? _player;
  String? _path;
  final position = ValueNotifier(Duration.zero);
  final playing = ValueNotifier(false);
  final error = ValueNotifier<String?>(null);
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _closed = false;
  int _revision = 0;
  HarborEditorPreview({AudioPlayer Function()? createPlayer})
      : createPlayer = createPlayer ?? (() => AudioPlayer());

  Future<void> play(String path) async {
    if (_closed) return;
    final revision = ++_revision;
    final player = _player ??= _create();
    error.value = null;
    if (_path != path) {
      await player.setFilePath(path);
      if (_closed || revision != _revision) return;
      if (player.processingState != ProcessingState.ready) {
        await player.processingStateStream
            .firstWhere((p) => p == ProcessingState.ready)
            .timeout(const Duration(seconds: 15));
      }
      if (_closed || revision != _revision) return;
      _path = path;
    }
    if (_closed || revision != _revision) return;
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    if (_closed || revision != _revision) return;
    unawaited(player.play().catchError((Object e) {
      if (!_closed && revision == _revision) error.value = '$e';
    }));
  }

  AudioPlayer _create() {
    final player = createPlayer();
    _subscriptions.add(player.positionStream.listen((value) {
      if (!_closed && position.value != value) position.value = value;
    }));
    _subscriptions.add(player.playerStateStream.listen((value) {
      if (!_closed) {
        playing.value =
            value.playing && value.processingState != ProcessingState.completed;
      }
    }));
    return player;
  }

  Future<void> pause() async {
    _revision++;
    if (!_closed) playing.value = false;
    await _player?.pause();
  }

  Future<void> restart() async {
    await _player?.seek(Duration.zero);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _revision++;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player?.dispose();
    position.dispose();
    playing.dispose();
    error.dispose();
  }
}
