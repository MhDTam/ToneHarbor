import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../services/audio/audio_player_service.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeDataProvider);
    final favorites = ref.watch(favoritesProvider);
    final songsAsync = ref.watch(songLibraryProvider);
    final playingSongId = ref.watch(
      audioPlayerProvider.select((s) => s.isPlaying ? s.currentSong?.id : null),
    );
    final player = ref.read(audioPlayerProvider.notifier);

    return Scaffold(
      body: AppBackground(
        theme: theme,
        child: SafeArea(
          top: isMobile,
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 28 : 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: theme.onSurface),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.favorites,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: songsAsync.when(
                  data: (songs) {
                    final favSongs =
                        songs.where((s) => favorites.contains(s.id)).toList();

                    if (favSongs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                color: theme.primary.withAlpha(100), size: 64),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context)!.noFavoritesYet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: theme.onSurface.withAlpha(120))),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: favSongs.length,
                      padding: EdgeInsets.only(bottom: isDesktop ? 20 : 100),
                      itemBuilder: (ctx, i) {
                        final song = favSongs[i];
                        final isPlaying = playingSongId == song.id;

                        return ListTile(
                          onTap: () {
                            final isCurrent =
                                ref.read(audioPlayerProvider).currentSong?.id ==
                                    song.id;
                            if (isCurrent) {
                              ctx.push(AppRoutes.player);
                            } else {
                              player.playSong(song, queue: favSongs, index: i);
                            }
                          },
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 28 : 20,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isPlaying
                                  ? theme.primary.withAlpha(30)
                                  : theme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.equalizer_rounded
                                  : Icons.music_note_rounded,
                              color: theme.primary,
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isPlaying
                                      ? theme.primary
                                      : theme.onSurface,
                                ),
                          ),
                          subtitle: Text(song.artist, maxLines: 1),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite_rounded,
                                color: Colors.red, size: 24),
                            onPressed: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(song.id);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, __) =>
                      Center(child: Text(AppLocalizations.of(context)!.error)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
