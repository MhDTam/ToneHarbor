import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/app_icons.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/playlist_repository.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeDataProvider);
    final playlistsAsync = ref.watch(playlistRepositoryProvider);
    final repo = ref.read(playlistRepositoryProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: AppBackground(
        theme: theme,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.playlists,
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.add_rounded,
                          color: theme.primary, size: 28),
                      onPressed: () => _showCreateDialog(context, repo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: playlistsAsync.when(
                  data: (playlists) => playlists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(AppIcons.queueMusic,
                                  color: theme.primary.withAlpha(100),
                                  size: 64),
                              const SizedBox(height: 16),
                              Text(AppLocalizations.of(context)!.noPlaylists,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color:
                                              theme.onSurface.withAlpha(120))),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: Text(AppLocalizations.of(context)!
                                    .createPlaylist),
                                onPressed: () =>
                                    _showCreateDialog(context, repo),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: playlists.length,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemBuilder: (ctx, i) {
                            final p = playlists[i];
                            final isSystem = p.name == 'system_recently_played';
                            final displayName = isSystem
                                ? AppLocalizations.of(ctx)!.recentlyPlayed
                                : p.name;

                            return _PlaylistCard(
                              playlist: p,
                              displayName: displayName,
                              isSystem: isSystem,
                              theme: theme,
                              onTap: () => ctx.push('/playlists/${p.id}'),
                              onRename: isSystem
                                  ? null
                                  : () => _showRenameDialog(ctx, repo, p),
                              onDelete: isSystem
                                  ? null
                                  : () => _showDeleteDialog(ctx, repo, p),
                            );
                          },
                        ),
                  loading: () => Center(
                      child: CircularProgressIndicator(color: theme.primary)),
                  error: (_, __) =>
                      Center(child: Text(AppLocalizations.of(context)!.error)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(
      BuildContext ctx, PlaylistRepositoryNotifier repo) async {
    final controller = TextEditingController();
    await showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.createPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              InputDecoration(hintText: AppLocalizations.of(ctx)!.playlistName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppLocalizations.of(ctx)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final name = controller.text.trim();
                Navigator.pop(dialogCtx);
                repo.createPlaylist(name);
              }
            },
            child: Text(AppLocalizations.of(ctx)!.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext ctx,
      PlaylistRepositoryNotifier repo, PlaylistModel pl) async {
    final controller = TextEditingController(text: pl.name);
    await showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.renamePlaylist),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppLocalizations.of(ctx)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newName = controller.text.trim();
                Navigator.pop(dialogCtx);
                repo.renamePlaylist(pl.id, newName);
              }
            },
            child: Text(AppLocalizations.of(ctx)!.rename),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext ctx,
      PlaylistRepositoryNotifier repo, PlaylistModel pl) async {
    await showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.deletePlaylist),
        content: Text(AppLocalizations.of(ctx)!.deleteConfirmMessage(pl.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppLocalizations.of(ctx)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogCtx);
              repo.deletePlaylist(pl.id);
            },
            child: Text(AppLocalizations.of(ctx)!.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final String displayName;
  final bool isSystem;
  final dynamic theme;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const _PlaylistCard({
    required this.playlist,
    required this.displayName,
    required this.isSystem,
    required this.theme,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primary.withAlpha(80)),
              ),
              child: Icon(
                  isSystem ? Icons.history_rounded : AppIcons.queueMusic,
                  color: theme.primary,
                  size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                      AppLocalizations.of(context)!
                          .songCount(playlist.songIds.length),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (!isSystem)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: theme.onSurface.withAlpha(120)),
                onSelected: (v) {
                  if (v == 'rename') onRename?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'rename',
                      child: Text(AppLocalizations.of(context)!.rename)),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(AppLocalizations.of(context)!.delete)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
