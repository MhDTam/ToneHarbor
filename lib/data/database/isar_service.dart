import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/playlist_model.dart';
import '../models/conversion_history_model.dart';
import '../models/action_history_model.dart';
import '../models/cached_song.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Isar Database Service
// ─────────────────────────────────────────────────────────────────────────────
class IsarService {
  static Isar? _instance;

  /// Guards against two concurrent first accesses opening the database twice.
  static Future<Isar>? _opening;

  static List<CollectionSchema<dynamic>> get _schemas => [
        PlaylistModelSchema,
        ConversionHistoryModelSchema,
        ActionHistoryModelSchema,
        CachedSongSchema,
      ];

  static Future<Isar> get instance async {
    final existing = _instance;
    if (existing != null && existing.isOpen) return existing;
    return _opening ??= (_open()..whenComplete(() => _opening = null));
  }

  static Future<Isar> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    try {
      final isar = await Isar.open(_schemas, directory: dir.path);
      _instance = isar;
      return isar;
    } catch (e, st) {
      // The local database could not be opened (usually an incompatible or
      // damaged schema). Move the files aside instead of deleting them: losing
      // every playlist / favourite because of a transient error is not
      // acceptable, and the backup can still be inspected or restored.
      debugPrint('Isar open failed, quarantining database: $e\n$st');
      await _quarantineDatabase(dir);
      final isar = await Isar.open(_schemas, directory: dir.path);
      _instance = isar;
      return isar;
    }
  }

  /// Renames `default.isar` / `default.isar.lock` so a failed open never
  /// destroys user data.
  static Future<void> _quarantineDatabase(Directory dir) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (final name in const ['default.isar', 'default.isar.lock']) {
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      try {
        if (!await file.exists()) continue;
        await file.rename('${file.path}.bak_$stamp');
        debugPrint('Backed up $name to ${file.path}.bak_$stamp');
      } catch (e) {
        debugPrint('Could not back up $name: $e');
        // A locked/corrupt file that cannot even be renamed would make the app
        // unusable - only then fall back to removing it.
        if (!name.endsWith('.lock')) {
          try {
            await file.delete();
          } catch (deleteError) {
            debugPrint('Could not delete $name: $deleteError');
          }
        }
      }
    }
  }

  /// Releases the database handle (called on app shutdown).
  static Future<void> close() async {
    try {
      await _instance?.close();
    } catch (e) {
      debugPrint('Failed to close Isar: $e');
    }
    _instance = null;
  }

  // ── Playlists ──────────────────────────────────────────────────────────────
  static Future<List<PlaylistModel>> getAllPlaylists() async {
    final db = await instance;
    return db.playlistModels.where().sortByCreatedAt().findAll();
  }

  static Future<PlaylistModel?> getPlaylist(int id) async {
    final db = await instance;
    return db.playlistModels.get(id);
  }

  static Future<int> savePlaylist(PlaylistModel playlist) async {
    final db = await instance;
    return await db.writeTxn(() async {
      return await db.playlistModels.put(playlist);
    });
  }

  static Future<void> deletePlaylist(int id) async {
    final db = await instance;
    await db.writeTxn(() async {
      await db.playlistModels.delete(id);
    });
  }

  static Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final db = await instance;
    // Read-modify-write inside ONE transaction: doing the read outside meant
    // concurrent updates (e.g. bulk "add to playlist") could drop songs.
    await db.writeTxn(() async {
      final playlist = await db.playlistModels.get(playlistId);
      if (playlist == null || playlist.songIds.contains(songId)) return;
      playlist.songIds = List<int>.from(playlist.songIds)..add(songId);
      await db.playlistModels.put(playlist);
    });
  }

  static Future<void> addSongsToPlaylist(
      int playlistId, Iterable<int> songIds) async {
    final db = await instance;
    await db.writeTxn(() async {
      final playlist = await db.playlistModels.get(playlistId);
      if (playlist == null) return;
      final ids = List<int>.from(playlist.songIds);
      final existing = ids.toSet();
      for (final id in songIds) {
        if (existing.add(id)) ids.add(id);
      }
      playlist.songIds = ids;
      await db.playlistModels.put(playlist);
    });
  }

  static Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await instance;
    await db.writeTxn(() async {
      final playlist = await db.playlistModels.get(playlistId);
      if (playlist == null) return;
      playlist.songIds = List<int>.from(playlist.songIds)..remove(songId);
      await db.playlistModels.put(playlist);
    });
  }

  static Future<void> renamePlaylist(int id, String newName) async {
    final db = await instance;
    await db.writeTxn(() async {
      final playlist = await db.playlistModels.get(id);
      if (playlist == null) return;
      playlist.name = newName;
      await db.playlistModels.put(playlist);
    });
  }

  static const String recentlyPlayedPlaylistName = 'system_recently_played';

  /// Puts [songId] at the top of the "recently played" playlist (creating it if
  /// needed) and returns its id. The whole update happens in one transaction.
  static Future<int?> addToRecentlyPlayed(int songId,
      {int maxEntries = 10}) async {
    final db = await instance;
    return db.writeTxn(() async {
      var playlist = await db.playlistModels
          .filter()
          .nameEqualTo(recentlyPlayedPlaylistName)
          .findFirst();
      playlist ??= PlaylistModel.create(name: recentlyPlayedPlaylistName);

      final ids = List<int>.from(playlist.songIds)
        ..remove(songId)
        ..insert(0, songId);
      if (ids.length > maxEntries) {
        ids.removeRange(maxEntries, ids.length);
      }

      playlist.songIds = ids;
      return db.playlistModels.put(playlist);
    });
  }

  // ── Conversion History ─────────────────────────────────────────────────────
  static Future<List<ConversionHistoryModel>> getConversionHistory() async {
    final db = await instance;
    return db.conversionHistoryModels
        .where()
        .sortByTimestampDesc()
        .limit(50)
        .findAll();
  }

  static Future<int> saveConversion(ConversionHistoryModel model) async {
    final db = await instance;
    return await db.writeTxn(() async {
      return await db.conversionHistoryModels.put(model);
    });
  }

  static Future<void> deleteConversion(int id) async {
    final db = await instance;
    await db.writeTxn(() async {
      await db.conversionHistoryModels.delete(id);
    });
  }

  // ── Action History (New) ───────────────────────────────────────────────────
  static Future<List<ActionHistoryModel>> getActionHistory(
      {String? type}) async {
    final db = await instance;
    if (type != null) {
      return db.actionHistoryModels
          .filter()
          .typeEqualTo(type)
          .sortByTimestampDesc()
          .limit(50)
          .findAll();
    }
    return db.actionHistoryModels
        .where()
        .sortByTimestampDesc()
        .limit(50)
        .findAll();
  }

  static Future<int> saveAction(ActionHistoryModel model) async {
    final db = await instance;
    return await db.writeTxn(() async {
      return await db.actionHistoryModels.put(model);
    });
  }

  static Future<void> clearActionHistory({String? type}) async {
    final db = await instance;
    await db.writeTxn(() async {
      if (type != null) {
        await db.actionHistoryModels.filter().typeEqualTo(type).deleteAll();
      } else {
        await db.actionHistoryModels.clear();
      }
    });
  }

  static Future<void> deleteAction(int id) async {
    final db = await instance;
    await db.writeTxn(() async {
      await db.actionHistoryModels.delete(id);
    });
  }
}
