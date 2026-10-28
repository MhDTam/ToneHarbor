import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On Windows getTemporaryDirectory() is the shared user Temp directory.
/// Only this application's dedicated namespace belongs to the cache service.
class CacheCleanupService {
  CacheCleanupService._();
  static const directoryName = 'toneharbor-cache';

  static Future<Directory> directory({bool create = true}) async {
    final base = await getTemporaryDirectory();
    final canonicalBase = await base.resolveSymbolicLinks();
    final owned = Directory(p.join(canonicalBase, directoryName));
    if (await FileSystemEntity.type(owned.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw FileSystemException(
        'Application cache cannot be a link',
        owned.path,
      );
    }
    if (create) await owned.create(recursive: true);
    return owned;
  }

  static Future<Directory> createTemporaryDirectory(String prefix) async =>
      (await directory()).createTemp(prefix);

  static Future<bool> deleteIfTemporary(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return false;
    try {
      final root = await directory(create: false);
      final file = File(filePath);
      if (!await root.exists() || !await file.exists()) return false;
      final parent = await root.resolveSymbolicLinks();
      final actual = await file.resolveSymbolicLinks();
      if (!p.isWithin(parent, actual)) return false;
      await file.delete();
      return true;
    } catch (error) {
      debugPrint('Application cache cleanup: $error');
      return false;
    }
  }

  static Future<int> getCacheSizeBytes() async {
    var bytes = 0;
    try {
      final root = await directory(create: false);
      if (!await root.exists()) return 0;
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            bytes += await entity.length();
          } catch (_) {}
        }
      }
    } catch (error) {
      debugPrint('Application cache size: $error');
    }
    return bytes;
  }

  /// Explicit clear removes only owned entries. Startup uses an age threshold.
  static Future<void> clearAllCache({Duration? olderThan}) async {
    try {
      final root = await directory(create: false);
      if (!await root.exists()) return;
      final cutoff = olderThan == null
          ? null
          : DateTime.now().subtract(olderThan);
      await for (final entity in root.list(followLinks: false)) {
        try {
          if (cutoff != null) {
            final stat = await entity.stat();
            if (!stat.modified.isBefore(cutoff)) continue;
          }
          // Link deletion removes the link itself, never its target.
          await entity.delete(recursive: entity is Directory);
        } catch (error) {
          debugPrint('Application cache entry cleanup: $error');
        }
      }
    } catch (error) {
      debugPrint('Application cache cleanup: $error');
    }
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
  }
}
