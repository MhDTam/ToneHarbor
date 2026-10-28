import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../../data/models/song_model.dart';

enum HarborSort {
  dateAdded,
  title,
  artist,
  album,
  duration,
  fileType,
  fileName,
  folder,
  recentlyPlayed
}

extension HarborSortLabel on HarborSort {
  String get label => switch (this) {
        HarborSort.dateAdded => 'Date added',
        HarborSort.title => 'Title',
        HarborSort.artist => 'Artist',
        HarborSort.album => 'Album',
        HarborSort.duration => 'Duration',
        HarborSort.fileType => 'File type',
        HarborSort.fileName => 'File name',
        HarborSort.folder => 'Folder',
        HarborSort.recentlyPlayed => 'Recently played',
      };
  bool get defaultAscending =>
      this != HarborSort.dateAdded && this != HarborSort.duration;
}

class HarborSortSettings {
  final HarborSort mode;
  final bool ascending;
  const HarborSortSettings(
      {this.mode = HarborSort.dateAdded, this.ascending = false});
}

class HarborSortNotifier extends StateNotifier<HarborSortSettings> {
  bool _changed = false;
  HarborSortNotifier() : super(const HarborSortSettings()) {
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('harbor_library_sort');
    if (!mounted || _changed) return;
    final mode = HarborSort.values.where((s) => s.name == name).firstOrNull ??
        HarborSort.dateAdded;
    state = HarborSortSettings(
        mode: mode,
        ascending:
            prefs.getBool('harbor_sort_ascending') ?? mode.defaultAscending);
  }

  Future<void> set(HarborSort mode, bool ascending) async {
    _changed = true;
    state = HarborSortSettings(mode: mode, ascending: ascending);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('harbor_library_sort', mode.name);
    await prefs.setBool('harbor_sort_ascending', ascending);
  }
}

final harborLibrarySortProvider =
    StateNotifierProvider<HarborSortNotifier, HarborSortSettings>(
        (_) => HarborSortNotifier());

List<SongModel> sortHarborSongs(
    List<SongModel> songs, HarborSortSettings settings,
    {List<int> recentIds = const []}) {
  final recent = {for (var i = 0; i < recentIds.length; i++) recentIds[i]: i};
  final text = <int, String>{};
  for (final song in songs) {
    text[song.id] = (switch (settings.mode) {
      HarborSort.title => song.title,
      HarborSort.artist => song.artist,
      HarborSort.album => song.album,
      HarborSort.fileType => p.extension(song.data),
      HarborSort.fileName => p.basename(song.data),
      HarborSort.folder => p.dirname(song.data),
      _ => song.title,
    })
        .toLowerCase();
  }
  final result = List<SongModel>.of(songs);
  result.sort((a, b) {
    if (settings.mode == HarborSort.recentlyPlayed &&
        recent.containsKey(a.id) != recent.containsKey(b.id)) {
      return recent.containsKey(a.id) ? -1 : 1;
    }
    var comparison = switch (settings.mode) {
      HarborSort.dateAdded => a.dateAdded.compareTo(b.dateAdded),
      HarborSort.duration => a.duration.compareTo(b.duration),
      HarborSort.recentlyPlayed =>
        (recent[a.id] ?? 0x7fffffff).compareTo(recent[b.id] ?? 0x7fffffff),
      _ => text[a.id]!.compareTo(text[b.id]!),
    };
    if (!settings.ascending) comparison = -comparison;
    return comparison != 0
        ? comparison
        : a.title.toLowerCase().compareTo(b.title.toLowerCase()) != 0
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : a.id.compareTo(b.id);
  });
  return result;
}
