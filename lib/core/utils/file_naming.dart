import 'package:path/path.dart' as p;

/// Container extensions the app understands. Only these are treated as an
/// extension when a user types a name into the rename dialog, so a title like
/// "01. Intro" keeps its dot instead of being truncated.
const Set<String> _kAudioExtensions = {
  '.mp3',
  '.m4a',
  '.wav',
  '.flac',
  '.ogg',
  '.aac',
  '.wma',
  '.opus',
  '.mp4',
  '.mkv',
  '.webm',
  '.avi',
  '.3gp',
  '.wmv',
  '.mov',
};

/// Characters that are illegal in a file name on at least one supported
/// platform (Windows is the strictest).
final RegExp _kIllegalFileNameChars = RegExp(r'[\\/:*?"<>|\x00-\x1F]');

/// Strips path separators and other reserved characters from a user supplied
/// file name. Prevents a typed name like `../../evil` from escaping the target
/// directory when it is joined onto a path.
String sanitizeFileName(String name) {
  final cleaned = name
      .replaceAll(_kIllegalFileNameChars, '_')
      // Leading/trailing dots (hidden / reserved on Windows) and whitespace.
      .replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '')
      // Separators that ended up at the edges are dropped entirely.
      .replaceAll(RegExp(r'^_+|_+$'), '')
      .trim();
  return cleaned;
}

/// Builds the new file name for a rename while keeping the original container
/// extension.
///
/// Renaming must never change the container: renaming a `.flac` file to
/// "My Song" used to append `.mp3`, which produced a FLAC file with an MP3
/// extension that most players refuse to open. A trailing extension that is
/// not a known audio container (e.g. "01. Intro") is treated as part of the
/// title instead.
String resolveRenamedFileName(String currentPath, String requestedName) {
  final sourceExt = p.extension(currentPath);
  final trimmed = requestedName.trim();
  if (sourceExt.isEmpty) return trimmed;

  final lower = trimmed.toLowerCase();
  final lowerSourceExt = sourceExt.toLowerCase();
  if (lower.endsWith(lowerSourceExt)) return trimmed;

  for (final ext in _kAudioExtensions) {
    if (lower.endsWith(ext)) {
      return '${trimmed.substring(0, trimmed.length - ext.length)}$sourceExt';
    }
  }
  return '$trimmed$sourceExt';
}
