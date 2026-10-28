import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedSongIdsProvider = StateProvider<Set<int>>((ref) => {});
final isSelectionModeProvider = Provider<bool>((ref) {
  return ref.watch(selectedSongIdsProvider).isNotEmpty;
});
