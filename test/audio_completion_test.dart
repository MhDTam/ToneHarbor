import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/services/audio/audio_handler.dart';

class _Engine implements AudioPlayer {
  final events = BehaviorSubject<PlaybackEvent>.seeded(PlaybackEvent());
  final processing =
      BehaviorSubject<ProcessingState>.seeded(ProcessingState.idle);
  final loads = <Uri>[];
  bool staleCompletion = false;
  Completer<void>? opening;
  Completer<void>? stopping;
  @override
  bool playing = false;
  @override
  Duration position = Duration.zero;
  @override
  Duration? get duration => const Duration(seconds: 60);
  @override
  Duration get bufferedPosition => position;
  @override
  double get speed => 1;
  @override
  ProcessingState get processingState => processing.value;
  @override
  Stream<ProcessingState> get processingStateStream => processing.stream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<double> get speedStream => const Stream.empty();
  void emit(ProcessingState value) {
    processing.add(value);
    events.add(PlaybackEvent(processingState: value));
  }

  @override
  Future<Duration?> setAudioSource(AudioSource source,
      {bool preload = true,
      int? initialIndex,
      Duration? initialPosition}) async {
    loads.add((source as UriAudioSource).uri);
    if (staleCompletion) {
      staleCompletion = false;
      emit(ProcessingState.completed);
    }
    if (opening != null) await opening!.future;
    position = Duration.zero;
    emit(ProcessingState.ready);
    return duration;
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> play() async {
    playing = true;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> seek(Duration? value, {int? index}) async {
    position = value ?? Duration.zero;
    emit(ProcessingState.ready);
  }

  @override
  Future<void> stop() async {
    playing = false;
    if (stopping != null) await stopping!.future;
  }

  @override
  Future<void> dispose() async {
    await processing.close();
    await events.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _songs = List.generate(
    3,
    (i) => SongModel(
        id: i + 1,
        title: 'Track ${i + 1}',
        artist: '',
        album: '',
        data: 'C:/Music/track-${i + 1}.mp3',
        duration: 60000,
        dateAdded: i));

Future<void> _flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  for (final (toggles, expectedIndexes) in [
    (0, [1]),
    (1, [0, 1]),
    (2, [0, 0, 0, 1]),
    (3, [0, 0, 0, 0, 0]),
  ]) {
    test('repeat mode $toggles performs the indicated number of replays',
        () async {
      final engine = _Engine();
      final handler = ToneHarborAudioHandler(player: engine);
      addTearDown(handler.onTaskRemoved);
      await handler.setQueueFromSongs(_songs, 0);
      for (var i = 0; i < toggles; i++) {
        await handler.customAction('toggleRepeat');
      }
      await _flush();
      for (final index in expectedIndexes) {
        engine.position = engine.duration!;
        engine.emit(ProcessingState.completed);
        await _flush();
        expect(handler.currentIndex, index);
      }
    });
  }
  test('late stop completion cannot clear a newly selected native queue',
      () async {
    final engine = _Engine();
    final handler = ToneHarborAudioHandler(player: engine);
    addTearDown(handler.onTaskRemoved);
    await handler.setQueueFromSongs(_songs, 0);
    engine.stopping = Completer<void>();
    final pending = handler.stop();
    await _flush();
    await handler.setQueueFromSongs(_songs, 1);
    engine.stopping!.complete();
    await pending;
    await _flush();
    expect(handler.currentIndex, 1);
    expect(handler.queue.value.length, 3);
    expect(engine.loads.last.path, endsWith('track-2.mp3'));
  });
  test('old completion during a manual source change cannot skip the selection',
      () async {
    final engine = _Engine();
    final handler = ToneHarborAudioHandler(player: engine);
    addTearDown(handler.onTaskRemoved);
    await handler.setQueueFromSongs(_songs, 0);
    await _flush();
    engine.staleCompletion = true;
    await handler.skipToQueueItem(1);
    await _flush();
    expect(handler.currentIndex, 1);
    expect(engine.loads.length, 2);
    expect(engine.loads.last.path, endsWith('track-2.mp3'));
    // An old end event arriving after ready is also invalid at position zero.
    engine.emit(ProcessingState.completed);
    await _flush();
    expect(handler.currentIndex, 1);
    // A genuine completion must still advance exactly once.
    engine.position = engine.duration!;
    engine.emit(ProcessingState.completed);
    engine.emit(ProcessingState.completed);
    await _flush();
    expect(handler.currentIndex, 2);
    expect(engine.loads.length, 3);
  });

  test('latest manual choice wins while earlier decoder loads are pending',
      () async {
    final engine = _Engine();
    final handler = ToneHarborAudioHandler(player: engine);
    addTearDown(handler.onTaskRemoved);
    await handler.setQueueFromSongs(_songs, 0);
    engine.opening = Completer<void>();
    final second = handler.skipToQueueItem(1);
    await _flush();
    final third = handler.skipToQueueItem(2);
    await _flush();
    engine.emit(ProcessingState.completed);
    await _flush();
    engine.opening!.complete();
    await Future.wait([second, third]);
    await _flush();
    expect(handler.currentIndex, 2);
    expect(engine.loads.length, 3);
  });
}
