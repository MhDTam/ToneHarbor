import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/data/models/playlist_model.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/data/repositories/playlist_repository.dart';
import 'package:toneharbor/services/audio/audio_handler.dart';
import 'package:toneharbor/services/audio/audio_player_service.dart';
import 'package:toneharbor/services/audio/audio_player_types.dart';

class _Handler implements ToneHarborAudioHandler {
  final index = StreamController<int?>.broadcast(sync: true);
  int queueLoads = 0, skips = 0;
  int? lastIndex;
  List<SongModel> lastQueue = [];
  bool? lastReload, lastStartPlaying;
  Completer<void>? decoder;
  Completer<void>? stopping;
  @override
  Future<void> stop() async {
    if (stopping != null) await stopping!.future;
  }

  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<double> get speedStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => index.stream;
  @override
  Stream<PlaybackStateInfo> get playbackStateStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get customStateStream => const Stream.empty();
  @override
  Stream<double> get volumeStream => const Stream.empty();
  @override
  Future<void> setQueueFromSongs(List<SongModel> songs, int i,
      {bool reload = true, bool startPlaying = true}) async {
    queueLoads++;
    lastIndex = i;
    lastQueue = List.of(songs);
    lastReload = reload;
    lastStartPlaying = startPlaying;
  }

  @override
  Future<void> skipToQueueItem(int i) async {
    skips++;
    lastIndex = i;
    if (decoder != null) await decoder!.future;
    index.add(i);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Playlists extends StateNotifier<AsyncValue<List<PlaylistModel>>>
    implements PlaylistRepositoryNotifier {
  _Playlists() : super(const AsyncData([]));
  @override
  Future<void> addToRecentlyPlayed(int songId) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SongModel _song(int id) => SongModel(
    id: id,
    title: '$id',
    artist: '',
    album: '',
    data: '$id',
    duration: 0,
    dateAdded: 0);

void main() {
  test('an old stop cannot erase a new selection, including the same source',
      () async {
    final handler = _Handler();
    final container = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      playlistRepositoryProvider.overrideWith((_) => _Playlists())
    ]);
    final player = container.read(audioPlayerProvider.notifier);
    final songs = [_song(1), _song(2)];
    await player.playSong(songs.first, queue: songs);
    handler.stopping = Completer<void>();
    final pending = player.stop();
    await player.playSong(songs.first, queue: songs);
    expect(handler.lastReload, isTrue);
    expect(handler.queueLoads, 2);
    handler.stopping!.complete();
    await pending;
    expect(container.read(audioPlayerProvider).currentSong?.id, 1);
    expect(container.read(audioPlayerProvider).queue.length, 2);
    container.dispose();
    await handler.index.close();
  });
  test('invalid native indexes cannot crash or replace the selected song',
      () async {
    expect(
        PlayerState(queue: [_song(1)], currentIndex: -1).currentSong, isNull);
    final handler = _Handler();
    final container = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      playlistRepositoryProvider.overrideWith((_) => _Playlists())
    ]);
    final player = container.read(audioPlayerProvider.notifier);
    await player.playSong(_song(1), queue: [_song(1), _song(2)]);
    handler.index.add(-1);
    handler.index.add(999);
    expect(container.read(audioPlayerProvider).currentSong?.id, 1);
    handler.index.add(1);
    expect(container.read(audioPlayerProvider).currentSong?.id, 2);
    container.dispose();
    await handler.index.close();
  });
  test('song identity wins over a missing or mismatched row index', () async {
    final handler = _Handler();
    final container = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      playlistRepositoryProvider.overrideWith((_) => _Playlists())
    ]);
    addTearDown(() async {
      container.dispose();
      await handler.index.close();
    });
    final player = container.read(audioPlayerProvider.notifier);
    final songs = [_song(3), _song(1), _song(2)];
    await player.playSong(songs[1], queue: songs);
    expect(handler.lastIndex, 1);
    expect(container.read(audioPlayerProvider).currentSong?.id, 1);
    await player.playSong(songs[0], queue: songs, index: 1);
    expect(handler.lastIndex, 0);
    expect(container.read(audioPlayerProvider).currentSong?.id, 3);
  });
  test(
      'enqueue preserves the loaded track and paused state, with next insertion',
      () async {
    final handler = _Handler();
    final container = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      playlistRepositoryProvider.overrideWith((_) => _Playlists())
    ]);
    addTearDown(() async {
      container.dispose();
      await handler.index.close();
    });
    final player = container.read(audioPlayerProvider.notifier);
    final songs = [_song(1), _song(2)];
    await player.playSong(songs.first, queue: songs);
    await player.enqueueSongs([_song(3), _song(4)], next: true);
    expect(handler.lastQueue.map((s) => s.id), [1, 3, 4, 2]);
    expect(handler.lastReload, isFalse);
    expect(handler.lastStartPlaying, isFalse);
    expect(container.read(audioPlayerProvider).currentSong?.id, 1);
    await player.enqueueSongs([_song(5)]);
    expect(handler.lastQueue.map((s) => s.id), [1, 3, 4, 2, 5]);
  });
  test('selection responds before a slow decoder completes', () async {
    final handler = _Handler();
    final container = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      playlistRepositoryProvider.overrideWith((_) => _Playlists())
    ]);
    addTearDown(() async {
      container.dispose();
      await handler.index.close();
    });
    final player = container.read(audioPlayerProvider.notifier);
    final songs = [_song(1), _song(2)];
    await player.playSong(songs.first, queue: songs);
    handler.decoder = Completer<void>();
    final pending = player.playSong(songs.last, queue: songs, index: 1);
    expect(container.read(audioPlayerProvider).currentSong?.id, 2);
    expect(container.read(audioPlayerProvider).position, Duration.zero);
    handler.decoder!.complete();
    await pending;
  });
  test('switching tracks within the same queue does not rebuild it', () async {
    final handler = _Handler();
    final container = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      playlistRepositoryProvider.overrideWith((_) => _Playlists())
    ]);
    addTearDown(() async {
      container.dispose();
      await handler.index.close();
    });
    final player = container.read(audioPlayerProvider.notifier);
    final songs = [_song(1), _song(2)];
    await player.playSong(songs.first, queue: songs);
    await player.playSong(songs.last, queue: List.of(songs), index: 1);
    expect(handler.queueLoads, 1);
    expect(handler.skips, 1);
    expect(container.read(audioPlayerProvider).currentSong?.id, 2);
  });
}
