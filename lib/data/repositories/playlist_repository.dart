import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/isar_service.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'song_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Playlist Repository with Riverpod
// ─────────────────────────────────────────────────────────────────────────────
final playlistRepositoryProvider = StateNotifierProvider<
    PlaylistRepositoryNotifier, AsyncValue<List<PlaylistModel>>>((ref) {
  return PlaylistRepositoryNotifier(ref);
});

class PlaylistRepositoryNotifier
    extends StateNotifier<AsyncValue<List<PlaylistModel>>> {
  final Ref ref;
  PlaylistRepositoryNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    if (!state.hasValue) state = const AsyncValue.loading();
    try {
      final playlists = await IsarService.getAllPlaylists();

      final systemPlaylists =
          playlists.where((p) => p.name == 'system_recently_played').toList();
      final userPlaylists =
          playlists.where((p) => p.name != 'system_recently_played').toList();

      final sorted = [...systemPlaylists, ...userPlaylists];

      state = AsyncValue.data(sorted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPlaylist(String name) async {
    final p = PlaylistModel.create(name: name);
    await IsarService.savePlaylist(p);
    await _load();
  }

  Future<void> renamePlaylist(int id, String newName) async {
    await IsarService.renamePlaylist(id, newName);
    await _load();
  }

  Future<void> deletePlaylist(int id) async {
    await IsarService.deletePlaylist(id);
    await _load();
  }

  Future<void> addSong(int playlistId, int songId) async {
    await IsarService.addSongToPlaylist(playlistId, songId);
    ref.invalidate(playlistSongsProvider(playlistId));
    await _load();
  }

  Future<void> addSongs(int playlistId, Iterable<int> ids) async {
    await IsarService.addSongsToPlaylist(playlistId, ids);
    ref.invalidate(playlistSongsProvider(playlistId));
    await _load();
  }

  Future<void> removeSong(int playlistId, int songId) async {
    await IsarService.removeSongFromPlaylist(playlistId, songId);
    ref.invalidate(playlistSongsProvider(playlistId));
    await _load();
  }

  Future<void> refresh() => _load();

  Future<void> addToRecentlyPlayed(int songId) async {
    final playlistId = await IsarService.addToRecentlyPlayed(songId);
    if (playlistId == null) return;
    ref.invalidate(playlistSongsProvider(playlistId));
    await _load(); // Refresh the list
  }
}

// Resolve SongModels for a playlist
final playlistSongsProvider = FutureProvider.autoDispose
    .family<List<SongModel>, int>((ref, playlistId) async {
  final pending = ref.keepAlive();
  try {
    final allSongsAsync = ref.watch(songLibraryProvider);
    final playlist = await IsarService.getPlaylist(playlistId);
    if (playlist == null) return [];
    final allSongs = allSongsAsync.valueOrNull ?? [];
    final songMap = {for (final s in allSongs) s.id: s};
    return playlist.songIds
        .map((id) => songMap[id])
        .whereType<SongModel>()
        .toList();
  } finally {
    pending.close();
  }
});
