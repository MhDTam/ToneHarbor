import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/features/desktop/harbor_library_sort.dart';

SongModel song(int id, String title, String artist, String album, String file,
        int duration, int date) =>
    SongModel(
        id: id,
        title: title,
        artist: artist,
        album: album,
        data: file,
        duration: duration,
        dateAdded: date);

void main() {
  final songs = [
    song(1, 'Beta', 'Alpha', 'Second', r'C:\Z\b.wav', 30, 20),
    song(2, 'alpha', 'Zulu', 'First', r'C:\A\z.mp3', 10, 40),
    song(3, 'Gamma', 'Beta', 'Third', r'C:\B\a.flac', 20, 30),
  ];
  test('sort choices use the corresponding metadata and both directions', () {
    final orders = {
      HarborSort.title: [2, 1, 3],
      HarborSort.artist: [1, 3, 2],
      HarborSort.album: [2, 1, 3],
      HarborSort.duration: [2, 3, 1],
      HarborSort.dateAdded: [1, 3, 2],
      HarborSort.fileType: [3, 2, 1],
      HarborSort.fileName: [3, 1, 2],
      HarborSort.folder: [2, 3, 1],
    };
    for (final entry in orders.entries) {
      expect(
          sortHarborSongs(
                  songs, HarborSortSettings(mode: entry.key, ascending: true))
              .map((s) => s.id),
          entry.value,
          reason: '${entry.key}');
      expect(
          sortHarborSongs(
                  songs, HarborSortSettings(mode: entry.key, ascending: false))
              .map((s) => s.id),
          entry.value.reversed,
          reason: '${entry.key}');
    }
    expect(songs.first.id, 1);
  });
  test(
      'recent sorting leaves unplayed tracks after played tracks in either direction',
      () {
    expect(
        sortHarborSongs(
            songs,
            const HarborSortSettings(
                mode: HarborSort.recentlyPlayed, ascending: true),
            recentIds: [3, 1]).map((s) => s.id),
        [3, 1, 2]);
    expect(
        sortHarborSongs(
            songs, const HarborSortSettings(mode: HarborSort.recentlyPlayed),
            recentIds: [3, 1]).map((s) => s.id),
        [1, 3, 2]);
  });
  test('sort choice and direction survive a fresh notifier', () async {
    SharedPreferences.setMockInitialValues({});
    final first = HarborSortNotifier();
    await first.set(HarborSort.album, false);
    first.dispose();
    final next = HarborSortNotifier();
    await Future<void>.delayed(Duration.zero);
    expect(next.state.mode, HarborSort.album);
    expect(next.state.ascending, isFalse);
    next.dispose();
  });
}
