import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/utils/audio_formats.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/models/song_model.dart';

/// Treat Explorer/command-line paths as input data. Opening never imports a
/// file into the library, evaluates commands, or accepts video containers.
Future<List<SongModel>> desktopOpenedSongs(Object? payload,
    {Future<bool> Function(String)? exists}) async {
  if (payload is! Map) return [];
  final raw = payload['paths'] ?? [payload['path']];
  if (raw is! List) return [];
  final seen = <String>{};
  final songs = <SongModel>[];
  for (final path in raw.whereType<String>()) {
    if (!isLibraryAudioFile(path) || !seen.add(normalizePath(path))) continue;
    try {
      if (!await (exists ?? ((path) => File(path).exists()))(path)) continue;
    } catch (_) {
      continue;
    }
    songs.add(SongModel(
        id: stablePathId(path),
        title: p.basenameWithoutExtension(path),
        artist: 'Unknown Artist',
        album: 'Opened audio',
        data: path,
        duration: 0,
        dateAdded: 0));
  }
  return songs;
}
