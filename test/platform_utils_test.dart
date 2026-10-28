import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/core/utils/platform_utils.dart';

void main() {
  group('normalizePath', () {
    test('is idempotent', () {
      const path = 'C:/Music/Album/Song.mp3';
      expect(normalizePath(normalizePath(path)), normalizePath(path));
    });
  });

  group('stablePathId', () {
    test('matches the golden value on Windows (stored ids must stay valid)', () {
      if (!Platform.isWindows) {
        // normalizePath() only lower-cases and swaps separators on Windows, so
        // the golden value below is Windows-specific (verified on Windows).
        return;
      }
      const path = 'C:/Music/Album/Song.mp3';
      expect(stablePathId(path), equals(1213199848597765));
    });

    test('is identical for the same file reached with different separators',
        () {
      const slash = 'C:/Music/Album/Song.mp3';
      const backslash = r'C:\Music\Album\Song.mp3';
      if (Platform.isWindows) {
        // Windows paths are case- and separator-insensitive.
        expect(stablePathId(slash), equals(stablePathId(backslash)));
      } else {
        expect(stablePathId(slash), isNot(equals(stablePathId(backslash))));
      }
    });

    test('is stable across repeated scans (no counter folded in)', () {
      final ids = [for (var i = 0; i < 3; i++) stablePathId('C:/Music/a.mp3')];
      expect(ids.toSet().length, 1);
    });

    test('differs for different files', () {
      expect(
        stablePathId('C:/Music/a.mp3'),
        isNot(equals(stablePathId('C:/Music/b.mp3'))),
      );
    });

    test('stays non-negative and inside the 53-bit range', () {
      for (final path in <String>[
        '',
        'a',
        'C:/Music/Album/Song.flac',
        r'D:\very\deep\folder\name with spaces\تست.mp3',
      ]) {
        final id = stablePathId(path);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(1 << 53));
      }
    });

    test('does not collide across a realistic library', () {
      final ids = <int>{};
      for (var i = 0; i < 5000; i++) {
        ids.add(stablePathId('C:/Music/Album ${i % 50}/Track $i.mp3'));
      }
      expect(ids.length, 5000);
    });
  });
}
