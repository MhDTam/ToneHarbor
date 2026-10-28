import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:share_plus/share_plus.dart';
import 'app_toast.dart';
import 'app_icons.dart';
import 'file_naming.dart';
import '../../core/router.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/repositories/custom_library_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../l10n/app_localizations.dart';

class SongOptionsModal {
  /// Reuse the existing guarded file actions from desktop context menus.
  static void performDesktopAction(
      String action, BuildContext context, WidgetRef ref, SongModel song) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, ref, song);
      case 'remove':
        _showRemoveFromLibraryDialog(context, ref, song);
      case 'delete':
        _showDeletePermanentlyDialog(context, ref, song);
      case 'folder':
        _showInFolder(song);
      case 'metadata':
        context.push(AppRoutes.metadataEditor, extra: song);
      case 'edit':
        context.push(AppRoutes.editor, extra: song);
    }
  }

  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required SongModel song,
    required dynamic theme,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    ref.watch(favoritesProvider).contains(song.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: theme.primary,
                  ),
                  title: Text(ref.watch(favoritesProvider).contains(song.id)
                      ? l.removeFromFavorites
                      : l.addToFavorites),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(favoritesProvider.notifier).toggle(song.id);
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.playlist_add_rounded, color: theme.primary),
                  title: Text(l.addToPlaylist),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPlaylistSelection(context, ref, song, theme);
                  },
                ),
                if (isMobile)
                  ListTile(
                    leading: Icon(Icons.share_rounded, color: theme.primary),
                    title: Text(l.share),
                    onTap: () {
                      Navigator.pop(ctx);
                      _shareSong(song, context);
                    },
                  ),
                if (isMobile)
                  ListTile(
                    leading:
                        Icon(Icons.ring_volume_rounded, color: theme.primary),
                    title: Text(l.setAsRingtone),
                    onTap: () {
                      Navigator.pop(ctx);
                      _setAsRingtone(context, song);
                    },
                  ),
                ListTile(
                  leading:
                      Icon(Icons.edit_note_rounded, color: theme.onSurface),
                  title: Text(l.editInfoTitleArt),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.metadataEditor, extra: song);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: theme.onSurface),
                  title: Text(l.renameSong),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameDialog(context, ref, song);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.tune_rounded, color: theme.primary),
                  title: Text(l.editAudioTrim8D),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.editor, extra: song);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline_rounded,
                      color: Colors.orangeAccent),
                  title: Text(l.removeFromLibrary,
                      style: const TextStyle(color: Colors.orangeAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRemoveFromLibraryDialog(context, ref, song);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent),
                  title: Text(l.deletePermanently,
                      style: const TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeletePermanentlyDialog(context, ref, song);
                  },
                ),
                if (isDesktop)
                  ListTile(
                    leading:
                        Icon(Icons.folder_open_rounded, color: theme.primary),
                    title: Text(l.showInFolder),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showInFolder(song);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _setAsRingtone(
      BuildContext context, SongModel song) async {
    final l = AppLocalizations.of(context)!;
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.musiconvert.mp3noads/media');
        await platform.invokeMethod('setRingtone', {'path': song.data});
        if (context.mounted) {
          AppToast.success(context, l.ringtoneSetSuccess);
        }
      } else {
        AppToast.error(context, l.notSupportedPlatform);
      }
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'PERMISSION_NEEDED') {
        AppToast.error(context, l.permissionWriteSettings);
      } else {
        AppToast.error(context, e.message ?? l.ringtoneFailed);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, e.toString());
      }
    }
  }

  static void _shareSong(SongModel song, BuildContext context) {
    if (isMobile) {
      final l = AppLocalizations.of(context)!;
      try {
        SharePlus.instance.share(
          ShareParams(
              files: [XFile(song.data)], text: '${l.appName}: ${song.title}'),
        );
      } catch (e) {
        debugPrint('Sharing failed: $e');
      }
    }
  }

  static void _showInFolder(SongModel song) {
    if (Platform.isWindows) {
      // `/select,` and the path must be a single argument for Explorer to
      // actually highlight the file.
      Process.run('explorer.exe', ['/select,${song.data}']);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', song.data]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [File(song.data).parent.path]);
    }
  }

  static void _showPlaylistSelection(
      BuildContext context, WidgetRef ref, SongModel song, dynamic theme) {
    final playlistsAsync = ref.read(playlistRepositoryProvider);
    final playlists = playlistsAsync.valueOrNull ?? [];
    final l = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.addToPlaylist,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (playlists.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l.noPlaylistsCreate))
            else
              ...playlists.map((p) => ListTile(
                    leading: const Icon(AppIcons.queueMusic),
                    title: Text(p.name),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final repo =
                          ref.read(playlistRepositoryProvider.notifier);
                      if (!p.songIds.contains(song.id)) {
                        await repo.addSong(p.id, song.id);
                        if (context.mounted) {
                          AppToast.success(context, l.addedToPlaylist(p.name));
                        }
                      } else {
                        if (context.mounted) {
                          AppToast.info(context, l.alreadyInPlaylist);
                        }
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  static void _showRenameDialog(
      BuildContext context, WidgetRef ref, SongModel song) {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: song.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.renameSong),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.enterNewName,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              final newName = sanitizeFileName(ctrl.text);
              if (newName.isNotEmpty && newName != song.title) {
                Navigator.pop(ctx);

                // Keep the source container (a .flac must not become .mp3).
                final finalName = resolveRenamedFileName(song.data, newName);
                if (finalName == p.basename(song.data)) return;

                if (isDesktop) {
                  try {
                    final file = File(song.data);
                    final newPath = p.join(file.parent.path, finalName);
                    if (await File(newPath).exists()) {
                      if (context.mounted) {
                        AppToast.error(
                            context, '${l.renameFailed}: $finalName');
                      }
                      return;
                    }
                    await file.rename(newPath);
                    ref.invalidate(songLibraryProvider);
                    if (context.mounted) {
                      AppToast.success(context, l.songRenamed);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(context, '${l.renameFailed}: $e');
                    }
                  }
                } else {
                  try {
                    _renameViaMobile(song, finalName, context, ref);
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(context, '${l.renameFailed}: $e');
                    }
                  }
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  static Future<void> _renameViaMobile(SongModel song, String finalName,
      BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    try {
      if (Platform.isAndroid) {
        if (!await Permission.audio.isGranted) {
          await Permission.audio.request();
        }
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
      }

      final file = File(song.data);
      final dir = file.parent;
      final newPath = p.join(dir.path, finalName);
      final baseName = finalName.replaceAll(RegExp(r'\.[^.]+$'), '');

      bool diskRenamed = false;
      String actualPath = song.data;

      // 1. Try direct file rename on disk
      try {
        if (await file.exists()) {
          final renamed = await file.rename(newPath);
          diskRenamed = true;
          actualPath = renamed.path;
        }
      } catch (e) {
        debugPrint('Direct file rename not permitted by Scoped Storage: $e');
      }

      // 2. If direct rename failed on Android, try native MediaStore rename
      if (!diskRenamed && Platform.isAndroid) {
        try {
          const platform = MethodChannel('com.musiconvert.mp3noads/media');
          final nativePath = await platform.invokeMethod<String>('renameFile', {
            'oldPath': song.data,
            'newName': finalName,
          });
          if (nativePath != null && nativePath.isNotEmpty) {
            diskRenamed = true;
            actualPath = nativePath;
          }
        } catch (e) {
          debugPrint('Native rename via MediaStore failed: $e');
        }
      }

      // 3. Save custom title in app preferences so MusiConvert always displays the new name
      await ref
          .read(customLibraryProvider.notifier)
          .setSongTitle(song.data, baseName);
      if (actualPath != song.data) {
        await ref
            .read(customLibraryProvider.notifier)
            .setSongTitle(actualPath, baseName);
      }

      // 4. Request MediaStore rescan
      try {
        final onAudioQuery = OnAudioQuery();
        await onAudioQuery.scanMedia(song.data);
        if (actualPath != song.data) {
          await onAudioQuery.scanMedia(actualPath);
        }
      } catch (e) {
        debugPrint('MediaStore scan error: $e');
      }

      ref.invalidate(songLibraryProvider);

      if (context.mounted) {
        AppToast.success(context, l.songRenamed);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '${l.renameFailed}: $e');
      }
    }
  }

  static void _showRemoveFromLibraryDialog(
      BuildContext context, WidgetRef ref, SongModel song) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.removeFromLibraryTitle),
        content: Text(l.removeFromLibraryMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(customLibraryProvider.notifier)
                  .excludeFile(song.data);
              if (!isDesktop) {
                await ref
                    .read(customLibraryProvider.notifier)
                    .removeFile(song.data);
              }
              ref.invalidate(songLibraryProvider);
              if (context.mounted) {
                AppToast.success(context, l.songRemoved);
              }
            },
            child: Text(l.remove,
                style: const TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  static void _showDeletePermanentlyDialog(
      BuildContext context, WidgetRef ref, SongModel song) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTitle),
        content: Text(l.deleteMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              if (Platform.isAndroid && isMobile) {
                if (!await Permission.audio.isGranted) {
                  await Permission.audio.request();
                }
                if (!await Permission.storage.isGranted) {
                  await Permission.storage.request();
                }
              }

              try {
                final file = File(song.data);
                bool deletedFromDisk = false;
                try {
                  if (await file.exists()) {
                    await file.delete();
                    deletedFromDisk = true;
                  }
                } catch (e) {
                  debugPrint('Direct delete not permitted: $e');
                }

                if (!deletedFromDisk && Platform.isAndroid) {
                  try {
                    const platform =
                        MethodChannel('com.musiconvert.mp3noads/media');
                    final res = await platform
                        .invokeMethod('deleteFile', {'path': song.data});
                    if (res == true) {
                      deletedFromDisk = true;
                    }
                  } catch (e) {
                    debugPrint('Native delete failed: $e');
                  }
                }

                if (!deletedFromDisk && await file.exists()) {
                  if (context.mounted) {
                    AppToast.error(context, l.deleteFailed);
                  }
                  return;
                }

                // Clean up references from custom library (never exclude, so re-downloading works)
                await ref
                    .read(customLibraryProvider.notifier)
                    .removeFile(song.data);
                await ref
                    .read(customLibraryProvider.notifier)
                    .unexcludeFile(song.data);
                ref.invalidate(songLibraryProvider);

                final player = ref.read(audioPlayerProvider.notifier);
                final playerState = ref.read(audioPlayerProvider);
                if (playerState.currentSong?.id == song.id) {
                  player.stop();
                }

                if (context.mounted) {
                  AppToast.success(context, l.songDeleted);
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(context, '${l.deleteFailed}: $e');
                }
              }
            },
            child:
                Text(l.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
