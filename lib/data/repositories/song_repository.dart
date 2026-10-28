import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/audio_formats.dart';
import '../models/song_model.dart';
import 'custom_library_repository.dart';
import '../../services/audio/metadata_scan.dart';
import 'package:isar_community/isar.dart';
import '../database/isar_service.dart';
import '../models/cached_song.dart';
import 'package:on_audio_query/on_audio_query.dart' as aq;
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Song Library Provider (Cross-Platform)
// ─────────────────────────────────────────────────────────────────────────────
final songLibraryProvider = FutureProvider<List<SongModel>>((ref) async {
  ref.keepAlive();
  final customLib = ref.watch(customLibraryProvider);
  if (isDesktop) {
    final scan = MetadataScan();
    ref.onDispose(scan.cancel);
    await ref.read(customLibraryProvider.notifier).ready;
    if (scan.cancelled) return [];
    return _scanDesktopMusicLibrary(customLib, scan);
  } else {
    final songs = await _scanMobileLibrary();
    if (customLib.excludedFiles.isEmpty && customLib.customTitles.isEmpty) {
      return songs;
    }
    final excluded = customLib.excludedFiles.map(normalizePath).toSet();
    return songs
        .where((s) => !excluded.contains(normalizePath(s.data)))
        .map((s) {
      final customTitle = customLib.customTitles[normalizePath(s.data)];
      if (customTitle != null && customTitle.isNotEmpty) {
        return SongModel(
          id: s.id,
          title: customTitle,
          artist: s.artist,
          album: s.album,
          data: s.data,
          duration: s.duration,
          dateAdded: s.dateAdded,
          albumId: s.albumId,
          artworkPath: s.artworkPath,
          isFavorite: s.isFavorite,
        );
      }
      return s;
    }).toList();
  }
});

/// Desktop: scan user's Music folder and custom additions
Future<List<SongModel>> _scanDesktopMusicLibrary(
    CustomLibrary customLib, MetadataScan scan) async {
  // Isar tag cache - lets us skip reading tags for unchanged files.
  final isar = await IsarService.instance;
  final allCachedSongs = await isar.cachedSongs.where().findAll();
  final cacheMap = {for (final e in allCachedSongs) normalizePath(e.path): e};
  final newOrUpdatedCache = <CachedSong>[];

  final folderPaths = <String>[];
  final individualFiles = <String>[];

  // Primary: the user's Music / Downloads folder. Built with the platform
  // separator so macOS and Linux work too (the old code hard-coded a
  // backslash and therefore never found those folders off Windows).
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  if (home.isNotEmpty) {
    folderPaths.add(p.join(home, 'Music'));
    folderPaths.add(p.join(home, 'Downloads'));
  }

  // Custom folders
  for (final folder in customLib.folders) {
    if (!folderPaths.contains(folder)) {
      folderPaths.add(folder);
    }
  }

  // Individual files
  individualFiles.addAll(customLib.files);

  final excluded = customLib.excludedFiles.map(normalizePath).toSet();
  final candidates = <_ScannedFile>[];
  final seen = <String>{};

  // 1. Files the user added explicitly
  for (final filePath in individualFiles) {
    if (scan.cancelled) return <SongModel>[];
    if (!isLibraryAudioFile(filePath)) continue;
    final key = normalizePath(filePath);
    if (excluded.contains(key) || !seen.add(key)) continue;
    try {
      final file = File(filePath);
      if (!await file.exists()) continue;
      final stat = await file.stat();
      candidates.add(_ScannedFile(file, stat.modified.millisecondsSinceEpoch));
    } catch (e) {
      debugPrint('Skipping unreadable file $filePath: $e');
    }
  }

  // 2. Folders (walked here: this only costs directory metadata)
  for (final musicPath in folderPaths) {
    if (scan.cancelled) return <SongModel>[];
    try {
      final musicDir = Directory(musicPath);
      if (!await musicDir.exists()) continue;
      await _collectAudioFiles(musicDir, candidates, seen, excluded, scan);
    } catch (e) {
      debugPrint('Skipping folder $musicPath: $e');
    }
  }

  if (scan.cancelled) return <SongModel>[];

  // 3. Reading tags is synchronous disk I/O. Doing it per file on the UI
  //    isolate froze the app on large libraries, so it now happens in a
  //    single background isolate pass.
  final needsMetadata = <String>[];
  for (final candidate in candidates) {
    final cached = cacheMap[normalizePath(candidate.file.path)];
    if (cached == null || cached.lastModifiedMs != candidate.lastModifiedMs) {
      needsMetadata.add(candidate.file.path);
    }
  }

  final metadata = <String, List<Object>>{};
  if (needsMetadata.isNotEmpty) {
    try {
      final rows = await scan.read(needsMetadata);
      for (final row in rows) {
        metadata[row[0] as String] = row;
      }
    } catch (e) {
      debugPrint('Background metadata scan failed: $e');
    }
  }

  final songs = <SongModel>[];
  for (final candidate in candidates) {
    if (scan.cancelled) return <SongModel>[];
    final song = _buildSongFromCandidate(
        candidate, cacheMap, metadata, newOrUpdatedCache);
    final title = customLib.customTitles[normalizePath(candidate.file.path)];
    songs.add(title == null || title.isEmpty
        ? song
        : SongModel(
            id: song.id,
            title: title,
            artist: song.artist,
            album: song.album,
            data: song.data,
            duration: song.duration,
            dateAdded: song.dateAdded,
            albumId: song.albumId,
            artworkPath: song.artworkPath,
            isFavorite: song.isFavorite));
  }

  // Sort by date added (newest first)
  songs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  if (newOrUpdatedCache.isNotEmpty && !scan.cancelled) {
    await isar.writeTxn(() async {
      await isar.cachedSongs.putAll(newOrUpdatedCache);
    });
  }

  return songs;
}

