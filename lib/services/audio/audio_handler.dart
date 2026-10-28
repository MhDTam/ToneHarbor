import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/models/song_model.dart';
import '../../data/database/isar_service.dart';
import 'audio_player_service.dart';

import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'audio_player_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Audio Handler – integrates just_audio with Android Media Controls
//
// CRITICAL: Uses .map().pipe() pattern from official audio_service example
// to ensure the Android MediaSession and notification stay in sync.
// ─────────────────────────────────────────────────────────────────────────────
class ToneHarborAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  final _currentIndexSubject = BehaviorSubject<int?>.seeded(null);
  final _playbackStateSubject = BehaviorSubject<PlaybackStateInfo>.seeded(
    const PlaybackStateInfo(),
  );
  final _mediaItemSubject = BehaviorSubject<MediaItemInfo?>.seeded(null);
  final _queueSubject = BehaviorSubject<List<MediaItemInfo>>.seeded([]);
  final _customStateSubject = BehaviorSubject<Map<String, dynamic>>.seeded({});
  final _volumeSubject = BehaviorSubject<double>.seeded(1.0);

  bool _isSingleTrack = false;
  RepeatState _repeatMode = RepeatState.off;
  bool _isShuffle = false;
  int _currentRepeatCount = 0;
  bool _sleepAfterTrack = false;
  bool _sleepAfterQueue = false;

  void setSleepBoundary({bool track = false, bool queue = false}) {
    _sleepAfterTrack = track;
    _sleepAfterQueue = queue;
  }

  /// Stop control that uses a smaller square than the default media stop icon.
  static const MediaControl _stopControl = MediaControl(
    androidIcon: 'drawable/ic_stop_small',
    label: 'Stop',
    action: MediaAction.stop,
  );

  /// Incremented on every [_loadTrack] so an in-flight load can detect that a
  /// newer one superseded it (rapid next/previous taps, queue replacement).
  int _loadEpoch = 0;
  bool _loadingTrack = false;
  bool _completionArmed = false;

  int get _currentIndex => _currentIndexSubject.value ?? 0;
  set _currentIndex(int value) => _currentIndexSubject.add(value);

  /// Cover art used by the system media session (lock screen / notification)
  /// when the song has no album art of its own.
  Uri? _fallbackArtUri;

  ToneHarborAudioHandler({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    unawaited(_loadFallbackArt());
    // ═══════════════════════════════════════════════════════════════════════
    // CRITICAL: Pipe just_audio events → audio_service playbackState
    // This is the EXACT pattern from the official audio_service example.
    // Using .listen() + .add() can cause timing issues where the Android
    // MediaSession never receives the state update.
    // ═══════════════════════════════════════════════════════════════════════
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Also listen to update our internal app state
    _player.playbackEventStream.listen(_updateInternalState);

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.ready && !_loadingTrack) {
        _completionArmed = true;
      }
      if (state == ProcessingState.completed &&
          !_loadingTrack &&
          _completionArmed) {
        // Source replacement can deliver the previous file's completed event.
        // It must never advance the index of the user's new selection.
        final duration = _player.duration;
        if (duration != null &&
            duration > Duration.zero &&
            _player.position < duration - const Duration(milliseconds: 250)) {
          return;
        }
        _completionArmed = false;
        final epoch = _loadEpoch;
        // Fire-and-forget, but never let it bubble up as an unhandled error.
        unawaited(
          _handlePlaybackCompleted(epoch).catchError((Object e) {
            debugPrint('Playback completed handler failed: $e');
          }),
        );
      }
    });
  }

  /// Transform just_audio PlaybackEvent → audio_service PlaybackState
  /// This is what feeds the Android notification and Control Center.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        // Stop first (with a smaller icon), then the usual transport controls.
        _stopControl,
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.stop,
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      // Collapsed view shows previous / play-pause / next; stop appears when
      // the notification is expanded.
      androidCompactActionIndices: const [1, 2, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    );
  }

  /// Update our internal app state (for the Flutter UI, not for Android)
  void _updateInternalState(PlaybackEvent event) {
    AppProcessingState appState;
    switch (_player.processingState) {
      case ProcessingState.idle:
        appState = AppProcessingState.idle;
      case ProcessingState.loading:
        appState = AppProcessingState.loading;
      case ProcessingState.buffering:
        appState = AppProcessingState.buffering;
      case ProcessingState.ready:
        appState = AppProcessingState.ready;
      case ProcessingState.completed:
        appState = AppProcessingState.completed;
    }

    _playbackStateSubject.add(
      PlaybackStateInfo(
        playing: _player.playing,
        processingState: appState,
        position: _player.position,
        speed: _player.speed,
      ),
    );
  }

  // Expose streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get speedStream => _player.speedStream;
  Stream<int?> get currentIndexStream => _currentIndexSubject.stream;
  Stream<PlaybackStateInfo> get playbackStateStream =>
      _playbackStateSubject.stream;
  Stream<Map<String, dynamic>> get customStateStream =>
      _customStateSubject.stream;
  Stream<double> get volumeStream => _volumeSubject.stream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;
  int? get currentIndex => _currentIndex;
  bool get hasNext =>
      _isShuffle || _currentIndex < _queueSubject.value.length - 1;
  bool get hasPrevious => _isShuffle || _currentIndex > 0;

  void _broadcastCustomState() {
    _customStateSubject.add({
      'single': _isSingleTrack,
      'repeat': _repeatMode.index,
      'shuffle': _isShuffle,
    });
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case 'setTheme':
        // The system notification/Control-Center colours are provided by the
        // platform; nothing to change here. Kept as a no-op so the Flutter side
        // can keep calling it without breaking.
        break;
      case 'toggleSingle':
        _isSingleTrack = !_isSingleTrack;
        _broadcastCustomState();
        break;
      case 'toggleRepeat':
        final next = (_repeatMode.index + 1) % RepeatState.values.length;
        _repeatMode = RepeatState.values[next];
        _currentRepeatCount = 0;
        _broadcastCustomState();
        break;
      case 'toggleShuffle':
        _isShuffle = !_isShuffle;
        _broadcastCustomState();
        break;
    }
  }

  // ── Queue Management ───────────────────────────────────────────────────────
  /// Replaces the playing queue.
  /// Set [reload] to false when the currently loaded file is already the track
  /// at [index] – only the queue/index bookkeeping is updated then.
  Future<void> setQueueFromSongs(
    List<SongModel> songs,
    int index, {
    bool reload = true,
    bool startPlaying = true,
  }) async {
    final items = songs.map(_songToMediaItem).toList();
    _queueSubject.add(items);

    // CRITICAL: Also update audio_service's queue so the system knows
    // there is an active playlist. Without this, some Android skins
    // (ColorOS, MIUI) refuse to show the media controls in Quick Settings.
    final serviceQueue = items
        .map(
          (item) => MediaItem(
            id: 'song_${item.id}',
            title: item.title,
            album: item.album ?? 'ToneHarbor',
            artist: item.artist ?? 'Unknown Artist',
            duration: item.duration,
            artUri: item.artUri,
          ),
        )
        .toList();
    queue.add(serviceQueue);

    _currentIndex = index;
    _currentRepeatCount = 0;

    if (reload) {
      if (!await _loadTrack(_currentIndex)) return;
    } else {
      _mediaItemSubject.add(items[_currentIndex]);
      mediaItem.add(
        MediaItem(
          id: 'song_${items[_currentIndex].id}',
          title: items[_currentIndex].title,
          album: items[_currentIndex].album ?? 'ToneHarbor',
          artist: items[_currentIndex].artist ?? 'Unknown Artist',
          duration: items[_currentIndex].duration,
          artUri: await _resolveArtUri(items[_currentIndex]),
        ),
      );
    }
    if (startPlaying) _startPlaying();
  }

  void _startPlaying() {
    unawaited(
      play().catchError((Object e, StackTrace st) {
        debugPrint('Playback failed: $e');
      }),
    );
  }

  Future<bool> _loadTrack(int index) async {
    if (index < 0 || index >= _queueSubject.value.length) return false;
    final item = _queueSubject.value[index];
    final epoch = ++_loadEpoch;
    _loadingTrack = true;
    _completionArmed = false;
    _mediaItemSubject.add(item);

    // Update audio_service's current mediaItem for the notification. The art
    // is resolved here so the lock-screen card shows the real cover when one
    // exists and the app icon otherwise.
    final artUri = await _resolveArtUri(item);
    if (epoch != _loadEpoch) return false;
    mediaItem.add(
      MediaItem(
        id: 'song_${item.id}',
        title: item.title,
        album: item.album ?? 'ToneHarbor',
        artist: item.artist ?? 'Unknown Artist',
        duration: item.duration,
        artUri: artUri,
      ),
    );

    // setAudioSource replaces the source itself. stop() deactivates just_audio's
    // native player, forcing Windows to destroy/recreate it on every click.
    try {
      await _player.setAudioSource(
        AudioSource.file(item.filePath),
        initialPosition: Duration.zero,
      );
      // The Windows plugin acknowledges `load` before MediaPlayer has opened
      // the source. Starting it during that interval can lose the first play.
      if (isDesktop && _player.processingState != ProcessingState.ready) {
        await _player.processingStateStream
            .firstWhere((state) => state == ProcessingState.ready)
            .timeout(const Duration(seconds: 15));
      }
    } on PlayerInterruptedException {
      // Another load won the race - expected, not an error.
      return false;
    } on PlayerException catch (e) {
      // Missing / unreadable / unsupported file: keep the queue usable instead
      // of crashing the playback isolate.
      debugPrint('Failed to load "${item.filePath}": ${e.message}');
      return false;
    } on TimeoutException {
      debugPrint('Timed out opening "${item.filePath}"');
      return false;
    } finally {
      if (epoch == _loadEpoch) {
        _loadingTrack = false;
        _completionArmed = _player.processingState == ProcessingState.ready;
      }
    }

    if (epoch != _loadEpoch) return false;
    await _player.setVolume(_volumeSubject.value);
    return true;
  }

  MediaItemInfo _songToMediaItem(SongModel song) {
    return MediaItemInfo(
      id: song.id,
      filePath: song.data,
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: Duration(milliseconds: song.duration),
      albumId: song.albumId,
      artUri: _artUriFor(song),
    );
  }

  /// Default artwork for the system media session: the app icon, so the
  /// lock-screen player and Dynamic Island always show the app icon. Real
  /// album art is used instead only when it actually exists (see
  /// [_resolveArtUri]).
  Uri? _artUriFor(SongModel song) => isMobile ? _fallbackArtUri : null;

  /// Returns the album art URI when the song really has artwork, otherwise the
  /// app icon. MediaStore's `albumart` URI returns nothing for songs without a
  /// cover, which previously left the lock-screen card with a blank generic
  /// icon.
  Future<Uri?> _resolveArtUri(MediaItemInfo item) async {
    if (!isMobile) return null;
    if (item.albumId > 0) {
      try {
        final bytes = await OnAudioQuery().queryArtwork(
          item.id,
          ArtworkType.AUDIO,
          size: 96,
        );
        if (bytes != null && bytes.isNotEmpty) {
          return Uri.parse(
            'content://media/external/audio/albumart/${item.albumId}',
          );
        }
      } catch (e) {
        debugPrint('Album art check failed: $e');
      }
    }
    return await _ensureFallbackArtUri();
  }

  Future<Uri?> _ensureFallbackArtUri() async {
    if (!isMobile) return null;
    if (_fallbackArtUri != null) {
      try {
        final file = File(_fallbackArtUri!.toFilePath());
        if (file.existsSync() && file.lengthSync() > 0) {
          return _fallbackArtUri;
        }
      } catch (_) {}
    }
    await _loadFallbackArt();
    return _fallbackArtUri;
  }

  Future<void> _loadFallbackArt() async {
    if (!isMobile) return;
    try {
      final path = await const MethodChannel(
        'com.musiconvert.mp3noads/lock',
      ).invokeMethod<String>('appIconPath');
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync() && file.lengthSync() > 0) {
          _fallbackArtUri = Uri.file(path);
        }
      }
    } catch (e) {
      debugPrint('Could not prepare fallback artwork: $e');
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await _player.stop();
    await _player.dispose();
    await super.onTaskRemoved();
  }

  // ── Playback Controls ───────────────────────────────────────────────────────
  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    if (!_player.playing) {
      await _player.play();
    }
  }

  @override
  Future<void> pause() => _player.pause();

  Future<void> setVolume(double volume) async {
    _volumeSubject.add(volume);
    await _player.setVolume(volume);
  }

  @override
  Future<void> stop() async {
    final epoch = ++_loadEpoch; // invalidate any in-flight load
    _loadingTrack = false;
    _completionArmed = false;
    await _player.stop();
    // A newer source may already be opening while native stop acknowledges.
    if (epoch != _loadEpoch) return;
    // Clear everything so the UI, the system notification and this handler
    // cannot drift apart (previously the queue/index stayed alive here).
    _queueSubject.add([]);
    queue.add(<MediaItem>[]);
    _mediaItemSubject.add(null);
    _currentIndexSubject.add(null);
    _currentRepeatCount = 0;
    _playbackStateSubject.add(
      const PlaybackStateInfo(
        playing: false,
        processingState: AppProcessingState.idle,
      ),
    );
    await super.stop();
  }

  /// Fully tears the player down and closes the app on every platform.
  /// (On desktop the old implementation left a disposed player behind, so any
  /// later interaction threw "Player is disposed".)
  Future<void> quit() async {
    _loadEpoch++;
    await _player.stop();
    await _player.dispose();
    // Release the database handle before the process goes away.
    await IsarService.close();
    _playbackStateSubject.add(
      const PlaybackStateInfo(
        playing: false,
        processingState: AppProcessingState.idle,
      ),
    );
    await super.stop();
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
      Future.delayed(const Duration(milliseconds: 300), () => exit(0));
    } else {
      exit(0);
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> seekRelative(Duration offset) async {
    final newPosition = _player.position + offset;
    final dur = _player.duration ?? Duration.zero;
    if (newPosition < Duration.zero) {
      await _player.seek(Duration.zero);
    } else if (newPosition > dur) {
      await skipToNext();
    } else {
      await _player.seek(newPosition);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> _handlePlaybackCompleted(int epoch) async {
    if (epoch != _loadEpoch || _loadingTrack) return;
    if (_sleepAfterTrack ||
        (_sleepAfterQueue && _currentIndex == _queueSubject.value.length - 1)) {
      _sleepAfterTrack = false;
      _sleepAfterQueue = false;
      await _player.pause();
      return;
    }
    if (_isSingleTrack) {
      _currentRepeatCount = 0;
      await _player.pause();
      if (epoch != _loadEpoch) return;
      await _player.seek(Duration.zero);
      return;
    }

    if (_repeatMode == RepeatState.one && _currentRepeatCount < 1) {
      _currentRepeatCount++;
      await _player.seek(Duration.zero);
      if (epoch != _loadEpoch) return;
      await _player.play();
      return;
    } else if (_repeatMode == RepeatState.three && _currentRepeatCount < 3) {
      _currentRepeatCount++;
      await _player.seek(Duration.zero);
      if (epoch != _loadEpoch) return;
      await _player.play();
      return;
    } else if (_repeatMode == RepeatState.infinite) {
      await _player.seek(Duration.zero);
      if (epoch != _loadEpoch) return;
      await _player.play();
      return;
    }

    _currentRepeatCount = 0;
    await skipToNext();
  }

  /// A random queue index that is different from the current one when the
  /// queue holds more than a single track (avoids "shuffle" replaying the same
  /// song back-to-back).
  int _randomOtherIndex() {
    final len = _queueSubject.value.length;
    if (len <= 1) return 0;
    int index;
    do {
      index = Random().nextInt(len);
    } while (index == _currentIndex);
    return index;
  }

  @override
  Future<void> skipToNext() async {
    if (_queueSubject.value.isEmpty) return;

    _currentRepeatCount = 0;
    int nextIndex = _currentIndex + 1;

    if (_isShuffle) {
      nextIndex = _randomOtherIndex();
    } else if (nextIndex >= _queueSubject.value.length) {
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }

    _currentIndex = nextIndex;
    if (!await _loadTrack(_currentIndex)) return;
    _startPlaying();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queueSubject.value.isEmpty) return;

    _currentRepeatCount = 0;
    int prevIndex = _currentIndex - 1;
    if (_isShuffle) {
      prevIndex = _randomOtherIndex();
    } else if (prevIndex < 0) {
      prevIndex = _queueSubject.value.length - 1;
    }

    _currentIndex = prevIndex;
    if (!await _loadTrack(_currentIndex)) return;
    _startPlaying();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queueSubject.value.length) {
      _currentRepeatCount = 0;
      _currentIndex = index;
      if (!await _loadTrack(_currentIndex)) return;
      _startPlaying();
    }
  }
}
