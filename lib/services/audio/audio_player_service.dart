import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/playlist_repository.dart';
import 'audio_handler.dart';
import 'audio_player_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Playback Mode Types
// ─────────────────────────────────────────────────────────────────────────────
enum RepeatState { off, one, three, infinite }

// ─────────────────────────────────────────────────────────────────────────────
// State class
// ─────────────────────────────────────────────────────────────────────────────
class PlayerState {
  final List<SongModel> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isSingleTrack;
  final RepeatState repeatMode;
  final bool isShuffle;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final AppProcessingState processingState;
  final double volume;
  final bool isMiniPlayerVisible;

  const PlayerState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isSingleTrack = false,
    this.repeatMode = RepeatState.off,
    this.isShuffle = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.processingState = AppProcessingState.idle,
    this.volume = 1.0,
    this.isMiniPlayerVisible = true,
  });

  SongModel? get currentSong => currentIndex >= 0 && currentIndex < queue.length
      ? queue[currentIndex]
      : null;

  PlayerState copyWith({
    List<SongModel>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isSingleTrack,
    RepeatState? repeatMode,
    bool? isShuffle,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    AppProcessingState? processingState,
    double? volume,
    bool? isMiniPlayerVisible,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isSingleTrack: isSingleTrack ?? this.isSingleTrack,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffle: isShuffle ?? this.isShuffle,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      processingState: processingState ?? this.processingState,
      volume: volume ?? this.volume,
      isMiniPlayerVisible: isMiniPlayerVisible ?? this.isMiniPlayerVisible,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio Player Notifier
// ─────────────────────────────────────────────────────────────────────────────
class AudioPlayerNotifier extends StateNotifier<PlayerState> {
  final ToneHarborAudioHandler _handler;
  final Ref ref;

  /// Kept so they can be cancelled in [dispose] – leaking these would keep
  /// writing to a disposed StateNotifier after the provider is torn down.
  final List<StreamSubscription<dynamic>> _subs = [];

  /// Last song id that was pushed to the "recently played" list, used to avoid
  /// duplicate entries when the handler re-emits the same queue index.
  int? _lastRecentSongId;
  int _commandRevision = 0, _pendingStops = 0;

  AudioPlayerNotifier(this._handler, this.ref) : super(const PlayerState()) {
    _listenToStreams();
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    super.dispose();
  }

  void _listenToStreams() {
    _subs.add(
      _handler.positionStream.listen((pos) {
        if (pos == state.position) return;
        state = state.copyWith(position: pos);
      }),
    );
    _subs.add(
      _handler.durationStream.listen((dur) {
        if (dur != null && dur != state.duration) {
          state = state.copyWith(duration: dur);
        }
      }),
    );
    _subs.add(
      _handler.speedStream.listen((speed) {
        if (speed == state.playbackSpeed) return;
        state = state.copyWith(playbackSpeed: speed);
      }),
    );
    _subs.add(
      _handler.playbackStateStream.listen((ps) {
        if (ps.playing == state.isPlaying &&
            ps.processingState == state.processingState) {
          return;
        }
        state = state.copyWith(
          isPlaying: ps.playing,
          processingState: ps.processingState,
        );
      }),
    );
    _subs.add(
      _handler.currentIndexStream.listen((idx) {
        if (idx == null || idx < 0 || idx >= state.queue.length) return;
        final changed = idx != state.currentIndex;
        state = state.copyWith(
          currentIndex: idx,
          position: changed ? Duration.zero : null,
          duration: changed && idx >= 0 && idx < state.queue.length
              ? Duration(milliseconds: state.queue[idx].duration)
              : null,
        );
        final song = state.currentSong;
        if (song != null && song.id != _lastRecentSongId) {
          _lastRecentSongId = song.id;
          ref
              .read(playlistRepositoryProvider.notifier)
              .addToRecentlyPlayed(song.id);
        }
      }),
    );
    _subs.add(
      _handler.customStateStream.listen((custom) {
        final repeatIndex = custom['repeat'] as int? ?? 0;
        state = state.copyWith(
          isSingleTrack: custom['single'] as bool?,
          isShuffle: custom['shuffle'] as bool?,
          repeatMode:
              (repeatIndex >= 0 && repeatIndex < RepeatState.values.length)
              ? RepeatState.values[repeatIndex]
              : RepeatState.off,
        );
      }),
    );
    _subs.add(
      _handler.volumeStream.listen((vol) {
        if (vol == state.volume) return;
        state = state.copyWith(volume: vol);
      }),
    );
  }

  Future<void> playSong(
    SongModel song, {
    List<SongModel>? queue,
    int index = 0,
  }) async {
    _commandRevision++;
    final reloadAfterStop = _pendingStops > 0;
    state = state.copyWith(isMiniPlayerVisible: true);

    var q = (queue == null || queue.isEmpty) ? <SongModel>[song] : queue;
    // A row's identity takes precedence over a stale/default display index.
    // Preserve a valid occurrence when the queue contains duplicates.
    var i = index;
    if (i < 0 || i >= q.length || q[i].id != song.id) {
      i = q.indexWhere((entry) => entry.id == song.id);
    }
    if (i < 0) {
      q = [...q, song];
      i = q.length - 1;
    }
    final sameQueue =
        identical(q, state.queue) ||
        (q.length == state.queue.length &&
            q.indexed.every(
              (entry) => entry.$2.id == state.queue[entry.$1].id,
            ));

    // Same audio source: just re-point the queue so that next/previous follow
    // the list the user actually tapped in, without reloading the file.
    if (!reloadAfterStop && sameQueue && state.currentSong?.id == q[i].id) {
      if (!state.isPlaying) await play();
      return;
    }
    if (!reloadAfterStop && state.currentSong?.id == q[i].id) {
      state = state.copyWith(queue: q, currentIndex: i);
      await _handler.setQueueFromSongs(q, i, reload: false);
      if (!state.isPlaying) await play();
      return;
    }

    if (!reloadAfterStop && sameQueue) {
      // Acknowledge the click before waiting for the decoder to open the file.
      state = state.copyWith(
        currentIndex: i,
        position: Duration.zero,
        duration: Duration(milliseconds: q[i].duration),
      );
      await _handler.skipToQueueItem(i);
      return;
    }

    state = state.copyWith(
      queue: q,
      currentIndex: i,
      position: Duration.zero,
      duration: Duration(milliseconds: q[i].duration),
    );
    await _handler.setQueueFromSongs(q, i);
  }

  Future<void> enqueueSongs(List<SongModel> songs, {bool next = false}) async {
    if (songs.isEmpty) return;
    _commandRevision++;
    final hadCurrent = state.currentSong != null;
    final queue = List<SongModel>.of(state.queue);
    final index = hadCurrent ? state.currentIndex : 0;
    queue.insertAll(next && hadCurrent ? index + 1 : queue.length, songs);
    final playing = state.isPlaying;
    state = state.copyWith(
      queue: queue,
      currentIndex: index,
      isMiniPlayerVisible: true,
      duration: hadCurrent
          ? null
          : Duration(milliseconds: queue.first.duration),
      position: hadCurrent ? null : Duration.zero,
    );
    await _handler.setQueueFromSongs(
      queue,
      index,
      reload: !hadCurrent || _pendingStops > 0,
      startPlaying: playing,
    );
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> stop() async {
    final revision = ++_commandRevision;
    _pendingStops++;
    try {
      await _handler.stop();
    } finally {
      _pendingStops--;
    }
    if (!mounted || revision != _commandRevision) return;
    // Keep the user's volume / mini-player visibility, drop the queue so the
    // UI and the handler stay in sync (the handler clears its queue too).
    _lastRecentSongId = null;
    state = PlayerState(
      volume: state.volume,
      isMiniPlayerVisible: state.isMiniPlayerVisible,
    );
  }

  Future<void> quit() async {
    await _handler.quit();
    state = const PlayerState();
  }

  void dismissMiniPlayer() {
    state = state.copyWith(isMiniPlayerVisible: false);
  }

  void showMiniPlayer() {
    state = state.copyWith(isMiniPlayerVisible: true);
  }

  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> seekRelative(Duration offset) => _handler.seekRelative(offset);
  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);
  Future<void> setVolume(double volume) => _handler.setVolume(volume);
  void setSleepBoundary({bool track = false, bool queue = false}) =>
      _handler.setSleepBoundary(track: track, queue: queue);

  Future<void> next() async {
    _commandRevision++;
    await _handler.skipToNext();
  }

  Future<void> previous() async {
    _commandRevision++;
    if (state.position.inSeconds > 3) {
      await _handler.seek(Duration.zero);
    } else {
      await _handler.skipToPrevious();
    }
  }

  Future<void> skipToIndex(int index) {
    _commandRevision++;
    return _handler.skipToQueueItem(index);
  }

  void toggleSingleTrackMode() {
    _handler.customAction('toggleSingle');
  }

  void toggleRepeatMode() {
    _handler.customAction('toggleRepeat');
  }

  void toggleShuffleMode() {
    _handler.customAction('toggleShuffle');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final audioHandlerProvider = Provider<ToneHarborAudioHandler>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, PlayerState>((ref) {
      final handler = ref.watch(audioHandlerProvider);
      return AudioPlayerNotifier(handler, ref);
    });