/// A file picked up by the desktop scan plus the stat data needed to decide
/// whether its cached tags are still valid.
class _ScannedFile {
  final File file;
  final int lastModifiedMs;

  const _ScannedFile(this.file, this.lastModifiedMs);
}

/// Walks [dir] recursively and collects the audio files it finds.
/// `followLinks: false` plus the depth guard keeps junctions / symlink loops
/// from hanging the scan, and unreadable entries are skipped instead of
/// aborting the whole scan.
Future<void> _collectAudioFiles(
  Directory dir,
  List<_ScannedFile> out,
  Set<String> seen,
  Set<String> excluded,
  MetadataScan scan, {
  int depth = 0,
}) async {
  if (depth > 12) return;
  try {
    final stream =
        dir.list(recursive: false, followLinks: false).handleError((e) {
      debugPrint('Skipping unreadable entity in ${dir.path}: $e');
    });

    await for (final entity in stream) {
      if (scan.cancelled) return;

      if (entity is Directory) {
        await _collectAudioFiles(entity, out, seen, excluded, scan,
            depth: depth + 1);
      } else if (entity is File) {
        try {
          if (!isLibraryAudioFile(entity.path)) continue;
          final key = normalizePath(entity.path);
          if (excluded.contains(key) || !seen.add(key)) continue;
          final stat = await entity.stat();
          out.add(_ScannedFile(entity, stat.modified.millisecondsSinceEpoch));
        } catch (fileError) {
          debugPrint('Failed to process file ${entity.path}: $fileError');
        }
      }
    }
  } catch (e) {
    debugPrint('Access denied or error reading directory ${dir.path}: $e');
  }
}

