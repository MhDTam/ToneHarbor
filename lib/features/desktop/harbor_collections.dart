import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';
import 'harbor_custom_images.dart';
import '../../core/utils/harbor_image_memory.dart';

const harborHomeBackdropAsset = 'assets/images/harbor/home-silk-hq-v22.webp';

String harborCollectionAsset(HarborTheme theme, String asset) =>
    theme == HarborTheme.forest
        ? 'assets/images/harbor/$asset.webp'
        : 'assets/images/harbor/themed/${theme.name}-$asset.webp';

/// Each tile is a real local collection. The main action opens that collection;
/// the separate play action uses that exact collection as the playback queue.
class HarborCollections extends ConsumerWidget {
  final List<SongModel> songs;
  final ValueChanged<String> onOpen;
  final ValueChanged<List<SongModel>> onPlay;
  const HarborCollections({
    super.key,
    required this.songs,
    required this.onOpen,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(harborThemeProvider);
    final liked = ref.watch(favoritesProvider);
    final playlists = ref.watch(playlistRepositoryProvider).valueOrNull ?? [];
    final recent = List<SongModel>.of(songs)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final collections = [
      (
        label: 'Recently added',
        action: 'Recently added',
        asset: 'green-studio-v2',
        tracks: recent,
        count: recent.length,
        unit: 'tracks',
      ),
      (
        label: 'Long listens',
        action: 'Long listens',
        asset: 'mountain-listens',
        tracks: recent.where((s) => s.duration >= 180000).toList(),
        count: recent.where((s) => s.duration >= 180000).length,
        unit: 'tracks',
      ),
      (
        label: 'Favorites',
        action: 'Liked Songs',
        asset: 'city-favorites',
        tracks: recent.where((s) => liked.contains(s.id)).toList(),
        count: recent.where((s) => liked.contains(s.id)).length,
        unit: 'tracks',
      ),
      (
        label: 'Playlists',
        action: 'Playlists',
        asset: 'leaves-playlists',
        tracks: <SongModel>[],
        count:
            playlists.where((p) => p.name != 'system_recently_played').length,
        unit: 'playlists',
      ),
    ];
    return LayoutBuilder(builder: (_, size) {
      final imageWidth = harborImageDecodeWidth(
          (size.maxWidth - 36) / 4, MediaQuery.devicePixelRatioOf(context),
          minimum: 160, maximum: 960);
      return Row(children: [
        for (var i = 0; i < collections.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
              child: RepaintBoundary(
                  child: Material(
            key: ValueKey('collection-${collections[i].action}'),
            color: theme.surface,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onOpen(collections[i].action),
              splashFactory: NoSplash.splashFactory,
              child: Stack(fit: StackFit.expand, children: [
                HarborCustomImage(
                    imageKey: 'collection:${collections[i].asset}',
                    cacheWidth: imageWidth,
                    fallback: Image.asset(
                        harborCollectionAsset(theme, collections[i].asset),
                        fit: BoxFit.cover,
                        cacheWidth: imageWidth,
                        filterQuality: FilterQuality.medium,
                        excludeFromSemantics: true)),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [
                      0,
                      .35,
                      1
                    ],
                            colors: [
                      Colors.transparent,
                      Color(0x18000000),
                      Color(0xF0091210)
                    ]))),
                DecoratedBox(
                    decoration: BoxDecoration(
                        border: Border.all(color: theme.accent.withAlpha(35)),
                        borderRadius: BorderRadius.circular(10))),
                PositionedDirectional(
                    start: 12,
                    end: 8,
                    bottom: 10,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                Text(harborText(context, collections[i].label),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                    '${collections[i].count} ${harborText(context, collections[i].unit)}',
                                    style: const TextStyle(
                                        color: Color(0xFFCFDAD4),
                                        fontSize: 12)),
                              ])),
                          const SizedBox(width: 4),
                          SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                  key: ValueKey(
                                      'play-collection-${collections[i].action}'),
                                  tooltip: harborText(
                                      context,
                                      collections[i].action == 'Playlists'
                                          ? 'Open playlists'
                                          : 'Play all'),
                                  style: IconButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor:
                                          theme.surface.withAlpha(220),
                                      side: BorderSide(
                                          color: theme.accent.withAlpha(80))),
                                  onPressed: collections[i].action ==
                                          'Playlists'
                                      ? () => onOpen('Playlists')
                                      : collections[i].tracks.isEmpty
                                          ? null
                                          : () => onPlay(collections[i].tracks),
                                  icon: Icon(
                                      collections[i].action == 'Playlists'
                                          ? Icons.arrow_forward_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 20,
                                      color: Colors.white))),
                        ])),
              ]),
            ),
          ))),
        ],
      ]);
    });
  }
}

/// Reference-matched silk artwork with edges faded into the page background.
/// Static and isolated from playback updates to avoid repainting the header.
class HarborHomeBackdrop extends ConsumerWidget {
  final Widget child;
  const HarborHomeBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(harborThemeProvider);
    final background = theme.background;
    return RepaintBoundary(
      child: Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(builder: (context, bounds) {
              final physicalWidth =
                  bounds.maxWidth * MediaQuery.devicePixelRatioOf(context);
              // Decode to the real display density, without enlarging the
              // original artwork or retaining a new cache entry per pixel.
              final decodeWidth =
                  ((physicalWidth / 128).ceil() * 128).clamp(512, 2172);
              final customWidth =
                  ((physicalWidth / 128).ceil() * 128).clamp(512, 4096);
              return Stack(fit: StackFit.expand, children: [
                HarborCustomImage(
                    imageKey: 'home:header',
                    fit: BoxFit.fill,
                    cacheWidth: customWidth,
                    fallback: Image.asset(
                      harborHomeBackdropAsset,
                      fit: BoxFit.fill,
                      cacheWidth: decodeWidth,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                      color: theme == HarborTheme.forest ? null : theme.accent,
                      colorBlendMode: BlendMode.color,
                    )),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        background,
                        background.withAlpha(0),
                        background.withAlpha(0),
                        background
                      ],
                      stops: const [0, .28, .97, 1],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        background.withAlpha(0),
                        background.withAlpha(0),
                        background
                      ],
                      stops: const [0, .72, 1],
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ),
        child,
      ]),
    );
  }
}
