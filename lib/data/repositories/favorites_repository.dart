import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFavoritesKey = 'favorite_songs';

class FavoritesNotifier extends StateNotifier<Set<int>> {
  late final Future<void> _ready;
  FavoritesNotifier() : super(const {}) {
    _ready = _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kFavoritesKey) ?? [];
    // tryParse: a single corrupt entry used to throw and wipe the whole set.
    if (mounted) state = list.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> setMany(Iterable<int> ids, bool liked) async {
    await _ready;
    if (!mounted) return;
    final current = Set<int>.of(state);
    if (liked) {
      current.addAll(ids);
    } else {
      current.removeAll(ids);
    }
    state = current;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kFavoritesKey, current.map((id) => '$id').toList());
  }

  Future<void> toggle(int id) async {
    await _ready;
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final current = Set<int>.from(state);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = current;
    await prefs.setStringList(
        _kFavoritesKey, current.map((e) => e.toString()).toList());
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) {
  return FavoritesNotifier();
});
