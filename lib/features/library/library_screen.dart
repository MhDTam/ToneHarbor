import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/app_toast.dart';

import '../../core/router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/song_options_modal.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../core/utils/artwork_widget.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/repositories/custom_library_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/selection_mode_provider.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/restore_excluded_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with WidgetsBindingObserver {
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isMobile) {
      _onResumed();
    }
  }

  Future<void> _checkPermissionState() async {
    if (!isMobile) return;
    final ok = await checkAudioPermission();
    if (mounted && _hasPermission != ok) {
      setState(() => _hasPermission = ok);
    }
  }

  Future<void> _onResumed() async {
    final ok = await checkAudioPermission();
    if (mounted && _hasPermission != ok) {
      setState(() => _hasPermission = ok);
    }
    if (ok) {
      final songs = ref.read(songLibraryProvider).valueOrNull;
      if (songs == null || songs.isEmpty) {
        await _rescanLibrary(ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final songsAsync = ref.watch(filteredSongsProvider);
    final searchQuery = ref.watch(songSearchQueryProvider);
    final sortOption = ref.watch(sortOptionProvider);
    // select(): watching the whole player state would rebuild the entire
    // library list on every playback position tick.
    final playingSongId = ref.watch(
      audioPlayerProvider.select((s) => s.isPlaying ? s.currentSong?.id : null),
    );
    final player = ref.read(audioPlayerProvider.notifier);
    final selectedIds = ref.watch(selectedSongIdsProvider);
    final favorites = ref.watch(favoritesProvider);

    return DropTarget(
      onDragDone: (details) async {
        final l = AppLocalizations.of(context)!;
        bool changed = false;
        for (final xFile in details.files) {
          final isDir = await FileSystemEntity.isDirectory(xFile.path);
          if (isDir) {
            await ref
                .read(customLibraryProvider.notifier)
                .addFolder(xFile.path);
            changed = true;
          } else {
            await ref.read(customLibraryProvider.notifier).addFile(xFile.path);
            changed = true;
          }
        }
        if (changed) {
          ref.invalidate(songLibraryProvider);
          if (context.mounted) {
            AppToast.success(context, l.mediaAdded);
          }
        }
      },
      child: Material(
        color: Colors.transparent,
        child: AppBackground(
          theme: theme,
          child: SafeArea(
            top: isMobile,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 20,
                      isDesktop ? 20 : 12, isDesktop ? 28 : 20, 0),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.library,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: isDesktop ? 24 : null,
                            ),
                      ),
                      const Spacer(),
                      if (isDesktop) ...[
                        IconButton(
                          icon: Icon(Icons.create_new_folder_rounded,
                              color: theme.onSurface),
                          tooltip: AppLocalizations.of(context)!.addMusicFolder,
                          onPressed: () async {
                            final l = AppLocalizations.of(context)!;
                            final path =
                                await FilePicker.platform.getDirectoryPath(
                              dialogTitle: l.addMusicFolder,
                            );
                            if (path != null) {
                              await ref
                                  .read(customLibraryProvider.notifier)
                                  .addFolder(path);
                              ref.invalidate(songLibraryProvider);
                              if (context.mounted) {
                                AppToast.success(context, l.mediaAdded);
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.note_add_rounded,
                              color: theme.onSurface),
                          tooltip: AppLocalizations.of(context)!.addAudioFile,
                          onPressed: () async {
                            final l = AppLocalizations.of(context)!;
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.audio,
                              allowMultiple: true,
                              dialogTitle: l.addAudioFile,
                            );
                            if (result != null && result.paths.isNotEmpty) {
                              for (final path in result.paths) {
                                if (path != null) {
                                  await ref
                                      .read(customLibraryProvider.notifier)
                                      .addFile(path);
                                }
                              }
                              ref.invalidate(songLibraryProvider);
                              if (context.mounted) {
                                AppToast.success(context, l.filesAdded);
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded,
                              color: Colors.red, size: 24),
                          tooltip: AppLocalizations.of(context)!.favorites,
                          onPressed: () => context.push(AppRoutes.favorites),
                        ),
                      IconButton(
                        icon: Icon(Icons.settings_rounded,
                            color: theme.onSurface),
                        tooltip: AppLocalizations.of(context)!.settings,
                        onPressed: () => context.push(AppRoutes.settings),
                      ),
                      // Manual rescan: needed because new files are not picked
                      // up automatically once the (cached) scan has run.
                      IconButton(
                        icon:
                            Icon(Icons.refresh_rounded, color: theme.onSurface),
                        tooltip: AppLocalizations.of(context)!.refreshLibrary,
                        onPressed: () => _manualRefreshLibrary(context, ref),
                      ),
                      // Sort dropdown
                      PopupMenuButton<SortOption>(
                        icon: Icon(Icons.sort_rounded, color: theme.onSurface),
                        onSelected: (option) => ref
                            .read(sortOptionProvider.notifier)
                            .state = option,
                        itemBuilder: (_) => SortOption.values
                            .map((o) => PopupMenuItem(
                                  value: o,
                                  child: Row(
                                    children: [
                                      if (sortOption == o)
                                        Icon(Icons.check_rounded,
                                            color: theme.primary, size: 18),
                                      if (sortOption == o)
                                        const SizedBox(width: 8),
                                      Text(_sortLabel(o, context)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 28 : 20, 8, isDesktop ? 28 : 20, 8),
                  child: TextField(
                    onChanged: (q) =>
                        ref.read(songSearchQueryProvider.notifier).state = q,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchSongs,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Selection mode bar
                if (selectedIds.isNotEmpty)
                  _SelectionBar(
                    selectedIds: selectedIds,
                    theme: theme,
                  ),
                // Song list
                Expanded(
                  child: songsAsync.when(
                    data: (songs) => songs.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () =>
                                _manualRefreshLibrary(context, ref),
                            color: theme.primary,
                            backgroundColor: theme.surface,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.18),
                                if (!_hasPermission && isMobile) ...[
                                  Icon(Icons.folder_shared_rounded,
                                      color: theme.primary, size: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .permissionRequired,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .permissionMessage,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                theme.onSurface.withAlpha(140),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primary,
                                        foregroundColor: theme.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                      ),
                                      icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 20),
                                      label: Text(
                                        AppLocalizations.of(context)!
                                            .grantPermission,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () async {
                                        final granted =
                                            await requestAudioPermission();
                                        if (granted) {
                                          if (mounted) {
                                            setState(
                                                () => _hasPermission = true);
                                            await _rescanLibrary(ref);
                                          }
                                        } else {
                                          openAppSettings();
                                        }
                                      },
                                    ),
                                  ),
                                ] else ...[
                                  Column(
                                    children: [
                                      Icon(Icons.music_off_rounded,
                                          color: theme.primary.withAlpha(100),
                                          size: 64),
                                      const SizedBox(height: 16),
                                      Text(
                                        searchQuery.isNotEmpty
                                            ? AppLocalizations.of(context)!
                                                .noResults
                                            : AppLocalizations.of(context)!
                                                .noSongsFound,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: theme.onSurface
                                                    .withAlpha(120)),
                                      ),
                                      if (isDesktop && searchQuery.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .placeMusicFolder,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: theme.onSurface
                                                      .withAlpha(80)),
                                        ),
                                      ],
                                      if (isMobile && searchQuery.isEmpty) ...[
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.primary,
                                            side: BorderSide(
                                                color: theme.primary
                                                    .withAlpha(80)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14)),
                                          ),
                                          icon: const Icon(Icons.search_rounded,
                                              size: 18),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .refreshLibrary),
                                          onPressed: () =>
                                              _manualRefreshLibrary(
                                                  context, ref),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                _manualRefreshLibrary(context, ref),
                            color: theme.primary,
                            backgroundColor: theme.surface,
                            child: ListView.builder(
                              itemCount: songs.length,
                              padding:
                                  EdgeInsets.only(bottom: isDesktop ? 20 : 100),
                              itemBuilder: (ctx, i) {
                                final song = songs[i];
                                final isPlaying = playingSongId == song.id;
                                final isSelected =
                                    selectedIds.contains(song.id);
                                final isFav = favorites.contains(song.id);

                                return _SongTile(
                                  song: song,
                                  isPlaying: isPlaying,
                                  isSelected: isSelected,
                                  isFav: isFav,
                                  theme: theme,
                                  onTap: () {
                                    if (selectedIds.isNotEmpty) {
                                      final current =
                                          Set<int>.from(selectedIds);
                                      if (current.contains(song.id)) {
                                        current.remove(song.id);
                                      } else {
                                        current.add(song.id);
                                      }
                                      ref
                                          .read(
                                              selectedSongIdsProvider.notifier)
                                          .state = current;
                                    } else {
                                      // Play on first tap; open the full
                                      // player only when tapping the current
                                      // track again.
                                      final isCurrent = ref
                                              .read(audioPlayerProvider)
                                              .currentSong
                                              ?.id ==
                                          song.id;
                                      if (isCurrent) {
                                        ctx.push(AppRoutes.player);
                                      } else {
                                        player.playSong(song,
                                            queue: songs, index: i);
                                      }
                                    }
                                  },
                                  onLongPress: () {
                                    final current = Set<int>.from(selectedIds);
                                    current.add(song.id);
                                    ref
                                        .read(selectedSongIdsProvider.notifier)
                                        .state = current;
                                  },
                                  onFavTap: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggle(song.id),
                                  onOptionsTap: () => SongOptionsModal.show(
                                    context: context,
                                    ref: ref,
                                    song: song,
                                    theme: theme,
                                  ),
                                );
                              },
                            ),
                          ),
                    loading: () => Center(
                        child: CircularProgressIndicator(color: theme.primary)),
                    error: (e, _) => Center(
                      child: Text('${AppLocalizations.of(context)!.error}: $e',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sortLabel(SortOption o, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (o) {
      case SortOption.dateAdded:
        return l.dateAdded;
      case SortOption.title:
        return l.title;
      case SortOption.artist:
        return l.artist;
      case SortOption.duration:
        return l.duration;
      case SortOption.fileType:
        return l.fileType;
    }
  }
}

class _SongTile extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final bool isSelected;
  final bool isFav;
  final dynamic theme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavTap;
  final VoidCallback onOptionsTap;

  const _SongTile({
    required this.song,
    required this.isPlaying,
    required this.isSelected,
    required this.isFav,
    required this.theme,
    required this.onTap,
    required this.onLongPress,
    required this.onFavTap,
    required this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withAlpha(80)
              : Colors.transparent, // Stronger selection color
          border: isSelected
              ? Border.all(
                  color: theme.primary.withAlpha(150),
                  width: 1.5) // Added selection border
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          selected: isSelected,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 20,
            vertical: 2,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Stack(
            children: [
              PlatformArtworkWidget(
                id: song.id,
                path: song.data,
                size: 48,
              ),
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primary.withAlpha(150),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
            ],
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPlaying ? theme.primary : theme.onSurface,
                ),
          ),
          subtitle: Text(
            '${song.artist}  •  ${song.durationFormatted}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.red : theme.onSurface.withAlpha(100),
                  size: 20,
                ),
                onPressed: onFavTap,
              ),
              IconButton(
                icon: Icon(Icons.more_vert_rounded,
                    color: theme.onSurface.withAlpha(120), size: 20),
                onPressed: onOptionsTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rescan helper
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _rescanLibrary(WidgetRef ref) async {
  if (isMobile) {
    // Ask MediaStore to index files added outside the app first.
    await scanMediaStoreForNewFiles();
  }
  ref.invalidate(songLibraryProvider);
  try {
    await ref.read(songLibraryProvider.future);
  } catch (e) {
    debugPrint('Library rescan failed: $e');
  }
}

Future<void> _manualRefreshLibrary(BuildContext context, WidgetRef ref) async {
  // 1. Prune exclusions for files that no longer exist on disk
  await ref.read(customLibraryProvider.notifier).pruneNonExistentExclusions();

  // 2. Index files added outside the app (mobile)
  if (isMobile) {
    await scanMediaStoreForNewFiles();
  }

  // 3. Check if there are any excluded tracks currently present on disk
  final customLib = ref.read(customLibraryProvider);
  if (customLib.excludedFiles.isNotEmpty && context.mounted) {
    final excludedSongsOnDisk =
        await getExcludedSongsOnDevice(customLib.excludedFiles);
    if (excludedSongsOnDisk.isNotEmpty && context.mounted) {
      final songsToRestore =
          await RestoreExcludedSheet.show(context, excludedSongsOnDisk);
      if (songsToRestore != null && songsToRestore.isNotEmpty) {
        await ref.read(customLibraryProvider.notifier).unexcludeFiles(
              songsToRestore.map((s) => s.data),
            );
        if (context.mounted) {
          final l = AppLocalizations.of(context)!;
          AppToast.success(
              context, l.restoredSongsCount(songsToRestore.length));
        }
      }
    }
  }

  // 4. Invalidate and reload songLibraryProvider
  ref.invalidate(songLibraryProvider);
  try {
    await ref.read(songLibraryProvider.future);
  } catch (e) {
    debugPrint('Library rescan failed: $e');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bulk Action Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _bulkRemoveFromLibrary(
    BuildContext context, WidgetRef ref, Set<int> ids) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppLocalizations.of(ctx)!.removeFromLibraryTitle),
      content: Text(AppLocalizations.of(ctx)!.removeFromLibraryMsg),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(AppLocalizations.of(ctx)!.remove,
              style: const TextStyle(color: Colors.orangeAccent)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final allSongsAsync = ref.read(songLibraryProvider);
    allSongsAsync.whenData((allSongs) async {
      int count = 0;
      for (final id in ids) {
        try {
          final song = allSongs.firstWhere((s) => s.id == id);

          // Add to exclusions
          await ref.read(customLibraryProvider.notifier).excludeFile(song.data);

          // Also remove from custom library if it was a single file addition
          await ref.read(customLibraryProvider.notifier).removeFile(song.data);
          count++;
        } catch (e) {
          debugPrint('Failed to exclude song $id: $e');
        }
      }

      ref.read(selectedSongIdsProvider.notifier).state = {};
      ref.invalidate(songLibraryProvider);

      if (context.mounted) {
        AppToast.success(
            context, AppLocalizations.of(context)!.removedItems(count));
      }
    });
  }
}

Future<void> _bulkAddToPlaylist(
    BuildContext context, WidgetRef ref, Set<int> ids) async {
  final playlistsAsync = ref.read(playlistRepositoryProvider);

  playlistsAsync.whenData((playlists) async {
    if (playlists.isEmpty) {
      AppToast.info(context, AppLocalizations.of(context)!.noPlaylistsCreate);
      return;
    }

    final selectedPlaylist = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.addToPlaylist),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(playlists[i].name),
              onTap: () => Navigator.pop(ctx, playlists[i].id),
            ),
          ),
        ),
      ),
    );

    if (selectedPlaylist != null) {
      final playlistName = playlists
          .firstWhere((p) => p.id == selectedPlaylist,
              orElse: () => playlists.first)
          .name;
      // Get the actual songs to add from the library
      final allSongsAsync = ref.read(songLibraryProvider);
      allSongsAsync.whenData((allSongs) async {
        final songsToAdd = allSongs.where((s) => ids.contains(s.id)).toList();
        for (final song in songsToAdd) {
          await ref
              .read(playlistRepositoryProvider.notifier)
              .addSong(selectedPlaylist, song.id);
        }
        ref.read(selectedSongIdsProvider.notifier).state = {};
        if (context.mounted) {
          AppToast.success(
            context,
            AppLocalizations.of(context)!
                .addedSongsToPlaylist(songsToAdd.length, playlistName),
          );
        }
      });
    }
  });
}

Future<void> _bulkDeletePermanently(
    BuildContext context, WidgetRef ref, Set<int> ids) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deleteTitle),
      content: Text(l.deleteMsg),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child:
              Text(l.delete, style: const TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  if (Platform.isAndroid && isMobile) {
    if (!await Permission.audio.isGranted) {
      await Permission.audio.request();
    }
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }
  }

  final allSongsAsync = ref.read(songLibraryProvider);
  allSongsAsync.whenData((allSongs) async {
    int count = 0;
    final player = ref.read(audioPlayerProvider.notifier);
    final playerState = ref.read(audioPlayerProvider);

    for (final id in ids) {
      try {
        final song = allSongs.firstWhere((s) => s.id == id);

        final file = File(song.data);
        bool deleted = false;
        try {
          if (await file.exists()) {
            await file.delete();
            deleted = true;
          }
        } catch (_) {}

        if (!deleted && Platform.isAndroid) {
          try {
            const platform = MethodChannel('com.musiconvert.mp3noads/media');
            final res =
                await platform.invokeMethod('deleteFile', {'path': song.data});
            if (res == true) {
              deleted = true;
            }
          } catch (_) {}
        }

        if (!deleted && await file.exists()) {
          continue;
        }

        await ref.read(customLibraryProvider.notifier).removeFile(song.data);
        await ref.read(customLibraryProvider.notifier).unexcludeFile(song.data);

        if (playerState.currentSong?.id == id) {
          player.stop();
        }
        count++;
      } catch (e) {
        debugPrint('Failed to delete song $id: $e');
      }
    }

    ref.read(selectedSongIdsProvider.notifier).state = {};
    ref.invalidate(songLibraryProvider);

    if (context.mounted) {
      AppToast.success(context, l.deletedItems(count));
    }
  });
}

class _SelectionBar extends ConsumerWidget {
  final Set<int> selectedIds;
  final dynamic theme;

  const _SelectionBar({required this.selectedIds, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 16, vertical: 8),
      color: theme.primary.withAlpha(20),
      child: Row(
        children: [
          Text(
            l.selected(selectedIds.length),
            style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          const SizedBox(width: 16),
          // Add to Playlist Button
          IconButton(
            tooltip: l.addToPlaylist,
            icon: Icon(Icons.playlist_add_rounded, color: theme.primary),
            onPressed: () => _bulkAddToPlaylist(context, ref, selectedIds),
          ),
          // Share Selected Button
          IconButton(
            tooltip: l.share,
            icon: Icon(Icons.share_rounded, color: theme.primary),
            onPressed: () async {
              final allSongsAsync = ref.read(songLibraryProvider);
              allSongsAsync.whenData((allSongs) async {
                final selectedPaths = allSongs
                    .where((s) => selectedIds.contains(s.id))
                    .map((s) => XFile(s.data,
                        mimeType: 'audio/mpeg')) // Specify audio mime types
                    .toList();
                if (selectedPaths.isNotEmpty) {
                  await SharePlus.instance.share(
                    ShareParams(
                      files: selectedPaths,
                      text:
                          '${l.appName}: ${l.songCount(selectedPaths.length)}',
                    ),
                  );
                }
              });
            },
          ),

          // Delete Permanently (visible, not hidden behind the more menu)
          IconButton(
            tooltip: l.deletePermanently,
            icon: const Icon(Icons.delete_forever_rounded,
                color: Colors.redAccent),
            onPressed: () => _bulkDeletePermanently(context, ref, selectedIds),
          ),
          // More Actions Popup
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: theme.primary),
            tooltip: l.moreActions,
            onSelected: (action) {
              if (action == 'remove') {
                _bulkRemoveFromLibrary(context, ref, selectedIds);
              } else if (action == 'delete') {
                _bulkDeletePermanently(context, ref, selectedIds);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    const Icon(Icons.remove_circle_outline_rounded,
                        color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text(l.removeFromLibrary),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever_rounded,
                        color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(l.deletePermanently),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),
          TextButton.icon(
            icon: Icon(Icons.done_all_rounded, color: theme.primary, size: 18),
            label: Text(l.selectAll),
            onPressed: () {
              final songsAsync = ref.read(filteredSongsProvider);
              songsAsync.whenData((songs) {
                ref.read(selectedSongIdsProvider.notifier).state =
                    songs.map((s) => s.id).toSet();
              });
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: Icon(Icons.close_rounded, color: theme.onSurface, size: 18),
            label: Text(l.clear),
            onPressed: () =>
                ref.read(selectedSongIdsProvider.notifier).state = {},
          ),
        ],
      ),
    );
  }
}