/// Builds a [SongModel] from a scanned file, reusing the Isar tag cache when
/// the file has not been modified since the previous scan.
SongModel _buildSongFromCandidate(
  _ScannedFile scanned,
  Map<String, CachedSong> cacheMap,
  Map<String, List<Object>> metadata,
  List<CachedSong> newOrUpdatedCache,
) {
  final file = scanned.file;
  final path = file.path;
  final fileName = path.split(Platform.pathSeparator).last;
  final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
  final album = file.parent.path.split(Platform.pathSeparator).last;
  final dateAdded = scanned.lastModifiedMs ~/ 1000;

  final cached = cacheMap[normalizePath(path)];
  if (cached != null && cached.lastModifiedMs == scanned.lastModifiedMs) {
    return SongModel(
      id: stablePathId(path),
      title: cached.title,
      artist: cached.artist,
      album: album,
      data: path,
      duration: cached.durationMs,
      dateAdded: cached.dateAddedSeconds,
    );
  }

  final row = metadata[path];
  var title = (row?[1] as String?) ?? '';
  var artist = (row?[2] as String?) ?? '';
  final durationMs = (row?[3] as int?) ?? 0;
  final tagsRead = (row?[4] as bool?) ?? false;

  if (title.isEmpty) title = nameWithoutExt;
  if (artist.isEmpty) {
    // Fall back to the common "Artist - Title" file name convention.
    if (!tagsRead && nameWithoutExt.contains(' - ')) {
      final parts = nameWithoutExt.split(' - ');
      artist = parts.first.trim();
      title = parts.sublist(1).join(' - ').trim();
    } else {
      artist = 'Unknown Artist';
    }
  }

  newOrUpdatedCache.add(CachedSong()
    ..id = cached?.id ?? Isar.autoIncrement
    ..path = path
    ..title = title
    ..artist = artist
    ..album = album
    ..durationMs = durationMs
    ..dateAddedSeconds = dateAdded
    ..lastModifiedMs = scanned.lastModifiedMs);

  return SongModel(
    id: stablePathId(path),
    title: title,
    artist: artist,
    album: album,
    data: path,
    duration: durationMs,
    dateAdded: dateAdded,
  );
}

