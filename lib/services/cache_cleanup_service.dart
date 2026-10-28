import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CacheCleanupService {
  CacheCleanupService._();

  /// Checks whether [filePath] is located within the application's temporary or cache directories.
  /// If it is, safely deletes the file. Never deletes files from external public storage.
  static Future<bool> deleteIfTemporary(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return false;

    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final canonicalFilePath = file.resolveSymbolicLinksSync();

      // Gather candidate temporary / cache directories
      final List<Directory> safeDirectories = [];

      try {
        final tempDir = await getTemporaryDirectory();
        safeDirectories.add(tempDir);
      } catch (_) {}

      try {
        final extCacheDirs = await getExternalCacheDirectories();
        if (extCacheDirs != null) {
          safeDirectories.addAll(extCacheDirs);
        }
      } catch (_) {}

      bool isInsideTemp = false;
      for (final dir in safeDirectories) {
        try {
          final canonicalDirPath = dir.resolveSymbolicLinksSync();
          if (canonicalFilePath.startsWith(canonicalDirPath)) {
            isInsideTemp = true;
            break;
          }
        } catch (_) {}
      }

      if (isInsideTemp) {
        await file.delete();
        debugPrint(
            'CacheCleanupService: Successfully deleted temporary file: $filePath');
        return true;
      } else {
        debugPrint(
            'CacheCleanupService: Skipped deletion, file is not in temporary cache: $filePath');
      }
    } catch (e) {
      debugPrint(
          'CacheCleanupService: Failed to delete temporary file $filePath: $e');
    }
    return false;
  }

  /// Calculates the total size in bytes of all files located in temporary and cache directories.
  static Future<int> getCacheSizeBytes() async {
    int totalBytes = 0;

    final List<Directory> targetDirs = [];
    try {
      targetDirs.add(await getTemporaryDirectory());
    } catch (_) {}

    try {
      final extDirs = await getExternalCacheDirectories();
      if (extDirs != null) {
        targetDirs.addAll(extDirs);
      }
    } catch (_) {}

    for (final dir in targetDirs) {
      try {
        if (await dir.exists()) {
          await for (final entity
              in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              try {
                totalBytes += await entity.length();
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint(
            'CacheCleanupService: Error calculating size for ${dir.path}: $e');
      }
    }

    return totalBytes;
  }

  /// Recursively deletes all files and empty directories in temporary and cache directories.
  static Future<void> clearAllCache() async {
    final List<Directory> targetDirs = [];
    try {
      targetDirs.add(await getTemporaryDirectory());
    } catch (_) {}

    try {
      final extDirs = await getExternalCacheDirectories();
      if (extDirs != null) {
        targetDirs.addAll(extDirs);
      }
    } catch (_) {}

    for (final dir in targetDirs) {
      try {
        if (await dir.exists()) {
          final entities = dir.listSync(recursive: false, followLinks: false);
          for (final entity in entities) {
            try {
              if (entity is File) {
                await entity.delete();
              } else if (entity is Directory) {
                await entity.delete(recursive: true);
              }
            } catch (e) {
              debugPrint(
                  'CacheCleanupService: Could not delete ${entity.path}: $e');
            }
          }
        }
      } catch (e) {
        debugPrint(
            'CacheCleanupService: Error clearing directory ${dir.path}: $e');
      }
    }
    debugPrint('CacheCleanupService: Cache clearance routine completed.');
  }

  /// Formats byte count to a user-friendly string (B, KB, MB, GB).
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
