import 'dart:math' as math;
import '../../core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/artwork_widget.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/song_repository.dart';
import 'harbor_artwork.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../services/audio/audio_player_service.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';
import 'harbor_custom_images.dart';
import '../../data/repositories/artwork_preferences.dart';

class HarborPlaylists extends ConsumerStatefulWidget {
  final int? playlistId;
  const HarborPlaylists({super.key, this.playlistId});

  @override
  ConsumerState<HarborPlaylists> createState() => _HarborPlaylistsState();
}

class _HarborPlaylistsState extends ConsumerState<HarborPlaylists> {
  String _query = '', _trackQuery = '', _sort = 'Date created';
  int? get playlistId => widget.playlistId;

  Future<void> _editName(BuildContext context, WidgetRef ref,
      [PlaylistModel? playlist]) async {
    final controller = TextEditingController(text: playlist?.name ?? '');
    final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(harborText(ctx,
                  playlist == null ? 'Create a playlist' : 'Rename playlist')),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 80,
                  decoration: InputDecoration(
                      hintText: harborText(ctx, 'Give it a name')),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(ctx, value.trim());
                    }
                  }),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(harborText(ctx, 'Cancel'))),
                FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(ctx, controller.text.trim());
                      }
                    },
                    child: Text(harborText(ctx, 'Save')))
              ],
            ));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (name == null) return;
    if (playlist == null) {
      await ref.read(playlistRepositoryProvider.notifier).createPlaylist(name);
    } else {
      await ref
          .read(playlistRepositoryProvider.notifier)
          .renamePlaylist(playlist.id, name);
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, PlaylistModel playlist) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(harborText(ctx, 'Delete playlist')),
              content: Text(
                  '${harborText(ctx, 'Delete this playlist? Your audio files stay on disk.')}\n\n${playlist.name}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(harborText(ctx, 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(harborText(ctx, 'Delete')))
              ],
            ));
    if (ok != true) return;
    await ref
        .read(playlistRepositoryProvider.notifier)
        .deletePlaylist(playlist.id);
    if (context.mounted && playlistId == playlist.id) context.go('/playlists');
  }

  String t(String key) => harborText(context, key);

  Future<void> _play(List<SongModel> songs,
      {SongModel? song, bool shuffle = false}) async {
    if (songs.isEmpty) return;
    final queue = List<SongModel>.of(songs);
    if (shuffle) queue.shuffle();
    final selected = song ?? queue.first;
    try {
      await ref.read(audioPlayerProvider.notifier).playSong(selected,
          queue: queue, index: queue.indexWhere((s) => s.id == selected.id));
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '$e');
      }
    }
  }

  String _duration(List<SongModel> songs) {
    final duration = Duration(
        milliseconds: songs.fold<int>(0, (sum, s) => sum + s.duration));
    return '${duration.inHours > 0 ? '${duration.inHours} ${t('hr')} ' : ''}${duration.inMinutes.remainder(60)} ${t('min')}';
  }

  Future<void> _enqueue(List<SongModel> songs) async {
    await ref.read(audioPlayerProvider.notifier).enqueueSongs(songs);
    if (mounted) {
      AppToast.success(
          context, '${songs.length} ${t('tracks added to queue')}');
    }
  }

  Widget _menu(PlaylistModel playlist, List<SongModel> songs) =>
      PopupMenuButton<String>(
          tooltip: t('Playlist options'),
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (action) {
            switch (action) {
              case 'play':
                _play(songs);
              case 'shuffle':
                _play(songs, shuffle: true);
              case 'queue':
                _enqueue(songs);
              case 'convert':
                context.go('/converter',
                    extra: songs.map((s) => s.data).toList());
              case 'rename':
                _editName(context, ref, playlist);
              case 'picture':
                chooseHarborPicture(context, ref, 'playlist:${playlist.id}');
              case 'resetPicture':
                ref
                    .read(artworkPreferencesProvider.notifier)
                    .reset('playlist:${playlist.id}');
              case 'delete':
                _delete(context, ref, playlist);
            }
          },
          itemBuilder: (_) => [
                for (final entry in [
                  ('play', Icons.play_arrow_rounded, 'Play all'),
                  ('shuffle', Icons.shuffle_rounded, 'Shuffle play'),
                  ('queue', Icons.playlist_add_rounded, 'Add to queue'),
                  ('convert', Icons.sync_rounded, 'Convert audio'),
                ])
                  PopupMenuItem(
                      value: entry.$1,
                      height: 38,
                      enabled: songs.isNotEmpty,
                      child: Row(children: [
                        Icon(entry.$2, size: 18),
                        const SizedBox(width: 12),
                        Text(t(entry.$3))
                      ])),
                const PopupMenuDivider(),
                PopupMenuItem(
                    value: 'picture',
                    height: 38,
                    child: Row(children: [
                      const Icon(Icons.image_outlined, size: 18),
                      const SizedBox(width: 12),
                      Text(t('Change picture'))
                    ])),
                if (ref
                    .read(artworkPreferencesProvider)
                    .containsKey('playlist:${playlist.id}'))
                  PopupMenuItem(
                      value: 'resetPicture',
                      height: 38,
                      child: Text(t('Restore default picture'))),
                PopupMenuItem(
                    value: 'rename',
                    height: 38,
                    child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 12),
                      Text(t('Rename playlist'))
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    height: 38,
                    child: Row(children: [
                      const Icon(Icons.delete_outline,
                          size: 18, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Text(t('Delete playlist'),
                          style: const TextStyle(color: Colors.redAccent))
                    ])),
              ]);

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(harborThemeProvider);
    return ref.watch(playlistRepositoryProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final user =
              all.where((p) => p.name != 'system_recently_played').toList();
          final selected = user.where((p) => p.id == playlistId).firstOrNull;
          if (selected != null) {
            return ref.watch(playlistSongsProvider(selected.id)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (songs) => _detail(selected, songs, palette));
          }
          final library =
              ref.watch(songLibraryProvider).valueOrNull ?? <SongModel>[];
          final byId = {for (final song in library) song.id: song};
          final visible = user
              .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
              .toList()
            ..sort((a, b) => switch (_sort) {
                  'Name' =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  'Track count' => b.songIds.length.compareTo(a.songIds.length),
                  _ => b.createdAt.compareTo(a.createdAt),
                });
          return Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(t('Your collection').toUpperCase(),
                                style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 10,
                                    letterSpacing: 1.8)),
                            const SizedBox(height: 5),
                            Text(t('Your playlists'),
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                                '${user.length} ${t('playlists')} · ${t('Made for your listening')}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ])),
                      FilledButton.icon(
                          onPressed: () => _editName(context, ref),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(t('New Playlist'))),
                    ]),
                    const SizedBox(height: 22),
                    Row(children: [
                      Expanded(
                          child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 260),
                                  child: SizedBox(
                                      height: 38,
                                      child: TextField(
                                          onChanged: (value) =>
                                              setState(() => _query = value),
                                          style: const TextStyle(fontSize: 12),
                                          decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                  Icons.search_rounded,
                                                  size: 18),
                                              hintText: t('Search playlists'),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12))))))),
                      PopupMenuButton<String>(
                          tooltip: t('Sort by'),
                          onSelected: (value) => setState(() => _sort = value),
                          itemBuilder: (_) => [
                                'Date created',
                                'Name',
                                'Track count'
                              ]
                                  .map((value) => CheckedPopupMenuItem(
                                      value: value,
                                      checked: _sort == value,
                                      child: Text(t(value))))
                                  .toList(),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sort_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(t(_sort),
                                        style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.expand_more, size: 16)
                                  ]))),
                    ]),
                    const SizedBox(height: 18),
                    Expanded(
                        child: visible.isEmpty
                            ? Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                    Icon(Icons.library_music_outlined,
                                        size: 52,
                                        color: palette.accent.withAlpha(140)),
                                    const SizedBox(height: 14),
                                    Text(
                                        t(user.isEmpty
                                            ? 'Create a playlist first.'
                                            : 'No matching playlists'),
                                        style: const TextStyle(
                                            color: Colors.white60))
                                  ]))
                            : GridView.builder(
                                key: const ValueKey('playlist-gallery'),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 330,
                                        mainAxisExtent: 258,
                                        mainAxisSpacing: 18,
                                        crossAxisSpacing: 18),
                                itemCount: visible.length,
                                itemBuilder: (_, i) {
                                  final playlist = visible[i];
                                  final songs = playlist.songIds
                                      .map((id) => byId[id])
                                      .whereType<SongModel>()
                                      .toList();
                                  return Material(
                                      key: ValueKey(
                                          'playlist-card-${playlist.id}'),
                                      color: palette.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                          onTap: () => context
                                              .go('/playlists/${playlist.id}'),
                                          hoverColor:
                                              palette.accent.withAlpha(12),
                                          splashFactory: NoSplash.splashFactory,
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                    child: Stack(
                                                        fit: StackFit.expand,
                                                        children: [
                                                      _PlaylistCover(
                                                          playlistId:
                                                              playlist.id,
                                                          songs: songs),
                                                      PositionedDirectional(
                                                          top: 10,
                                                          start: 10,
                                                          child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(7),
                                                              decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .black
                                                                      .withAlpha(
                                                                          145),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8)),
                                                              child: const Icon(
                                                                  Icons
                                                                      .queue_music_rounded,
                                                                  size: 18))),
                                                      PositionedDirectional(
                                                          bottom: 10,
                                                          end: 10,
                                                          child: IconButton.filled(
                                                              tooltip:
                                                                  t('Play all'),
                                                              onPressed: songs
                                                                      .isEmpty
                                                                  ? null
                                                                  : () => _play(
                                                                      songs),
                                                              icon: const Icon(Icons
                                                                  .play_arrow_rounded),
                                                              style: IconButton.styleFrom(
                                                                  backgroundColor:
                                                                      palette
                                                                          .accent,
                                                                  foregroundColor:
                                                                      palette
                                                                          .background))),
                                                    ])),
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        16, 10, 7, 10),
                                                    child: Row(children: [
                                                      Expanded(
                                                          child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                            Text(playlist.name,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)),
                                                            const SizedBox(
                                                                height: 5),
                                                            Text(
                                                                '${playlist.songIds.length} ${t('tracks')}${songs.isEmpty ? '' : ' · ${_duration(songs)}'}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .white60)),
                                                          ])),
                                                      _menu(playlist, songs),
                                                    ])),
                                              ])));
                                })),
                  ]));
        });
  }

  Widget _detail(
      PlaylistModel playlist, List<SongModel> songs, HarborTheme palette) {
    final tracks = songs
        .where((s) => '${s.title} ${s.artist} ${s.album}'
            .toLowerCase()
            .contains(_trackQuery.toLowerCase()))
        .toList();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                    onPressed: () => context.go('/playlists'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(t('Your playlists')))),
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.accent.withAlpha(22))),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                          width: wide ? 142 : 108,
                          height: wide ? 142 : 108,
                          child: _PlaylistCover(
                              playlistId: playlist.id, songs: songs))),
                  const SizedBox(width: 22),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(t('PLAYLIST'),
                            style: TextStyle(
                                color: palette.accent,
                                letterSpacing: 1.6,
                                fontSize: 10)),
                        const SizedBox(height: 9),
                        Text(playlist.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: wide ? 32 : 25,
                                height: 1.15,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text(
                            '${songs.length} ${t('tracks')} · ${_duration(songs)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white60)),
                      ])),
                  _menu(playlist, songs),
                ])),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  FilledButton.icon(
                      onPressed: songs.isEmpty ? null : () => _play(songs),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(t('Play all'))),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                      tooltip: t('Shuffle play'),
                      onPressed: songs.isEmpty
                          ? null
                          : () => _play(songs, shuffle: true),
                      icon: const Icon(Icons.shuffle_rounded, size: 19)),
                  const SizedBox(width: 8),
                  IconButton(
                      tooltip: t('Add to queue'),
                      onPressed: songs.isEmpty ? null : () => _enqueue(songs),
                      icon: const Icon(Icons.playlist_add_rounded, size: 21)),
                  const Spacer(),
                  SizedBox(
                      width: wide ? 230 : 155,
                      height: 36,
                      child: TextField(
                          onChanged: (value) =>
                              setState(() => _trackQuery = value),
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                              hintText: t('Search tracks'),
                              prefixIcon:
                                  const Icon(Icons.search_rounded, size: 17),
                              contentPadding: EdgeInsets.zero))),
                ])),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12))),
                child: Row(children: [
                  const SizedBox(
                      width: 30,
                      child: Text('#',
                          style:
                              TextStyle(fontSize: 11, color: Colors.white54))),
                  const SizedBox(width: 52),
                  Expanded(
                      flex: 5,
                      child: Text(t('Title'),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white54))),
                  if (wide) ...[
                    Expanded(
                        flex: 2,
                        child: Text(t('Artist'),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white54))),
                    Expanded(
                        flex: 2,
                        child: Text(t('Album'),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white54))),
                  ],
                  const SizedBox(
                      width: 55,
                      child: Icon(Icons.schedule_rounded,
                          size: 15, color: Colors.white54)),
                  const SizedBox(width: 38),
                ])),
            Expanded(
                child: tracks.isEmpty
                    ? Center(
                        child: Text(
                            t(songs.isEmpty
                                ? 'Add songs from your library to this playlist.'
                                : 'No matching tracks'),
                            style: const TextStyle(color: Colors.white60)))
                    : ListView.builder(
                        itemExtent: 64,
                        itemCount: tracks.length,
                        itemBuilder: (_, i) {
                          final song = tracks[i];
                          return Consumer(builder: (_, rowRef, __) {
                            final active = rowRef.watch(audioPlayerProvider
                                .select((p) => p.currentSong?.id == song.id));
                            return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Material(
                                    key: ValueKey('playlist-track-${song.id}'),
                                    color: active
                                        ? palette.accent.withAlpha(18)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                        onTap: () => _play(songs, song: song),
                                        splashFactory: NoSplash.splashFactory,
                                        hoverColor: palette.accent.withAlpha(9),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Row(children: [
                                              SizedBox(
                                                  width: 30,
                                                  child: active
                                                      ? Icon(Icons.graphic_eq,
                                                          size: 17,
                                                          color: palette.accent)
                                                      : Text(
                                                          '${songs.indexOf(song) + 1}',
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white54))),
                                              PlatformArtworkWidget(
                                                  id: song.id,
                                                  path: song.data,
                                                  size: 40,
                                                  nullArtworkWidget: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                          color: palette.accent
                                                              .withAlpha(20),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7)),
                                                      child: Icon(
                                                          Icons
                                                              .music_note_rounded,
                                                          size: 19,
                                                          color:
                                                              palette.accent))),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  flex: 5,
                                                  child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(song.title,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: active
                                                                    ? palette
                                                                        .accent
                                                                    : Colors
                                                                        .white)),
                                                        if (!wide)
                                                          Text(song.artist,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .white60)),
                                                      ])),
                                              if (wide) ...[
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(song.artist,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .white60))),
                                                Expanded(
                                                    flex: 2,
                                                    child: Text(song.album,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .white60))),
                                              ],
                                              SizedBox(
                                                  width: 55,
                                                  child: Text(
                                                      song.durationFormatted,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.white60))),
                                              SizedBox(
                                                  width: 38,
                                                  child: IconButton(
                                                      tooltip: t(
                                                          'Remove from playlist'),
                                                      onPressed: () => ref
                                                          .read(
                                                              playlistRepositoryProvider
                                                                  .notifier)
                                                          .removeSong(
                                                              playlist.id,
                                                              song.id),
                                                      icon: const Icon(
                                                          Icons
                                                              .remove_circle_outline_rounded,
                                                          size: 17))),
                                            ])))));
                          });
                        })),
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    '${tracks.length} ${t('tracks')} · ${_duration(tracks)}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11))),
          ]));
    });
  }
}

class _PlaylistCover extends StatelessWidget {
  final int playlistId;
  final List<SongModel> songs;
  const _PlaylistCover({required this.playlistId, required this.songs});
  @override
  Widget build(BuildContext context) =>
      ClipRect(child: LayoutBuilder(builder: (_, box) {
        final side = math.max(box.maxWidth, box.maxHeight);
        return OverflowBox(
            maxWidth: side,
            maxHeight: side,
            child: HarborCustomImage(
                imageKey: 'playlist:$playlistId',
                width: side,
                height: side,
                fallback: HarborArtwork(size: side, playlist: true)));
      }));
}
