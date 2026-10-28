import 'dart:io';

bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;
bool get isMobile => Platform.isAndroid || Platform.isIOS;
bool get isWindows => Platform.isWindows;

String normalizePath(String path) {
  if (Platform.isWindows) {
    return path.toLowerCase().replaceAll('/', '\\');
  }
  return path;
}

/// Deterministic 53-bit hash of a file path.
///
/// Used as the song id on desktop: it only depends on the (normalised) path,
/// so favourites, playlists and queue positions keep pointing at the same song
/// after a rescan - the previous implementation folded in a per-scan counter,
/// which silently re-numbered the whole library whenever a file was added.
int stablePathId(String path) {
  const int offset = 0x811c9dc5; // FNV-1a offset basis
  const int prime = 0x100000001b3; // FNV-1a prime
  const int mask = 0x1FFFFFFFFFFFFF; // 53 bits - safe on every Dart platform
  var hash = offset;
  for (final unit in normalizePath(path).codeUnits) {
    hash = ((hash ^ unit) * prime) & mask;
  }
  return hash;
}
