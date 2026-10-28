import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/artwork_widget.dart';
import '../../../core/utils/platform_utils.dart';
import '../../desktop/harbor_themes.dart';
import '../../../data/models/song_model.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet dialog prompting the user to restore tracks
/// that were previously removed from the library (excluded).
class RestoreExcludedSheet extends ConsumerStatefulWidget {
  final List<SongModel> songs;

  const RestoreExcludedSheet({
    super.key,
    required this.songs,
  });

  /// Shows the modal bottom sheet and returns the list of songs selected for restoration.
  /// If the user dismisses or selects "Keep Hidden", returns null.
  static Future<List<SongModel>?> show(
    BuildContext context,
    List<SongModel> songs,
  ) {
    if (songs.isEmpty) return Future.value(null);
    return showModalBottomSheet<List<SongModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RestoreExcludedSheet(songs: songs),
    );
  }

  @override
  ConsumerState<RestoreExcludedSheet> createState() =>
      _RestoreExcludedSheetState();
}

class _RestoreExcludedSheetState extends ConsumerState<RestoreExcludedSheet> {
  late Set<String> _selectedPaths;

  @override
  void initState() {
    super.initState();
    // Default to all selected
    _selectedPaths = widget.songs.map((s) => s.data).toSet();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedPaths.length == widget.songs.length) {
        _selectedPaths.clear();
      } else {
        _selectedPaths = widget.songs.map((s) => s.data).toSet();
      }
    });
  }

  void _toggleSong(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final l = AppLocalizations.of(context)!;
    final accent =
        isDesktop ? ref.watch(harborThemeProvider).accent : theme.primary;
    final isSingle = widget.songs.length == 1;
    final allSelected = _selectedPaths.length == widget.songs.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.onSurface.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restore_page_rounded,
                      color: theme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.restoreExcludedTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.onSurface,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: theme.onSurface.withAlpha(120)),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subtitle / Prompt
              Text(
                isSingle
                    ? l.restoreExcludedPromptSingle
                    : l.restoreExcludedPromptMultiple,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.onSurface.withAlpha(180),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 16),

              // Songs display
              if (isSingle) ...[
                _buildSingleSongCard(widget.songs.first, theme),
              ] else ...[
                // Header with select all toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedPaths.length} / ${widget.songs.length}',
                      style: TextStyle(
                        color: theme.onSurface.withAlpha(140),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: Icon(
                        allSelected
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        size: 18,
                        color: theme.primary,
                      ),
                      label: Text(
                        allSelected ? l.deselectAll : l.selectAll,
                        style: TextStyle(color: theme.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // List of songs
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.songs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.onSurface.withAlpha(15),
                    ),
                    itemBuilder: (ctx, idx) {
                      final song = widget.songs[idx];
                      final isSelected = _selectedPaths.contains(song.data);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleSong(song.data),
                        activeColor: theme.primary,
                        contentPadding: EdgeInsets.zero,
                        secondary: PlatformArtworkWidget(
                          id: song.id,
                          path: song.data,
                          size: 42,
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.onSurface.withAlpha(120),
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: theme.onSurface.withAlpha(30)),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, null),
                      child: Text(
                        l.restoreExcludedKeepHidden,
                        style: TextStyle(
                          color: theme.onSurface.withAlpha(180),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const ValueKey('restore-library-action'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDesktop
                            ? Color.lerp(theme.surface, accent, .14)
                            : theme.primary,
                        foregroundColor: isDesktop ? accent : Colors.white,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        overlayColor: accent.withAlpha(18),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isDesktop
                              ? BorderSide(color: accent.withAlpha(65))
                              : BorderSide.none,
                        ),
                        elevation: 0,
                      ),
                      onPressed: (isSingle || _selectedPaths.isNotEmpty)
                          ? () {
                              final toRestore = isSingle
                                  ? widget.songs
                                  : widget.songs
                                      .where((s) =>
                                          _selectedPaths.contains(s.data))
                                      .toList();
                              Navigator.pop(context, toRestore);
                            }
                          : null,
                      child: Text(
                        l.restoreExcludedAction,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSongCard(SongModel song, dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.onSurface.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.onSurface.withAlpha(20)),
      ),
      child: Row(
        children: [
          PlatformArtworkWidget(
            id: song.id,
            path: song.data,
            size: 50,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.onSurface.withAlpha(140),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
