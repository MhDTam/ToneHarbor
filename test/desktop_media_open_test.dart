import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/services/audio/desktop_media_open.dart';

void main() {
  test('Explorer paths retain Arabic, spaces and exact order without videos',
      () async {
    final songs = await desktopOpenedSongs({
      'paths': [
        r'C:\Poetry\أم الغرباء - جلسة هادئة.mp3',
        r'C:\Music\second.flac',
        r'C:\Music\video.mp4',
        r'C:\Music\missing.wav',
        r'C:\Music\second.flac',
      ]
    }, exists: (path) async => !path.contains('missing'));
    expect(songs, hasLength(2));
    expect(songs.first.title, 'أم الغرباء - جلسة هادئة');
    expect(songs.first.data, r'C:\Poetry\أم الغرباء - جلسة هادئة.mp3');
    expect(songs.last.data, r'C:\Music\second.flac');
    expect(songs.first.id, isNot(songs.last.id));
  });
  test('invalid payloads and inaccessible files recover safely', () async {
    expect(await desktopOpenedSongs(null), isEmpty);
    expect(await desktopOpenedSongs({'paths': 'a.mp3'}), isEmpty);
    final songs = await desktopOpenedSongs({
      'paths': [12, null, 'http://host/file.mp3', 'good.wav']
    }, exists: (path) async {
      if (path.startsWith('http')) throw StateError('inaccessible');
      return true;
    });
    expect(songs.map((s) => s.data), ['good.wav']);
    final legacy = await desktopOpenedSongs({'path': 'old-style.mp3'},
        exists: (_) async => true);
    expect(legacy.single.title, 'old-style');
  });
}
