import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/services/audio/audio_player_service.dart';
import 'package:toneharbor/services/audio/audio_player_types.dart';
import 'package:toneharbor/services/audio/sleep_timer_service.dart';

class _FakePlayer extends StateNotifier<PlayerState>
    implements AudioPlayerNotifier {
  int pauses = 0;
  bool trackBoundary = false, queueBoundary = false;
  _FakePlayer(super.state);
  void emit(PlayerState next) => state = next;
  @override
  void setSleepBoundary({bool track = false, bool queue = false}) {
    trackBoundary = track;
    queueBoundary = queue;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SongModel _song(int id) => SongModel(
    id: id,
    title: 'Track $id',
    artist: 'Artist',
    album: '',
    data: 'track$id',
    duration: 10000,
    dateAdded: 0);

void main() {
  test(
      'track timer waits for completion rather than cutting off the last second',
      () async {
    final initial = PlayerState(
        queue: [_song(1), _song(2)], duration: const Duration(seconds: 10));
    final player = _FakePlayer(initial);
    final timer = SleepTimerNotifier(player);
    addTearDown(timer.dispose);
    addTearDown(player.dispose);
    await timer.startTimer(mode: SleepTimerMode.trackEndLock);
    expect(player.trackBoundary, isTrue);
    player.emit(initial.copyWith(position: const Duration(milliseconds: 9500)));
    await Future<void>.delayed(Duration.zero);
    expect(player.pauses, 0);
    expect(timer.state.isActive, isTrue);
    player.emit(initial.copyWith(
        position: const Duration(seconds: 10),
        processingState: AppProcessingState.completed));
    await Future<void>.delayed(Duration.zero);
    expect(player.pauses, 1);
    expect(timer.state.isActive, isFalse);
  });
  test('playlist timer ignores intermediate tracks and stops on the last',
      () async {
    final initial = PlayerState(queue: [_song(1), _song(2)], currentIndex: 0);
    final player = _FakePlayer(initial);
    final timer = SleepTimerNotifier(player);
    addTearDown(timer.dispose);
    addTearDown(player.dispose);
    await timer.startTimer(mode: SleepTimerMode.playlistEndLock);
    player
        .emit(initial.copyWith(processingState: AppProcessingState.completed));
    await Future<void>.delayed(Duration.zero);
    expect(player.pauses, 0);
    expect(timer.state.isActive, isTrue);
    player.emit(initial.copyWith(
        currentIndex: 1, processingState: AppProcessingState.completed));
    await Future<void>.delayed(Duration.zero);
    expect(player.pauses, 1);
    expect(timer.state.isActive, isFalse);
  });
}
