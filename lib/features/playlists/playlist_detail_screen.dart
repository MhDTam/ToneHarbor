import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/artwork_widget.dart';
import '../../core/router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeDataProvider);
    final repo = ref.read(playlistRepositoryProvider.notifier);
    final songsAsync = ref.watch(playlistSongsProvider(playlistId));
    final player = ref.read(audioPlayerProvider.notifier);
    final playlistsAsync = ref.watch(playlistRepositoryProvider);

    // The playlist can be gone (deleted while this screen is open) or the
    // repository may still be loading. `firstWhere(orElse: throw)` used to
    // crash the whole screen in both cases.
    final matching =
        playlistsAsync.valueOrNull?.where((p) => p.id == playlistId) ??
            const [];
    final rawName = matching.isEmpty ? null : matching.first.name;

    final isSystem = rawName == 'system_recently_played';
    final playlistName = rawName == null
        ? AppLocalizations.of(context)!.playlists
        : isSystem
            ? AppLocalizations.of(context)!.recentlyPlayed
            : rawName;

    return Scaffold(
      body: AppBackground(
        theme: theme,
        child: SafeArea(
          top: isMobile,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: theme.onSurface),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(playlistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    // Add songs button
                    if (!isSystem)
                      IconButton(
                        icon: Icon(Icons.add_rounded, color: theme.primary),
                        onPressed: () =>
                            _showAddSongsSheet(context, ref, playlistId),
                      ),
                  ],
                ),
              ),
              // Actions row
              songsAsync.when(
                data: (songs) => songs.isEmpty
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label:
                                    Text(AppLocalizations.of(context)!.playAll),
                                onPressed: () {
                                  player.playSong(songs.first,
                                      queue: songs, index: 0);
                                  context.push(AppRoutes.player);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon:
                                    const Icon(Icons.shuffle_rounded, size: 18),
                                label:
                                    Text(AppLocalizations.of(context)!.shuffle),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.primary,
                                  side: BorderSide(
                                      color: theme.primary.withAlpha(80)),
                                ),
                                onPressed: () {
                                  final shuffled = [...songs]..shuffle();
                                  player.playSong(shuffled.first,
                                      queue: shuffled, index: 0);
                                  final isShuffle =
                                      ref.read(audioPlayerProvider).isShuffle;
                                  if (!isShuffle) {
                                    player.toggleShuffleMode();
                                  }
                                  context.push(AppRoutes.player);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: songsAsync.when(
                  data: (songs) => songs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.library_add_rounded,
                                  color: theme.primary.withAlpha(100),
                                  size: 64),
                              const SizedBox(height: 16),
                              Text(AppLocalizations.of(context)!.noSongsFound,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color:
                                              theme.onSurface.withAlpha(120))),
                              const SizedBox(height: 12),
                              if (!isSystem)
                                ElevatedButton(
                                  onPressed: () => _showAddSongsSheet(
                                      context, ref, playlistId),
                                  child: Text(
                                      AppLocalizations.of(context)!.addSongs),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: songs.length,
                          padding: const EdgeInsets.only(bottom: 100),
                          itemBuilder: (ctx, i) {
                            final song = songs[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 4),
                              leading: PlatformArtworkWidget(
                                id: song.id,
                                path: song.data,
                                size: 48,
                              ),
                              title: Text(song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall),
                              trailing: isSystem
                                  ? null
                                  : IconButton(
                                      icon: Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: Colors.red.withAlpha(180),
                                          size: 22),
                                      onPressed: () =>
                                          repo.removeSong(playlistId, song.id),
                                    ),
                              onTap: () {
                                // Selecting a track starts playback (mini
                                // player). The full player only opens when the
                                // already-playing track is tapped again.
                                final isCurrent = ref
                                        .read(audioPlayerProvider)
                                        .currentSong
                                        ?.id ==
                                    song.id;
                                if (isCurrent) {
                                  ctx.push(AppRoutes.player);
                                } else {
                                  player.playSong(song, queue: songs, index: i);
                                }
                              },
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

  void _showAddSongsSheet(BuildContext ctx, WidgetRef ref, int playlistId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSongsSheet(playlistId: playlistId),
    );
  }
}

class _AddSongsSheet extends ConsumerWidget {
  final int playlistId;
  const _AddSongsSheet({required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeDataProvider);
    final songsAsync = ref.watch(songLibraryProvider);
    final playlistSongs = ref.watch(playlistSongsProvider(playlistId));
    final repo = ref.read(playlistRepositoryProvider.notifier);

    final existingIds =
        (playlistSongs.valueOrNull ?? []).map((s) => s.id).toSet();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.onSurface.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.addSongs,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: songsAsync.when(
              data: (songs) => ListView.builder(
                itemCount: songs.length,
                itemBuilder: (ctx, i) {
                  final song = songs[i];
                  final isAdded = existingIds.contains(song.id);
                  return ListTile(
                    leading: Icon(
                      isAdded
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      color: isAdded
                          ? theme.primary
                          : theme.onSurface.withAlpha(120),
                    ),
                    title: Text(song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text(song.artist,
                        style: Theme.of(context).textTheme.bodySmall),
                    onTap: isAdded
                        ? null
                        : () => repo.addSong(playlistId, song.id),
                  );
                },
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (_, __) =>
                  Center(child: Text(AppLocalizations.of(context)!.error)),
            ),
          ),
        ],
      ),
    );
  }
}
