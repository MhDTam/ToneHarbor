import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/core/utils/file_naming.dart';

void main() {
  group('resolveRenamedFileName', () {
    test('keeps the source container when no extension is typed', () {
      expect(
        resolveRenamedFileName('/music/song.flac', 'My Song'),
        'My Song.flac',
      );
    });

    test('keeps the source container when a different one is typed', () {
      expect(
        resolveRenamedFileName('/music/song.flac', 'My Song.mp3'),
        'My Song.flac',
      );
    });

    test('does not duplicate an extension that already matches', () {
      expect(
        resolveRenamedFileName('/music/song.mp3', 'My Song.mp3'),
        'My Song.mp3',
      );
    });

    test('treats a non-audio trailing dot as part of the title', () {
      expect(
        resolveRenamedFileName('/music/song.flac', '01. Intro'),
        '01. Intro.flac',
      );
    });

    test('returns the name unchanged when the source has no extension', () {
      expect(resolveRenamedFileName('/music/song', 'My Song'), 'My Song');
    });
  });

  group('sanitizeFileName', () {
    test('strips path separators and reserved characters', () {
      expect(sanitizeFileName('../evil'), 'evil');
      expect(sanitizeFileName(r'a/b\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j');
    });

    test('trims whitespace and edge dots', () {
      expect(sanitizeFileName('  spaced  '), 'spaced');
      expect(sanitizeFileName('.hidden'), 'hidden');
      expect(sanitizeFileName('name.'), 'name');
      expect(sanitizeFileName('...'), '');
    });

    test('allows normal names with spaces and dashes', () {
      expect(sanitizeFileName('My - Song (Remix)'), 'My - Song (Remix)');
    });
  });
}
