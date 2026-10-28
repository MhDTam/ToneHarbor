import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'safe_metadata_reader.dart';
import '../../core/utils/platform_utils.dart';
import 'artwork_loader.dart';

final artworkLoaderProvider = Provider<ArtworkLoader>((ref) {
  final loader = ArtworkLoader(
      read: (path) => compute(_readArtwork, path),
      version: (path) async {
        final stat = await File(path).stat();
        return (stat.type, stat.size, stat.modified.microsecondsSinceEpoch);
      });
  ref.onDispose(loader.close);
  return loader;
});

// ─────────────────────────────────────────────────────────────────────────────
// Shared Artwork Provider – caches extracted album art as raw bytes
// ─────────────────────────────────────────────────────────────────────────────

/// Embedded artwork read straight from the file (works on every platform).
///
/// On mobile prefer [artworkBytesByIdProvider]: album art that lives in the
/// MediaStore is not embedded in the file itself.
final artworkBytesProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>((ref, path) {
  final loader = ref.watch(artworkLoaderProvider);
  final request = loader.load(path);
  final pending = ref.keepAlive();
  var cancelled = false;
  ref.onCancel(() {
    cancelled = true;
    loader.cancel(path, request);
  });
  ref.onResume(() {
    if (cancelled) ref.invalidateSelf();
  });
  ref.onDispose(() => loader.cancel(path, request));
  return request.whenComplete(pending.close);
});

Uint8List? _readArtwork(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return readAudioTags(path, includeArtwork: true).artwork;
}

/// MediaStore ids are small positive 32-bit values.
///
/// Songs that do not come from the library (a file opened through "Open with",
/// a converted file, ...) are given a 53-bit path hash instead. Passing such a
/// value to `on_audio_query` overflows the platform `int` and the plugin
/// crashes the whole app with `IllegalStateException: Reply already submitted`,
/// so it must never happen.
bool isValidMediaStoreId(int id) => id > 0 && id <= 0x7FFFFFFF;

/// MediaStore artwork for a mobile song id.
///
/// This used to be part of [artworkBytesProvider] as `querySongs()` plus a
/// linear scan, i.e. a full MediaStore query for every single artwork widget
/// (very slow on a real library). Reading one row by id is orders of magnitude
/// cheaper, and the song id *is* the MediaStore id on mobile.
final artworkBytesByIdProvider =
    FutureProvider.family<Uint8List?, int>((ref, id) async {
  if (!isMobile || !isValidMediaStoreId(id)) return null;
  try {
    final art =
        await OnAudioQuery().queryArtwork(id, ArtworkType.AUDIO, size: 600);
    if (art != null && art.isNotEmpty) return art;
  } catch (e) {
    debugPrint('MediaStore artwork lookup failed for id $id: $e');
  }
  return null;
});
