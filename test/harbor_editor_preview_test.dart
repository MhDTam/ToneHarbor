import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toneharbor/features/desktop/harbor_editor_preview.dart';

class _Engine implements AudioPlayer {
  final positions = StreamController<Duration>.broadcast(sync: true);
  final states = BehaviorSubject<PlayerState>.seeded(
      PlayerState(false, ProcessingState.ready));
  Completer<void>? opening;
  int loads = 0, plays = 0, pauses = 0;
  bool disposed = false;
  @override
  ProcessingState get processingState => states.value.processingState;
  @override
  Stream<ProcessingState> get processingStateStream =>
      states.stream.map((s) => s.processingState);
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Future<Duration?> setFilePath(String path,
      {Duration? initialPosition, bool preload = true, dynamic tag}) async {
    loads++;
    if (opening != null) await opening!.future;
    if (!disposed) states.add(PlayerState(false, ProcessingState.ready));
    return const Duration(seconds: 30);
  }

  @override
  Future<void> play() async {
    plays++;
    states.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    pauses++;
    if (!disposed) states.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (!disposed) positions.add(position ?? Duration.zero);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await positions.close();
    await states.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('preview engine is lazy and resume reuses its loaded source', () async {
    final engine = _Engine();
    var creations = 0;
    final preview = HarborEditorPreview(createPlayer: () {
      creations++;
      return engine;
    });
    expect(creations, 0);
    await preview.play('preview.wav');
    await Future<void>.delayed(Duration.zero);
    expect(creations, 1);
    expect(preview.playing.value, isTrue);
    engine.positions.add(const Duration(seconds: 4));
    expect(preview.position.value.inSeconds, 4);
    await preview.pause();
    await preview.play('preview.wav');
    expect(engine.loads, 1);
    expect(engine.plays, 2);
    await preview.close();
    await preview.close();
    expect(engine.disposed, isTrue);
  });
  test('cancelled opening never starts late playback', () async {
    final engine = _Engine()..opening = Completer<void>();
    final preview = HarborEditorPreview(createPlayer: () => engine);
    final loading = preview.play('pending.wav');
    await preview.pause();
    engine.opening!.complete();
    await loading;
    expect(engine.plays, 0);
    expect(preview.playing.value, isFalse);
    await preview.close();
  });
  test('disposing during a source load never touches disposed listeners',
      () async {
    final engine = _Engine()..opening = Completer<void>();
    final preview = HarborEditorPreview(createPlayer: () => engine);
    final loading = preview.play('pending.wav');
    await preview.close();
    engine.opening!.complete();
    await loading;
    expect(engine.plays, 0);
    expect(engine.disposed, isTrue);
  });
}