/// Asks MediaStore to index common music folders and individual audio files.
///
/// Files copied onto the device from outside the app (file manager, USB, adb)
/// are not in MediaStore until something triggers a scan.
Future<void> scanMediaStoreForNewFiles() async {
  if (!isMobile) return;
  const dirs = <String>[
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Music/MusiConvert',
    '/storage/emulated/0/Audiobooks',
    '/storage/emulated/0/Podcasts',
    '/storage/emulated/0/Recordings',
  ];
  final audioExtensions = <String>{
    '.mp3',
    '.m4a',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.opus',
    '.wma'
  };
  final query = aq.OnAudioQuery();
  for (final dir in dirs) {
    try {
      final d = Directory(dir);
      if (await d.exists()) {
        await query.scanMedia(dir);
        try {
          await for (final entity in d
              .list(recursive: false, followLinks: false)
              .handleError((_) {})) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (audioExtensions.contains(ext)) {
                await query.scanMedia(entity.path);
              }
            } else if (entity is Directory) {
              await query.scanMedia(entity.path);
              await for (final subEntity in entity
                  .list(recursive: false, followLinks: false)
                  .handleError((_) {})) {
                if (subEntity is File) {
                  final ext = p.extension(subEntity.path).toLowerCase();
                  if (audioExtensions.contains(ext)) {
                    await query.scanMedia(subEntity.path);
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Media scan failed for $dir: $e');
    }
  }
}

/// Finds audio files on the device that match any of the given excluded paths.
/// Used during library refresh to ask the user if they want to restore them.
Future<List<SongModel>> getExcludedSongsOnDevice(
    Iterable<String> excludedPaths) async {
  final normalizedExcluded = excludedPaths.map(normalizePath).toSet();
  if (normalizedExcluded.isEmpty) return [];

  final found = <SongModel>[];
  final foundPaths = <String>{};

  if (isMobile) {
    try {
      final audioQuery = aq.OnAudioQuery();
      final allSongs = await audioQuery.querySongs(
        sortType: null,
        orderType: aq.OrderType.ASC_OR_SMALLER,
        uriType: aq.UriType.EXTERNAL,
        ignoreCase: true,
      );
      for (final s in allSongs) {
        final norm = normalizePath(s.data);
        if (normalizedExcluded.contains(norm) && !foundPaths.contains(norm)) {
          String artist = s.artist ?? '';
          String album = s.album ?? '';
          final lowerArtist = artist.trim().toLowerCase();
          if (lowerArtist.isEmpty ||
              lowerArtist == '<unknown>' ||
              lowerArtist == 'unknown') {
            artist = 'Unknown Artist';
          }
          final lowerAlbum = album.trim().toLowerCase();
          if (lowerAlbum.isEmpty ||
              lowerAlbum == '<unknown>' ||
              lowerAlbum == 'unknown') {
            album = 'Unknown Album';
          }
          found.add(SongModel(
            id: s.id,
            title: s.title,
            artist: artist,
            album: album,
            data: s.data,
            duration: s.duration ?? 0,
            dateAdded: s.dateAdded ?? 0,
            albumId: s.albumId ?? 0,
          ));
          foundPaths.add(norm);
        }
      }
    } catch (e) {
      debugPrint('Error querying excluded songs from audio query: $e');
    }
  }

  // Fallback for any excluded path on disk not indexed by MediaStore, or on Desktop
  for (final path in excludedPaths) {
    if (isDesktop && !isLibraryAudioFile(path)) continue;
    final norm = normalizePath(path);
    if (!foundPaths.contains(norm)) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final title = p.basenameWithoutExtension(path);
          found.add(SongModel(
            id: stablePathId(path),
            title: title,
            artist: 'Unknown Artist',
            album: 'Unknown Album',
            data: path,
            duration: 0,
            dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ));
          foundPaths.add(norm);
        }
      } catch (_) {}
    }
  }

  return found;
}

/// Checks whether audio access permission has already been granted.
Future<bool> checkAudioPermission() async {
  if (!isMobile) return true;
  if (!Platform.isAndroid) {
    return (await Permission.audio.status).isGranted;
  }
  final sdk = await _MobileScannerImpl.androidSdkInt();
  if (sdk >= 33) {
    if (await Permission.audio.isGranted) return true;
    return await Permission.storage.isGranted;
  }
  return await Permission.storage.isGranted;
}

/// Requests audio access permission and returns whether granted.
Future<bool> requestAudioPermission() async {
  if (!isMobile) return true;
  if (!Platform.isAndroid) {
    final req = await Permission.audio.request();
    return req.isGranted;
  }
  final sdk = await _MobileScannerImpl.androidSdkInt();
  if (sdk >= 33) {
    if (await Permission.audio.isGranted) return true;
    final audio = await Permission.audio.request();
    if (audio.isGranted) return true;
    return (await Permission.storage.request()).isGranted;
  }
  if (await Permission.storage.isGranted) return true;
  return (await Permission.storage.request()).isGranted;
}

/// Mobile: use on_audio_query to scan device
Future<List<SongModel>> _scanMobileLibrary() async {
  try {
    return await _mobileScan();
  } catch (e, st) {
    // Don't hide the failure completely: an empty library with no trace made
    // permission / MediaStore problems impossible to diagnose.
    debugPrint('Mobile library scan failed: $e\n$st');
    return [];
  }
}

Future<List<SongModel>> _mobileScan() async {
  // This will be handled by the mobile implementation
  // Import on_audio_query and permission_handler only on mobile
  if (!isMobile) return [];

  try {
    final onAudioQuery = await _getOnAudioQuery();
    if (onAudioQuery == null) return [];
    return onAudioQuery;
  } catch (e) {
    debugPrint('Mobile scan error: $e');
    return [];
  }
}

Future<List<SongModel>?> _getOnAudioQuery() async {
  if (!isMobile) return [];

  // We need to use the mobile-specific scanner
  // This is handled via mobile_song_scanner.dart
  return await MobileSongScanner.scan();
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Song Scanner - isolated to avoid importing mobile-only packages
// ─────────────────────────────────────────────────────────────────────────────
class MobileSongScanner {
  static Future<List<SongModel>> scan() async {
    if (!isMobile) return [];
    // Dynamic import approach - this will only execute on mobile
    try {
      // Use platform channel or plugin registry
      final scanner = _MobileScannerImpl();
      return await scanner.querySongs();
    } catch (e) {
      debugPrint('Mobile song scanner failed: $e');
      return [];
    }
  }
}

class _MobileScannerImpl {
  static int? _cachedSdkInt;

  static Future<int> androidSdkInt() async {
    if (_cachedSdkInt != null) return _cachedSdkInt!;
    try {
      _cachedSdkInt = await const MethodChannel('com.musiconvert.mp3noads/lock')
          .invokeMethod<int>('sdkInt');
    } catch (_) {}
    return _cachedSdkInt ?? 33;
  }

  Future<bool> _ensureAudioPermission() async {
    return await requestAudioPermission();
  }

  Future<List<SongModel>> querySongs() async {
    if (!isMobile) return [];

    if (!await _ensureAudioPermission()) return [];

    // Also request notification permission (required for Android 13+)
    if (Platform.isAndroid) {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }
    }

    // Automatically index media directories so MediaStore contains all audio files on device
    await scanMediaStoreForNewFiles();

    final audioQuery = aq.OnAudioQuery();
    final songsList = await audioQuery.querySongs(
      sortType: null,
      orderType: aq.OrderType.ASC_OR_SMALLER,
      uriType: aq.UriType.EXTERNAL,
      ignoreCase: true,
    );

    final mapped = songsList.map((s) {
      String artist = s.artist ?? '';
      String album = s.album ?? '';
      // Clean up ugly MediaStore <Unknown> tags
      final lowerArtist = artist.trim().toLowerCase();
      if (lowerArtist.isEmpty ||
          lowerArtist == '<unknown>' ||
          lowerArtist == 'unknown') {
        artist = 'Unknown Artist';
      }
      final lowerAlbum = album.trim().toLowerCase();
      if (lowerAlbum.isEmpty ||
          lowerAlbum == '<unknown>' ||
          lowerAlbum == 'unknown') {
        album = 'Unknown Album';
      }
      return SongModel(
        id: s.id,
        title: s.title,
        artist: artist,
        album: album,
        data: s.data,
        duration: s.duration ?? 0,
        dateAdded: s.dateAdded ?? 0,
        albumId: s.albumId ?? 0,
      );
    }).toList();

    return mapped;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sorting
// ─────────────────────────────────────────────────────────────────────────────
enum SortOption { dateAdded, title, artist, duration, fileType }

final sortOptionProvider =
    StateProvider<SortOption>((ref) => SortOption.dateAdded);

// Search filter
final songSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredSongsProvider = Provider<AsyncValue<List<SongModel>>>((ref) {
  final query = ref.watch(songSearchQueryProvider).toLowerCase();
  final sortOption = ref.watch(sortOptionProvider);
  final songsAsync = ref.watch(songLibraryProvider);

  return songsAsync.whenData((songs) {
    // Filter and build the lower-case sort keys in ONE pass. Lower-casing
    // inside the sort comparators meant ~2 allocations per comparison
    // (hundreds of thousands of them per keystroke on a big library).
    final filtered = <SongModel>[];
    final titleKeys = <SongModel, String>{};
    final artistKeys = <SongModel, String>{};

    for (final song in songs) {
      final title = song.title.toLowerCase();
      final artist = song.artist.toLowerCase();
      if (query.isNotEmpty &&
          !title.contains(query) &&
          !artist.contains(query)) {
        continue;
      }
      filtered.add(song);
      titleKeys[song] = title;
      artistKeys[song] = artist;
    }

    switch (sortOption) {
      case SortOption.dateAdded:
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortOption.title:
        filtered.sort((a, b) => titleKeys[a]!.compareTo(titleKeys[b]!));
        break;
      case SortOption.artist:
        filtered.sort((a, b) {
          final byArtist = artistKeys[a]!.compareTo(artistKeys[b]!);
          return byArtist != 0
              ? byArtist
              : titleKeys[a]!.compareTo(titleKeys[b]!);
        });
        break;
      case SortOption.duration:
        filtered.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case SortOption.fileType:
        final extKeys = <SongModel, String>{
          for (final song in filtered)
            song: song.data.split('.').last.toLowerCase(),
        };
        filtered.sort((a, b) {
          final byExt = extKeys[a]!.compareTo(extKeys[b]!);
          return byExt != 0 ? byExt : titleKeys[a]!.compareTo(titleKeys[b]!);
        });
        break;
    }

    return filtered;
  });
});
