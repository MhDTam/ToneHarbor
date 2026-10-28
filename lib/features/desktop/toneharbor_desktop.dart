import 'dart:math' as math;
import 'dart:io';
import '../../data/repositories/artwork_preferences.dart';
import 'harbor_custom_images.dart';
import 'harbor_track_list.dart';
import 'harbor_collections.dart';
import 'harbor_entrance.dart';
import 'harbor_library_sort.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/router.dart';
import '../../core/utils/artwork_widget.dart';
import '../../core/utils/song_options_modal.dart';
import '../../data/models/song_model.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/custom_library_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/overlay_mode_provider.dart';
import '../library/widgets/restore_excluded_sheet.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';
import 'harbor_navigation.dart';
import 'harbor_brand.dart';
import 'harbor_artwork.dart';
import 'harbor_waveform.dart';
import 'harbor_listening_room.dart';
import 'harbor_folders.dart';
import 'harbor_playback_clock.dart';
import 'harbor_window_frame.dart';
import 'harbor_repeat_button.dart';
import 'harbor_track_menu.dart';
import '../../core/utils/app_toast.dart';
import '../../services/audio/sleep_timer_service.dart';

const harborGreen = Color(0xFF7CE791);
const harborMuted = Color(0xFFAFBDC5);
const harborBackground = Color(0xFF0B1413);
const harborSurface = Color(0xFF101918);
const harborBorder = Color(0xFF25352E);

final Map<(HarborTheme, TargetPlatform), ThemeData> _harborThemes = {};
ThemeData buildHarborTheme([HarborTheme theme = harborDefaultTheme]) =>
    _harborThemes.putIfAbsent(
        (theme, defaultTargetPlatform),
        () => ThemeData(
              useMaterial3: true,
              popupMenuTheme: PopupMenuThemeData(
                  color: theme.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 4,
                  shadowColor: const Color(0x44000000),
                  menuPadding: const EdgeInsets.all(5),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) =>
                      TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 12,
                          color: states.contains(WidgetState.disabled)
                              ? const Color(0xFF60717A)
                              : const Color(0xFFE2EBEF))),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.border))),
              brightness: Brightness.dark,
              fontFamily: 'Segoe UI',
              scaffoldBackgroundColor: theme.background,
              colorScheme: ColorScheme.dark(
                  primary: theme.accent,
                  secondary: theme.accent,
                  surface: theme.surface,
                  onPrimary: theme.background),
              dividerColor: theme.border,
              dividerTheme: DividerThemeData(color: theme.border, thickness: 1),
              scrollbarTheme: ScrollbarThemeData(
                  thickness: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.dragged)
                          ? 6
                          : states.contains(WidgetState.hovered)
                              ? 5
                              : 3),
                  thumbColor: WidgetStateProperty.resolveWith((states) => theme
                      .accent
                      .withAlpha(states.contains(WidgetState.dragged)
                          ? 200
                          : states.contains(WidgetState.hovered)
                              ? 145
                              : 65)),
                  thumbVisibility: const WidgetStatePropertyAll(true),
                  trackVisibility: const WidgetStatePropertyAll(false),
                  trackColor: const WidgetStatePropertyAll(Colors.transparent),
                  trackBorderColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                  radius: const Radius.circular(4),
                  minThumbLength: 48,
                  crossAxisMargin: 3,
                  mainAxisMargin: 5),
              sliderTheme: SliderThemeData(
                  trackHeight: 5,
                  activeTrackColor: theme.accent,
                  inactiveTrackColor:
                      Color.lerp(theme.background, Colors.white, .28),
                  disabledActiveTrackColor: Colors.white24,
                  disabledInactiveTrackColor: Colors.white12,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12)),
              inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: theme.input,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none)),
            ));

/// Windows presentation shares the original library, playlists and audio engine.
class ToneHarborDesktop extends ConsumerStatefulWidget {
  final Widget child;
  const ToneHarborDesktop({super.key, required this.child});
  @override
  ConsumerState<ToneHarborDesktop> createState() => _ToneHarborDesktopState();
}

class _ToneHarborDesktopState extends ConsumerState<ToneHarborDesktop> {
  final _search = TextEditingController();
  String _collection = 'All', _tab = 'All';
  bool _queueOpen = true, _recentSortOverride = false;
  String? _group;
  Color get _accent => ref.read(harborThemeProvider).accent;
  final Set<int> _selected = {};
  bool _selectionMode = false;
  int? _selectionAnchor;
  Object? _filteredKey;
  List<SongModel> _filteredSongs = const [];
  String t(String key) => harborText(context, key);
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _import({bool folder = false}) async {
    try {
      final library = ref.read(customLibraryProvider.notifier);
      if (folder) {
        final path = await FilePicker.platform
            .getDirectoryPath(dialogTitle: 'Add a music folder');
        if (path != null) await library.addFolder(path);
      } else {
        final files = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.custom,
            allowedExtensions: [
              'mp3',
              'wav',
              'flac',
              'm4a',
              'aac',
              'ogg',
              'opus',
              'wma'
            ]);
        if (files != null) {
          await library.addFiles(
              files.files.map((file) => file.path).whereType<String>());
        }
      }
      ref.invalidate(songLibraryProvider);
    } catch (e) {
      _error('Could not import music: $e');
    }
  }

  void _error(String message) {
    if (mounted) {
      AppToast.error(context, message);
    }
  }

  Future<void> _play(SongModel song, List<SongModel> songs) async {
    try {
      await ref
          .read(audioPlayerProvider.notifier)
          .playSong(song, queue: songs, index: songs.indexOf(song));
    } catch (e) {
      _error('Could not play this file: $e');
    }
  }

  void _select(String collection) {
    setState(() {
      _collection = collection;
      _recentSortOverride = false;
      _group = null;
      _tab = collection == 'All' ? 'All' : 'Songs';
      _search.clear();
      _selected.clear();
      _selectionMode = false;
      _selectionAnchor = null;
    });
    context.go(AppRoutes.library);
  }

  Future<void> _refreshLibrary() async {
    try {
      final excluded = ref.read(customLibraryProvider).excludedFiles;
      final found = await getExcludedSongsOnDevice(excluded);
      if (!mounted) return;
      if (found.isNotEmpty) {
        final restored = await RestoreExcludedSheet.show(context, found);
        if (!mounted) return;
        if (restored != null) {
          await ref
              .read(customLibraryProvider.notifier)
              .addFiles(restored.map((song) => song.data));
        }
      }
      ref.invalidate(songLibraryProvider);
      await ref.read(songLibraryProvider.future);
    } catch (e) {
      _error('$e');
    }
  }

  void _selectSong(SongModel song, List<SongModel> songs, int index) {
    final keyboard = HardwareKeyboard.instance;
    setState(() {
      _selectionMode = true;
      if (keyboard.isShiftPressed &&
          _selectionAnchor != null &&
          _selectionAnchor! < songs.length) {
        final first = math.min(index, _selectionAnchor!);
        final last = math.max(index, _selectionAnchor!);
        _selected.addAll(songs.sublist(first, last + 1).map((s) => s.id));
      } else {
        if (!_selected.add(song.id)) _selected.remove(song.id);
        _selectionAnchor = index;
      }
    });
  }

  Future<void> _addToPlaylist(List<SongModel> songs) async {
    final playlists = (ref.read(playlistRepositoryProvider).valueOrNull ?? [])
        .where((p) => p.name != 'system_recently_played')
        .toList();
    final id = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(t('Add to playlist')),
              content: SizedBox(
                  width: 390,
                  child: playlists.isEmpty
                      ? Text(t('Create a playlist first.'))
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: playlists.length,
                              itemBuilder: (_, i) => ListTile(
                                  leading: const Icon(Icons.queue_music),
                                  title: Text(playlists[i].name),
                                  subtitle: Text(
                                      '${playlists[i].songIds.length} ${t('tracks')}'),
                                  onTap: () =>
                                      Navigator.pop(ctx, playlists[i].id))))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t('Cancel')))
              ],
            ));
    if (id != null && mounted) {
      try {
        await ref
            .read(playlistRepositoryProvider.notifier)
            .addSongs(id, songs.map((s) => s.id));
        if (mounted) {
          setState(() {
            _selected.clear();
            _selectionMode = false;
          });
        }
      } catch (e) {
        _error('$e');
      }
    }
  }

  Future<void> _removeSelected(List<SongModel> songs) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(t('Remove from library')),
              content: Text(
                  '${t('Remove selected tracks from your library? Their files stay on disk.')} (${songs.length})'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(t('Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(t('Remove')))
              ],
            ));
    if (confirmed != true || !mounted) return;
    try {
      final library = ref.read(customLibraryProvider.notifier);
      await library.excludeFiles(songs.map((song) => song.data));
      ref.invalidate(songLibraryProvider);
      if (mounted) {
        setState(() {
          _selected.clear();
          _selectionMode = false;
        });
      }
    } catch (e) {
      _error('$e');
    }
  }

  Future<void> _deleteOriginals(List<SongModel> songs) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(t('Delete permanently')),
              content: Text(
                  '${songs.length} ${t('tracks')}\n${t('This deletes the original files from your device.')}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(t('Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(t('Delete permanently'))),
              ],
            ));
    if (confirmed != true || !mounted) return;
    final removed = <String>[], failed = <String>[];
    final current = ref.read(audioPlayerProvider).currentSong;
    if (current != null && songs.any((song) => song.data == current.data)) {
      await ref.read(audioPlayerProvider.notifier).stop();
    }
    for (final song in songs) {
      try {
        final file = File(song.data);
        if (await file.exists()) await file.delete();
        removed.add(song.data);
      } catch (_) {
        failed.add(song.title);
      }
    }
    if (removed.isNotEmpty) {
      await ref.read(customLibraryProvider.notifier).excludeFiles(removed);
      ref.invalidate(songLibraryProvider);
    }
    if (!mounted) return;
    setState(() {
      _selected.removeWhere((id) =>
          songs.any((song) => song.id == id && removed.contains(song.data)));
      _selectionMode = _selected.isNotEmpty;
    });
    if (failed.isNotEmpty) {
      _error('${t('Could not delete files')}: ${failed.join(', ')}');
    }
  }

  Widget _songMenuButton(SongModel song, {bool horizontal = false}) => Builder(
      builder: (anchor) => IconButton(
          tooltip: t('Song options'),
          padding: EdgeInsets.zero,
          onPressed: () => _openSongMenu(song, anchor: anchor),
          icon: Icon(horizontal ? Icons.more_horiz : Icons.more_vert,
              size: horizontal ? 20 : 18, color: harborMuted)));

  Future<void> _openSongMenu(SongModel song,
      {Offset? position, BuildContext? anchor}) async {
    final box = anchor?.findRenderObject() as RenderBox?;
    final point =
        position ?? box?.localToGlobal(Offset(0, box.size.height + 4));
    if (point == null) return;
    final choice = await showHarborTrackMenu(context,
        globalPosition: point,
        song: song,
        liked: ref.read(favoritesProvider).contains(song.id),
        customPicture: ref
            .read(artworkPreferencesProvider)
            .containsKey(trackPictureKey(song.data)));
    if (choice != null && mounted) _songAction(choice, song);
  }

  void _songAction(String action, SongModel song) {
    switch (action) {
      case 'picture':
        chooseHarborPicture(context, ref, trackPictureKey(song.data));
      case 'resetPicture':
        ref
            .read(artworkPreferencesProvider.notifier)
            .reset(trackPictureKey(song.data));
      case 'play':
        _play(song, [song]);
      case 'next':
        _enqueue([song], next: true);
      case 'queue':
        _enqueue([song]);
      case 'favorite':
        ref.read(favoritesProvider.notifier).toggle(song.id);
      case 'playlist':
        _addToPlaylist([song]);
      case 'convert':
        _convertSongs([song]);
      case 'copy':
        _copyPaths([song]);
      case 'details':
        _songDetails(song);
      case 'select':
        final libraryPage = GoRouterState.of(context).uri.path == '/library';
        setState(() {
          if (!libraryPage) {
            _collection = 'All';
            _tab = 'Songs';
            _group = null;
            _search.clear();
          }
          _selectionMode = true;
          _selected.add(song.id);
        });
        if (!libraryPage) context.go(AppRoutes.library);
      default:
        SongOptionsModal.performDesktopAction(action, context, ref, song);
    }
  }

  void _songDetails(SongModel song) {
    final file = song.data.replaceAll('\\', '/').split('/').last;
    final date = DateTime.fromMillisecondsSinceEpoch(song.dateAdded * 1000)
        .toLocal()
        .toString()
        .split(' ')
        .first;
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(t('Track details')),
              content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final entry in {
                      'Title': song.title,
                      'Artist': song.artist,
                      'Album': song.album,
                      'Duration': song.durationFormatted,
                      'File type': file.split('.').last.toUpperCase(),
                      'File name': file,
                      'Date added': date,
                      'File path': song.data
                    }.entries)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 95,
                                    child: Text(t(entry.key),
                                        style: const TextStyle(
                                            fontSize: 12, color: harborMuted))),
                                Expanded(
                                    child: SelectableText(entry.value,
                                        style: const TextStyle(fontSize: 12))),
                              ])),
                  ]))),
              actions: [
                TextButton.icon(
                    onPressed: () => _copyPaths([song]),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(t('Copy file path'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t('Close')))
              ],
            ));
  }

  Future<void> _rightClickSong(
      TapDownDetails details, SongModel song, bool liked) async {
    await _openSongMenu(song, position: details.globalPosition);
  }

  Future<void> _newPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(t('Create a playlist')),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 80,
                  decoration: InputDecoration(hintText: t('Give it a name')),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
                  }),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t('Cancel'))),
                FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(ctx, controller.text.trim());
                      }
                    },
                    child: Text(t('Create')))
              ],
            ));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (name != null && mounted) {
      try {
        await ref
            .read(playlistRepositoryProvider.notifier)
            .createPlaylist(name);
        if (mounted) context.go(AppRoutes.playlists);
      } catch (e) {
        _error('Could not create playlist: $e');
      }
    }
  }

  List<SongModel> _filtered(List<SongModel> all) {
    final preferences = ref.watch(harborLibrarySortProvider);
    final settings = _collection == 'Recently Played' && !_recentSortOverride
        ? const HarborSortSettings(
            mode: HarborSort.recentlyPlayed, ascending: true)
        : preferences;
    final favorites = _collection == 'Liked Songs'
        ? ref.watch(favoritesProvider)
        : const <int>{};
    final playlists = _collection == 'Recently Played' ||
            settings.mode == HarborSort.recentlyPlayed
        ? ref.watch(playlistRepositoryProvider).valueOrNull ?? []
        : <PlaylistModel>[];
    final recentIds = playlists
        .where((p) => p.name == 'system_recently_played')
        .expand((p) => p.songIds)
        .take(10)
        .toList();
    final q = _search.text.trim().toLowerCase();
    final key = (
      all,
      settings.mode,
      settings.ascending,
      _collection,
      _tab,
      _group,
      q,
      favorites,
      recentIds.join(',')
    );
    if (_filteredKey == key) return _filteredSongs;
    final songs = all.where((s) {
      if (_collection == 'Liked Songs' && !favorites.contains(s.id)) {
        return false;
      }
      if (_collection == 'Recently Played' && !recentIds.contains(s.id)) {
        return false;
      }
      if (_collection == 'Long listens' && s.duration < 180000) return false;
      if (q.isNotEmpty &&
          !'${s.title} ${s.artist} ${s.album}'.toLowerCase().contains(q)) {
        return false;
      }
      if (_group != null && _groupFor(s) != _group) return false;
      return true;
    }).toList();
    _filteredKey = key;
    return _filteredSongs =
        sortHarborSongs(songs, settings, recentIds: recentIds);
  }

  String _groupFor(SongModel s) => switch (_tab) {
        'Albums' => s.album,
        'Artists' => s.artist,
        'Folders' => harborFolderPath(s),
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final libraryPage = location == '/library';
    final library = ref.watch(songLibraryProvider);
    final all = library.valueOrNull ?? [];
    if (!libraryPage) {
      // A departed library page must not pin an old catalogue and sorted copy.
      _filteredKey = null;
      _filteredSongs = const [];
    }
    final songs = libraryPage ? _filtered(all) : const <SongModel>[];
    final palette = ref.watch(harborThemeProvider);
    return Theme(
        data: buildHarborTheme(palette),
        child: HarborWindowFrame(
            child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(color: palette.background),
            child: LayoutBuilder(builder: (context, size) {
              final wide = size.maxWidth >= 1250 &&
                  _queueOpen &&
                  location != AppRoutes.desktopPlayer &&
                  location != AppRoutes.settings &&
                  location != AppRoutes.editing &&
                  location != AppRoutes.editor &&
                  location != AppRoutes.converter;
              final compact = size.maxWidth < 1000;
              return Column(children: [
                Expanded(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      _sidebar(location, compact),
                      Expanded(
                          child: Column(children: [
                        _topbar(),
                        Expanded(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              Expanded(
                                  child: HarborContentWidth(
                                      maxWidth: location == AppRoutes.settings
                                          ? 1600
                                          : 2200,
                                      child: HarborEntrance(
                                          trigger: location,
                                          child: location == '/'
                                              ? _home(all)
                                              : location ==
                                                      AppRoutes.desktopPlayer
                                                  ? Consumer(builder:
                                                      (_, playerRef, __) {
                                                      playerRef.watch(
                                                          audioPlayerProvider
                                                              .select(
                                                                  harborPlaybackLayout));
                                                      return _fullPlayer(
                                                          playerRef.read(
                                                              audioPlayerProvider));
                                                    })
                                                  : libraryPage
                                                      ? _library(
                                                          library, all, songs)
                                                      : ClipRect(
                                                          child:
                                                              widget.child)))),
                              if (wide)
                                SizedBox(
                                    width: (size.maxWidth * .27)
                                        .clamp(350.0, 480.0),
                                    child:
                                        Consumer(builder: (_, playerRef, __) {
                                      playerRef.watch(audioPlayerProvider
                                          .select(harborPlaybackLayout));
                                      return _nowPlaying(
                                          playerRef.read(audioPlayerProvider));
                                    })),
                            ]))
                      ])),
                    ])),
                if (location != AppRoutes.desktopPlayer)
                  Consumer(builder: (_, playerRef, __) {
                    playerRef.watch(
                        audioPlayerProvider.select(harborPlaybackLayout));
                    return _bottomPlayer(
                        playerRef.read(audioPlayerProvider), compact);
                  })
              ]);
            }),
          ),
        )));
  }

  Widget _sidebar(String location, bool compact) =>
      Consumer(builder: (context, sidebarRef, _) {
        final library = location == '/library';
        final palette = sidebarRef.watch(harborThemeProvider);
        return Container(
            width: compact ? 184 : 222,
            decoration: BoxDecoration(
                color: palette.sidebar,
                border: Border(right: BorderSide(color: palette.border))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                      height: 82,
                      child: DragToMoveArea(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Row(children: [
                                const HarborBrandMark(),
                                const SizedBox(width: 9),
                                Expanded(
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text('ToneHarbor',
                                            style: TextStyle(
                                                fontSize: compact ? 19 : 23,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -.8))))
                              ])))),
                  Expanded(
                      child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          children: [
                        _nav(Icons.home_rounded, 'Home', location == '/', () {
                          setState(() {
                            _collection = 'All';
                            _tab = 'All';
                            _search.clear();
                            _group = null;
                          });
                          context.go('/');
                        }),
                        _nav(
                            Icons.music_note_rounded,
                            'Library',
                            library && _collection == 'All',
                            () => _select('All')),
                        _nav(
                            Icons.queue_music_rounded,
                            'Playlists',
                            location.startsWith('/playlists'),
                            () => context.go(AppRoutes.playlists)),
                        _nav(
                            Icons.graphic_eq,
                            'Audio Editor',
                            location.startsWith('/editing'),
                            () => context.go(AppRoutes.editing)),
                        _nav(
                            Icons.sync_rounded,
                            'Converter',
                            location == '/converter',
                            () => context.go(AppRoutes.converter)),
                        const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 17),
                            child: Divider(height: 1)),
                        _section('YOUR MUSIC'),
                        _nav(
                            Icons.favorite_rounded,
                            'Liked Songs',
                            library && _collection == 'Liked Songs',
                            () => _select('Liked Songs')),
                        _nav(
                            Icons.history_rounded,
                            'Recently Played',
                            library && _collection == 'Recently Played',
                            () => _select('Recently Played')),
                        _nav(Icons.folder_outlined, 'Music Folders', false, () {
                          _select('All');
                          setState(() => _tab = 'Folders');
                        }),
                        const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 17),
                            child: Divider(height: 1)),
                        _section('MADE BY YOU'),
                        ...?(sidebarRef
                            .watch(playlistRepositoryProvider)
                            .valueOrNull
                            ?.where((p) => p.name != 'system_recently_played')
                            .take(6)
                            .map((p) => _nav(
                                Icons.playlist_play_rounded,
                                p.name,
                                location == '/playlists/${p.id}',
                                () => context.go('/playlists/${p.id}')))),
                      ])),
                  Padding(
                      padding: const EdgeInsets.all(17),
                      child: OutlinedButton.icon(
                          onPressed: _newPlaylist,
                          icon: const Icon(Icons.add, size: 19),
                          label: Text(t('New Playlist')),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: harborMuted,
                              side: BorderSide(color: palette.border),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))))),
                ]));
      });

  Widget _section(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(13, 0, 0, 10),
      child: Text(t(text),
          style: const TextStyle(
              color: Color(0xFF6D837A),
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600)));
  Widget _nav(IconData icon, String text, bool active, VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    height: 43,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        gradient: active
                            ? LinearGradient(colors: [
                                ref
                                    .read(harborThemeProvider)
                                    .accent
                                    .withAlpha(36),
                                ref
                                    .read(harborThemeProvider)
                                    .accent
                                    .withAlpha(82)
                              ])
                            : null,
                        border: Border.all(
                            color: active
                                ? ref
                                    .read(harborThemeProvider)
                                    .accent
                                    .withAlpha(100)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(9)),
                    child: Row(children: [
                      Icon(icon,
                          size: 20,
                          color: active
                              ? ref.read(harborThemeProvider).accent
                              : harborMuted),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Text(t(text),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: active
                                      ? ref.read(harborThemeProvider).accent
                                      : harborMuted,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400)))
                    ]),
                  ))));

  Widget _topbar() => LayoutBuilder(builder: (context, constraints) {
        final labels = constraints.maxWidth >= 900;
        return SizedBox(
            height: 74,
            child: Row(children: [
              const SizedBox(width: 6),
              HarborBackButton(
                  localBack: GoRouterState.of(context).uri.path == '/library' &&
                          (_group != null ||
                              _collection != 'All' ||
                              _tab != 'All' ||
                              _search.text.isNotEmpty)
                      ? () => setState(() {
                            if (_group != null) {
                              _group = null;
                            } else {
                              _collection = 'All';
                              _tab = 'All';
                              _search.clear();
                            }
                            _selected.clear();
                            _selectionMode = false;
                            _selectionAnchor = null;
                          })
                      : null),
              const SizedBox(width: 8),
              SizedBox(
                  width: math.min(
                      300,
                      math.max(
                          140, constraints.maxWidth - (labels ? 478 : 390))),
                  height: 36,
                  child: TextField(
                      controller: _search,
                      onChanged: (_) {
                        setState(() {});
                        if (GoRouterState.of(context).uri.path != '/library') {
                          context.go('/library');
                        }
                      },
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: harborMuted, size: 20),
                          hintText: t('Search songs, artists, albums...'),
                          hintStyle:
                              const TextStyle(color: harborMuted, fontSize: 12),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8)))),
              Expanded(
                  child: GestureDetector(
                      key: const ValueKey('window-drag-area'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) => windowManager.startDragging(),
                      onDoubleTap: _maximize,
                      child: const SizedBox(height: 56))),
              _toolbarMenu('Add music', Icons.add_rounded, labels, (choice) {
                if (choice == 'files') _import();
                if (choice == 'folder') _import(folder: true);
              }, [
                _menuEntry(
                    'files', Icons.audio_file_outlined, 'Add music files'),
                _menuEntry('folder', Icons.create_new_folder_outlined,
                    'Add music folder'),
              ]),
              _icon(Icons.picture_in_picture_alt_rounded, 'Mini player',
                  () => OverlayModeManager.enableOverlay(ref, context),
                  size: 20),
              _icon(Icons.refresh_rounded, 'Refresh library', _refreshLibrary,
                  size: 20),
              _icon(Icons.settings_outlined, 'Settings',
                  () => context.push(AppRoutes.settings),
                  size: 20),
              const SizedBox(width: 10),
              const SizedBox(height: 22, child: VerticalDivider(width: 1)),
              const SizedBox(width: 8),
              _icon(Icons.remove, 'Minimize', () => windowManager.minimize(),
                  size: 16),
              _icon(Icons.crop_square_rounded, 'Maximize / restore', _maximize,
                  size: 15),
              _icon(Icons.close, 'Close', () => windowManager.close(),
                  size: 17),
              const SizedBox(width: 6),
            ]));
      });

  Future<void> _maximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  PopupMenuItem<String> _menuEntry(String value, IconData icon, String title) =>
      PopupMenuItem(
          value: value,
          child: Row(children: [
            Icon(icon, size: 18, color: harborMuted),
            const SizedBox(width: 12),
            Text(t(title), style: const TextStyle(fontSize: 13))
          ]));

  Widget _toolbarMenu(
          String title,
          IconData icon,
          bool label,
          ValueChanged<String> onSelected,
          List<PopupMenuEntry<String>> items) =>
      PopupMenuButton<String>(
        tooltip: t(title),
        onSelected: onSelected,
        itemBuilder: (_) => items,
        position: PopupMenuPosition.under,
        child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: label ? 12 : 10, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20, color: harborMuted),
              if (label) ...[
                const SizedBox(width: 7),
                Text(t(title),
                    style: const TextStyle(fontSize: 12, color: harborMuted)),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded,
                    size: 15, color: harborMuted)
              ]
            ])),
      );
  Widget _timerButton() {
    final active =
        ref.watch(sleepTimerProvider.select((value) => value.isActive));
    return PopupMenuButton<int>(
      tooltip: t('Sleep timer'),
      icon: Icon(Icons.timer_outlined,
          size: 20,
          color: active ? ref.read(harborThemeProvider).accent : harborMuted),
      onSelected: (value) async {
        final timer = ref.read(sleepTimerProvider.notifier);
        if (value == 0) {
          timer.cancel();
          return;
        }
        if (ref.read(audioPlayerProvider).currentSong == null) return;
        await timer.startTimer(
            mode: value == -1
                ? SleepTimerMode.trackEndLock
                : value == -2
                    ? SleepTimerMode.playlistEndLock
                    : SleepTimerMode.timeEndLock,
            minutes: value > 0 ? value : 15);
      },
      itemBuilder: (_) => [
        for (final minutes in [15, 30, 45, 60, 90])
          PopupMenuItem(
              value: minutes, child: Text('$minutes ${t('minutes')}')),
        const PopupMenuDivider(),
        PopupMenuItem(value: -1, child: Text(t('Stop after current track'))),
        PopupMenuItem(value: -2, child: Text(t('Stop after playlist'))),
        if (active) PopupMenuItem(value: 0, child: Text(t('Cancel timer'))),
      ],
    );
  }

  Widget _speedButton(PlayerState player) => PopupMenuButton<double>(
        tooltip: t('Playback speed'),
        onSelected: (speed) =>
            ref.read(audioPlayerProvider.notifier).setSpeed(speed),
        itemBuilder: (_) => [
          for (final speed in [.5, .75, 1.0, 1.25, 1.5, 2.0])
            PopupMenuItem(
                value: speed,
                child: Row(children: [
                  Expanded(child: Text('$speed×')),
                  if ((player.playbackSpeed - speed).abs() < .001)
                    const Icon(Icons.check, size: 18)
                ]))
        ],
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text('${player.playbackSpeed.toStringAsFixed(2)}×',
                style: const TextStyle(color: harborMuted, fontSize: 12))),
      );

  Widget _home(List<SongModel> all) {
    final lists = ref.watch(playlistRepositoryProvider).valueOrNull ?? [];
    final byId = {for (final song in all) song.id: song};
    final recent = lists
        .where((p) => p.name == 'system_recently_played')
        .expand((p) => p.songIds)
        .take(10)
        .map((id) => byId[id])
        .whereType<SongModel>()
        .toList();
    final newest = List<SongModel>.of(all)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final resume = recent.firstOrNull ?? newest.firstOrNull;
    final theme = ref.read(harborThemeProvider);

    return SingleChildScrollView(
      key: const ValueKey('home-dashboard'),
      padding: const EdgeInsets.fromLTRB(26, 0, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HarborHomeBackdrop(
          key: const ValueKey('home-listening-header'),
          child: SizedBox(
            height: 128,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('Home'),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.7)),
                      const SizedBox(height: 6),
                      Text(t('Welcome back'),
                          style: const TextStyle(
                              color: harborMuted, fontSize: 13)),
                      const SizedBox(height: 12),
                      Text(
                          '${all.length} ${t('tracks')} · ${t('Stored on your device')}',
                          style: const TextStyle(
                              color: harborMuted, fontSize: 11)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _select('All'),
                  icon: const Icon(Icons.library_music_outlined, size: 17),
                  label: Text(t('Open library')),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 164,
          child: HarborCollections(
            key: const ValueKey('home-collections'),
            songs: all,
            onOpen: _openCollection,
            onPlay: (queue) => _play(queue.first, queue),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          key: const ValueKey('home-resume'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
          ),
          child: Row(children: [
            _art(resume, 76),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      t(recent.isEmpty
                              ? 'Start listening'
                              : 'Continue listening')
                          .toUpperCase(),
                      style: TextStyle(
                          color: theme.accent,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(resume?.title ?? t('Your listening space'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      resume?.artist ??
                          t('Add audio files or a folder to start listening.'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: harborMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              key: const ValueKey('home-resume-play'),
              onPressed: resume == null
                  ? () => _import()
                  : () => _play(resume, recent.isEmpty ? newest : recent),
              icon: Icon(
                  resume == null ? Icons.add_rounded : Icons.play_arrow_rounded,
                  size: 20),
              label: Text(t(resume == null ? 'Add music' : 'Play now')),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final panels = [
            _homeTracks(
                'Recently played', recent, () => _select('Recently Played')),
            _homeTracks('Recently added', newest.take(8).toList(),
                () => _openCollection('Recently added')),
          ];
          return constraints.maxWidth >= 760
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: panels[0]),
                  const SizedBox(width: 20),
                  Expanded(child: panels[1]),
                ])
              : Column(
                  children: [panels[0], const SizedBox(height: 20), panels[1]]);
        }),
      ]),
    );
  }

  Widget _homeTracks(
          String title, List<SongModel> songs, VoidCallback action) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(t(title),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600))),
          IconButton(
              tooltip: t('See all'),
              onPressed: action,
              icon: const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: harborMuted))
        ]),
        const Divider(height: 12),
        if (songs.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(t('No recent tracks yet.'),
                  style: const TextStyle(color: harborMuted, fontSize: 12)))
        else
          ...songs.asMap().entries.map((entry) => SizedBox(
              height: 49,
              child: _songRow(entry.value, songs, entry.key, small: true))),
      ]);
  Widget _fullPlayer(PlayerState player) => HarborListeningRoom(
      player: player,
      artwork: (size) => _art(player.currentSong, size, playback: true),
      transport: _transport(player, large: true),
      progress: _progress(player),
      timer: _timerButton(),
      speed: _speedButton(player),
      options: (song) => _songMenuButton(song, horizontal: true),
      onPlay: (song) => _play(song, player.queue));
  void _openCollection(String collection) {
    if (collection == 'Playlists') {
      context.go(AppRoutes.playlists);
    } else if (collection == 'Recently added') {
      _select('All');
      _chooseSort(HarborSort.dateAdded, ascending: false);
    } else {
      _select(collection);
    }
  }

  Widget _library(AsyncValue<List<SongModel>> library, List<SongModel> all,
          List<SongModel> songs) =>
      LayoutBuilder(builder: (context, constraints) {
        return Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 22, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                SizedBox(
                    height: 80,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    t(_collection == 'All'
                                        ? 'Library'
                                        : _collection),
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.7)),
                                const SizedBox(height: 5),
                                Text(
                                    '${songs.length} ${t('tracks')} · ${t('Stored on your device')}',
                                    style: const TextStyle(
                                        color: harborMuted, fontSize: 13)),
                              ])),
                        ]))),
                SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: Row(children: [
                      Expanded(
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                  children: [
                                'All',
                                'Songs',
                                'Albums',
                                'Artists',
                                'Folders'
                              ].map((tab) {
                                final active = _tab == tab;
                                return InkWell(
                                    onTap: () => setState(() {
                                          _tab = tab;
                                          _group = null;
                                          _selected.clear();
                                          _selectionMode = false;
                                          _selectionAnchor = null;
                                        }),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18),
                                      decoration: BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: active
                                                      ? _accent
                                                      : Colors.transparent,
                                                  width: 2))),
                                      child: Text(t(tab),
                                          style: TextStyle(
                                              color: active
                                                  ? _accent
                                                  : harborMuted,
                                              fontSize: 12,
                                              fontWeight: active
                                                  ? FontWeight.w600
                                                  : FontWeight.w400)),
                                    ));
                              }).toList()))),
                    ])),
              ]),
              const SizedBox(height: 8),
              if (_group != null)
                Row(children: [
                  TextButton.icon(
                      onPressed: () => setState(() => _group = null),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(t('Back'))),
                  Expanded(
                      child: Text(_group!, overflow: TextOverflow.ellipsis))
                ]),
              if (_tab == 'All' || _tab == 'Songs' || _group != null)
                _selectionToolbar(songs),
              if (['Albums', 'Artists'].contains(_tab) && _group == null)
                Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _sortButton()),
              if (['Albums', 'Artists', 'Folders'].contains(_tab) &&
                  _group == null)
                Expanded(child: _groups(songs))
              else ...[
                SizedBox(
                    height: 35,
                    child: Row(children: [
                      const SizedBox(width: 12),
                      if (_selectionMode)
                        SizedBox(
                            width: 36,
                            child: Checkbox(
                              key: const ValueKey('select-all-tracks'),
                              tristate: true,
                              value: songs.isEmpty ||
                                      !songs
                                          .any((s) => _selected.contains(s.id))
                                  ? false
                                  : songs.every((s) => _selected.contains(s.id))
                                      ? true
                                      : null,
                              onChanged: songs.isEmpty
                                  ? null
                                  : (_) => setState(() {
                                        _selectionMode = true;
                                        if (songs.every(
                                            (s) => _selected.contains(s.id))) {
                                          _selected.clear();
                                        } else {
                                          _selected
                                              .addAll(songs.map((s) => s.id));
                                        }
                                      }),
                            )),
                      const SizedBox(
                          width: 28,
                          child: Text('#',
                              style:
                                  TextStyle(color: harborMuted, fontSize: 11))),
                      const SizedBox(width: 52),
                      Expanded(
                          flex: 5,
                          child: InkWell(
                              onTap: () => _chooseSort(HarborSort.title,
                                  reverseIfSame: true),
                              child: Row(children: [
                                Text(t('Title'),
                                    style: const TextStyle(
                                        color: harborMuted, fontSize: 13)),
                              ]))),
                      Expanded(
                          flex: 2,
                          child: Text(t('Artist'),
                              style: const TextStyle(
                                  color: harborMuted, fontSize: 11))),
                      const SizedBox(
                          width: 55,
                          child: Icon(Icons.schedule,
                              size: 15, color: harborMuted)),
                      const SizedBox(width: 69),
                    ])),
                const Divider(height: 1),
                Expanded(
                    child: library.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (e, _) => _empty(
                            'Could not load your library',
                            '$e',
                            Icons.error_outline,
                            () => ref.invalidate(songLibraryProvider),
                            'Try again'),
                        data: (_) => songs.isEmpty
                            ? _empty(
                                _search.text.isNotEmpty
                                    ? 'No matching tracks'
                                    : 'Make room for your music.',
                                _search.text.isNotEmpty
                                    ? 'Try a different song, artist or album.'
                                    : 'Add audio files or a folder to start listening.',
                                Icons.library_music_outlined,
                                () => _import(),
                                'Add music')
                            : HarborTrackList(
                                songs: songs,
                                selectionMode: _selectionMode,
                                selected: _selected,
                                onSelection: (ids, anchor) => setState(() {
                                      _selectionMode = true;
                                      _selected.clear();
                                      _selected.addAll(ids);
                                      _selectionAnchor = anchor;
                                    }),
                                onCancelSelection: _cancelSelection,
                                rowBuilder: (song, index) =>
                                    _songRow(song, songs, index)))),
              ],
              const SizedBox(height: 12),
            ]));
      });

  HarborSortSettings get _sortSettings =>
      _collection == 'Recently Played' && !_recentSortOverride
          ? const HarborSortSettings(
              mode: HarborSort.recentlyPlayed, ascending: true)
          : ref.read(harborLibrarySortProvider);

  void _chooseSort(HarborSort mode,
      {bool reverseIfSame = false, bool? ascending}) {
    final current = _sortSettings;
    setState(() {
      _recentSortOverride = true;
      _selectionAnchor = null;
    });
    ref.read(harborLibrarySortProvider.notifier).set(
        mode,
        ascending ??
            (reverseIfSame && current.mode == mode
                ? !current.ascending
                : mode.defaultAscending));
  }

  Widget _sortButton() => PopupMenuButton<String>(
        tooltip: t('Sort by'),
        position: PopupMenuPosition.under,
        onSelected: (value) {
          if (value.startsWith('mode:')) {
            _chooseSort(HarborSort.values.byName(value.substring(5)));
          } else {
            _chooseSort(_sortSettings.mode, ascending: value == 'ascending');
          }
        },
        itemBuilder: (_) => [
          for (final mode in HarborSort.values)
            PopupMenuItem(
                value: 'mode:${mode.name}',
                height: 36,
                child: Row(children: [
                  Expanded(
                      child: Text(t(mode.label),
                          style: const TextStyle(fontSize: 12))),
                  if (_sortSettings.mode == mode)
                    Icon(Icons.check_rounded, color: _accent, size: 17),
                ])),
          const PopupMenuDivider(),
          for (final ascending in [true, false])
            PopupMenuItem(
                value: ascending ? 'ascending' : 'descending',
                height: 36,
                child: Row(children: [
                  Icon(
                      ascending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: harborMuted),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(t(ascending ? 'Ascending' : 'Descending'),
                          style: const TextStyle(fontSize: 12))),
                  if (_sortSettings.ascending == ascending)
                    Icon(Icons.check_rounded, color: _accent, size: 17),
                ])),
        ],
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.sort_rounded, size: 18, color: harborMuted),
              const SizedBox(width: 7),
              Text('${t('Sort by')}: ${t(_sortSettings.mode.label)}',
                  style: const TextStyle(color: harborMuted, fontSize: 11)),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, size: 15, color: harborMuted),
            ])),
      );

  void _cancelSelection() => setState(() {
        _selectionMode = false;
        _selected.clear();
        _selectionAnchor = null;
      });

  void _selectAll(List<SongModel> songs) => setState(() {
        _selectionMode = true;
        _selected.addAll(songs.map((song) => song.id));
      });

  void _invertSelection(List<SongModel> songs) => setState(() {
        final ids = songs
            .where((song) => !_selected.contains(song.id))
            .map((song) => song.id)
            .toSet();
        _selected.clear();
        _selected.addAll(ids);
        _selectionMode = true;
      });

  void _convertSongs(List<SongModel> songs) {
    if (songs.isNotEmpty) {
      context.go(AppRoutes.converter,
          extra: songs.map((song) => song.data).toList());
    }
  }

  Future<void> _enqueue(List<SongModel> songs, {bool next = false}) async {
    try {
      await ref
          .read(audioPlayerProvider.notifier)
          .enqueueSongs(songs, next: next);
      if (mounted) {
        AppToast.success(
            context, '${songs.length} ${t('tracks added to queue')}');
      }
    } catch (e) {
      _error('$e');
    }
  }

  Future<void> _copyPaths(List<SongModel> songs) async {
    await Clipboard.setData(
        ClipboardData(text: songs.map((song) => song.data).join('\n')));
    if (mounted) AppToast.success(context, t('File paths copied'));
  }

  Widget _selectionToolbar(List<SongModel> songs) {
    final chosen = songs.where((song) => _selected.contains(song.id)).toList();
    if (!_selectionMode) {
      return SizedBox(
          height: 60,
          child: Row(children: [
            TextButton.icon(
                onPressed: () => setState(() => _selectionMode = true),
                icon: const Icon(Icons.checklist_rounded, size: 17),
                label: Text(t('Select tracks'),
                    style: const TextStyle(fontSize: 12))),
            if (songs.isNotEmpty)
              _icon(Icons.play_arrow_rounded, 'Play all',
                  () => _play(songs.first, songs),
                  size: 20, width: 32),
            const Spacer(),
            _sortButton(),
          ]));
    }
    PopupMenuItem<String> action(String value, IconData icon, String label,
            {bool enabled = true, bool danger = false}) =>
        PopupMenuItem(
            value: value,
            height: 36,
            enabled: enabled,
            child: Row(children: [
              Icon(icon,
                  size: 17, color: danger ? Colors.orangeAccent : harborMuted),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(t(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: danger ? Colors.orangeAccent : null))),
            ]));
    return SizedBox(
        height: 60,
        child: LayoutBuilder(
            builder: (context, size) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      color: ref.read(harborThemeProvider).surface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.white12)),
                  child: Row(children: [
                    _icon(Icons.close_rounded, 'Cancel selection',
                        _cancelSelection,
                        size: 17, width: 30),
                    const SizedBox(width: 5),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: _accent.withAlpha(20),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${chosen.length} ${t('selected')}',
                            style: TextStyle(
                                color: _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    if (size.maxWidth >= 720)
                      TextButton(
                          onPressed: () => _selectAll(songs),
                          child: Text(t('Select all'),
                              style: const TextStyle(fontSize: 11))),
                    const Spacer(),
                    FilledButton.icon(
                        onPressed: chosen.isEmpty
                            ? null
                            : () => _play(chosen.first, chosen),
                        style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12)),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(t('Play selected'),
                            style: const TextStyle(fontSize: 11))),
                    const SizedBox(width: 8),
                    const SizedBox(
                        height: 20, child: VerticalDivider(width: 12)),
                    IconButton(
                        tooltip: t('Add to playlist'),
                        onPressed: chosen.isEmpty
                            ? null
                            : () => _addToPlaylist(chosen),
                        icon: const Icon(Icons.playlist_add_rounded, size: 20)),
                    IconButton(
                        tooltip: t('Convert selected'),
                        onPressed:
                            chosen.isEmpty ? null : () => _convertSongs(chosen),
                        icon: const Icon(Icons.sync_rounded, size: 19)),
                    PopupMenuButton<String>(
                      tooltip: t('Delete tracks'),
                      enabled: chosen.isNotEmpty,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onSelected: (action) {
                        if (action == 'library') _removeSelected(chosen);
                        if (action == 'original') _deleteOriginals(chosen);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'library',
                            child: Text(t('Remove from library'))),
                        PopupMenuItem(
                            value: 'original',
                            child: Text(t('Delete permanently'),
                                style:
                                    const TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                    PopupMenuButton<String>(
                      tooltip: t('Selection actions'),
                      position: PopupMenuPosition.under,
                      icon: const Icon(Icons.more_horiz_rounded,
                          color: harborMuted),
                      onSelected: (value) {
                        switch (value) {
                          case 'next':
                            _enqueue(chosen, next: true);
                          case 'queue':
                            _enqueue(chosen);
                          case 'shuffle':
                            final queue = List<SongModel>.of(chosen)..shuffle();
                            if (queue.isNotEmpty) _play(queue.first, queue);
                          case 'favorite':
                            ref
                                .read(favoritesProvider.notifier)
                                .setMany(chosen.map((s) => s.id), true);
                          case 'unfavorite':
                            ref
                                .read(favoritesProvider.notifier)
                                .setMany(chosen.map((s) => s.id), false);
                          case 'copy':
                            _copyPaths(chosen);
                          case 'invert':
                            _invertSelection(songs);
                          case 'all':
                            _selectAll(songs);
                          case 'clear':
                            setState(() => _selected.clear());
                          case 'remove':
                            _removeSelected(chosen);
                        }
                      },
                      itemBuilder: (_) => [
                        action('next', Icons.playlist_play_rounded, 'Play next',
                            enabled: chosen.isNotEmpty),
                        action(
                            'queue', Icons.queue_music_rounded, 'Add to queue',
                            enabled: chosen.isNotEmpty),
                        action('shuffle', Icons.shuffle_rounded,
                            'Shuffle selected',
                            enabled: chosen.isNotEmpty),
                        const PopupMenuDivider(),
                        action('favorite', Icons.favorite_outline_rounded,
                            'Add to favorites',
                            enabled: chosen.isNotEmpty),
                        action('unfavorite', Icons.heart_broken_outlined,
                            'Remove from favorites',
                            enabled: chosen.isNotEmpty),
                        action('copy', Icons.copy_rounded, 'Copy file paths',
                            enabled: chosen.isNotEmpty),
                        const PopupMenuDivider(),
                        action('all', Icons.select_all_rounded, 'Select all'),
                        action('invert', Icons.flip_to_front_rounded,
                            'Invert selection'),
                        action(
                            'clear', Icons.deselect_rounded, 'Clear selection'),
                        const PopupMenuDivider(),
                        action('remove', Icons.remove_circle_outline,
                            'Remove from library',
                            enabled: chosen.isNotEmpty, danger: true),
                      ],
                    ),
                  ]),
                )));
  }

  Widget _groups(List<SongModel> songs) {
    final groups = <String, List<SongModel>>{};
    for (final song in songs) {
      (groups[_groupFor(song)] ??= []).add(song);
    }
    if (groups.isEmpty) {
      return _empty(
          'Your music belongs here',
          'Add a folder to discover your collection.',
          Icons.folder_open,
          () => _import(folder: true),
          'Add folder');
    }
    final keys = groups.keys.toList()..sort();
    if (_tab == 'Folders') {
      return HarborFolders(
          folders: groups,
          onOpen: (path) => setState(() => _group = path),
          onPlay: (queue) => _play(queue.first, queue),
          onAdd: () => _import(folder: true));
    }
    return GridView.builder(
        padding: const EdgeInsets.only(top: 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 210,
            mainAxisExtent: 105,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12),
        itemCount: keys.length,
        itemBuilder: (_, i) => Material(
            color: ref.read(harborThemeProvider).surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _group = keys[i]),
                child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              _tab == 'Folders'
                                  ? Icons.folder_outlined
                                  : _tab == 'Artists'
                                      ? Icons.person_outline
                                      : Icons.album_outlined,
                              color: _accent),
                          const Spacer(),
                          Text(keys[i],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          Text('${groups[keys[i]]!.length} ${t('tracks')}',
                              style: const TextStyle(
                                  fontSize: 10, color: harborMuted))
                        ])))));
  }

  Widget _empty(String title, String subtitle, IconData icon,
          VoidCallback action, String button) =>
      Center(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: _accent, size: 35),
                const SizedBox(height: 14),
                Text(t(title),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Text(t(subtitle),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: harborMuted, fontSize: 12)),
                const SizedBox(height: 18),
                FilledButton.icon(
                    onPressed: action,
                    icon: const Icon(Icons.add, size: 17),
                    label: Text(t(button)))
              ])));

  Widget _art(SongModel? song, double size, {bool playback = false}) =>
      RepaintBoundary(
          child: song == null
              ? HarborArtwork(size: size, playback: playback)
              : PlatformArtworkWidget(
                  id: song.id,
                  path: song.data,
                  size: size,
                  nullArtworkWidget: HarborArtwork(
                      size: size, seed: song.id, playback: playback),
                  iconColor: _accent,
                  backgroundColor: _accent.withAlpha(35)));
  Widget _songRow(SongModel song, List<SongModel> songs, int index,
          {bool small = false}) =>
      Consumer(builder: (context, rowRef, _) {
        final active = rowRef.watch(
            audioPlayerProvider.select((s) => s.currentSong?.id == song.id));
        final liked = rowRef
            .watch(favoritesProvider.select((ids) => ids.contains(song.id)));
        final motionDuration = MediaQuery.disableAnimationsOf(context) ||
                MediaQuery.accessibleNavigationOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200);
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: RepaintBoundary(
                child: HarborTrackHighlight(
                    key: ValueKey('playing-row-highlight-${song.id}'),
                    active: active,
                    selected: _selected.contains(song.id),
                    accent: _accent,
                    idleColor: index.isEven
                        ? Colors.white.withAlpha(3)
                        : Colors.transparent,
                    duration: motionDuration,
                    child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                            hoverColor: Colors.white.withAlpha(9),
                            splashFactory: NoSplash.splashFactory,
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              final keyboard = HardwareKeyboard.instance;
                              if (!small &&
                                  GoRouterState.of(context).uri.path ==
                                      '/library' &&
                                  (_selectionMode ||
                                      keyboard.isControlPressed ||
                                      keyboard.isShiftPressed)) {
                                _selectSong(song, songs, index);
                              } else {
                                _play(song, songs);
                              }
                            },
                            onSecondaryTapDown: (details) =>
                                _rightClickSong(details, song, liked),
                            child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: small ? 5 : 12, vertical: 5),
                                child: Row(children: [
                                  if (!small) ...[
                                    if (_selectionMode)
                                      SizedBox(
                                          width: 36,
                                          child: Checkbox(
                                            key: ValueKey(
                                                'select-track-${song.id}'),
                                            value: _selected.contains(song.id),
                                            onChanged: (_) =>
                                                _selectSong(song, songs, index),
                                          )),
                                    SizedBox(
                                        width: 28,
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(
                                              begin: active ? 1 : 0,
                                              end: active ? 1 : 0),
                                          duration: motionDuration,
                                          curve: Curves.easeOutCubic,
                                          builder: (_, value, __) => Stack(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            children: [
                                              Opacity(
                                                  opacity: 1 - value,
                                                  child: Text('${index + 1}',
                                                      style: const TextStyle(
                                                          color: harborMuted,
                                                          fontSize: 12))),
                                              Opacity(
                                                  opacity: value,
                                                  child: Transform.scale(
                                                      scale: .8 + .2 * value,
                                                      child: Icon(
                                                          Icons.graphic_eq,
                                                          size: 17,
                                                          color: _accent))),
                                            ],
                                          ),
                                        )),
                                  ],
                                  _art(song, small ? 32 : 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      flex: 5,
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AnimatedDefaultTextStyle(
                                                duration: motionDuration,
                                                curve: Curves.easeOutCubic,
                                                style: DefaultTextStyle.of(
                                                        context)
                                                    .style
                                                    .copyWith(
                                                        fontSize:
                                                            small ? 12 : 15,
                                                        color: active
                                                            ? _accent
                                                            : const Color(
                                                                0xFFDDE6EC)),
                                                child: Text(song.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis)),
                                            if (small)
                                              Text(song.artist,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: harborMuted,
                                                      fontSize: 10))
                                          ])),
                                  if (!small) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                        flex: 2,
                                        child: Text(song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: harborMuted,
                                                fontSize: 13)))
                                  ],
                                  SizedBox(
                                      width: small ? 37 : 55,
                                      child: Text(song.durationFormatted,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: harborMuted,
                                              fontSize: small ? 10 : 12))),
                                  if (!small)
                                    _icon(
                                        liked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        'Like song',
                                        () => ref
                                            .read(favoritesProvider.notifier)
                                            .toggle(song.id),
                                        size: 17,
                                        color: liked ? _accent : harborMuted,
                                        width: 32),
                                  SizedBox(
                                      width: small ? 30 : 36,
                                      height: 36,
                                      child: _songMenuButton(song)),
                                ])))))));
      });

  void _toggle() {
    final p = ref.read(audioPlayerProvider);
    if (p.currentSong == null) return;
    final notifier = ref.read(audioPlayerProvider.notifier);
    (p.isPlaying ? notifier.pause() : notifier.play()).catchError((Object e) {
      _error('Playback failed: $e');
    });
  }

  Widget _transport(PlayerState p, {bool large = false}) {
    final n = ref.read(audioPlayerProvider.notifier);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _icon(Icons.shuffle_rounded, 'Shuffle', n.toggleShuffleMode,
          color: p.isShuffle ? _accent : harborMuted),
      const SizedBox(width: 9),
      _icon(Icons.skip_previous_rounded, 'Previous', () => n.previous()),
      const SizedBox(width: 12),
      SizedBox(
          width: large ? 66 : 43,
          height: large ? 66 : 43,
          child: IconButton(
              onPressed: p.currentSong == null ? null : _toggle,
              style: IconButton.styleFrom(
                  side: BorderSide(
                      color: p.currentSong == null
                          ? ref.read(harborThemeProvider).border
                          : _accent),
                  backgroundColor: ref.read(harborThemeProvider).background),
              icon: Icon(
                  p.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: large ? 36 : 28,
                  color: p.currentSong == null ? harborMuted : Colors.white))),
      const SizedBox(width: 12),
      _icon(Icons.skip_next_rounded, 'Next', () => n.next()),
      const SizedBox(width: 9),
      HarborRepeatButton(mode: p.repeatMode, onPressed: n.toggleRepeatMode),
    ]);
  }

  Widget _progress(PlayerState _) => HarborPlaybackClock(
      builder: (p) => Row(children: [
            Text(_time(p.position),
                style: const TextStyle(fontSize: 10, color: harborMuted)),
            Expanded(
                child: Slider(
                    value: p.position.inMilliseconds.toDouble().clamp(
                        0, math.max(1, p.duration.inMilliseconds).toDouble()),
                    max: math.max(1, p.duration.inMilliseconds).toDouble(),
                    onChanged: p.currentSong == null
                        ? null
                        : (v) => ref
                            .read(audioPlayerProvider.notifier)
                            .seek(Duration(milliseconds: v.round())))),
            Text(_time(p.duration),
                style: const TextStyle(fontSize: 10, color: harborMuted))
          ]));

  Widget _nowPlaying(PlayerState p) => Container(
        key: const ValueKey('now-playing-panel'),
        margin: const EdgeInsets.fromLTRB(0, 0, 14, 10),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(
            color: ref.read(harborThemeProvider).surface.withAlpha(160),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withAlpha(22))),
        child: LayoutBuilder(builder: (context, size) {
          final dense = size.maxHeight < 570;
          final artSize = math.min(
              size.maxWidth - 12, size.maxHeight * (dense ? .30 : .40));
          final next = p.queue.length - p.currentIndex - 1;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(t('NOW PLAYING'),
                      style: const TextStyle(
                          color: harborMuted,
                          fontSize: 10,
                          letterSpacing: 1.6)),
                  const Spacer(),
                  _icon(Icons.open_in_full_rounded, 'Full player',
                      () => context.go(AppRoutes.desktopPlayer),
                      size: 15, width: 28),
                  _icon(Icons.chevron_right_rounded, 'Hide player panel',
                      () => setState(() => _queueOpen = false),
                      size: 20, width: 25),
                ]),
                const SizedBox(height: 10),
                Column(
                  key: const ValueKey('panel-track-details'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: InkWell(
                            onTap: () => context.go(AppRoutes.desktopPlayer),
                            borderRadius: BorderRadius.circular(14),
                            child:
                                _art(p.currentSong, artSize, playback: true))),
                    SizedBox(height: dense ? 12 : 18),
                    Text(p.currentSong?.title ?? t('A space for your sound.'),
                        maxLines: dense ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(p.currentSong?.artist ?? t('Choose a track to begin'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: harborMuted)),
                  ],
                ),
                const SizedBox(height: 14),
                HarborPlaybackClock(
                    builder: (live) => Column(children: [
                          HarborWaveform(
                              path: p.currentSong?.data,
                              duration: live.duration,
                              progress: live.duration.inMilliseconds == 0
                                  ? 0
                                  : live.position.inMilliseconds /
                                      live.duration.inMilliseconds,
                              height: dense ? 44 : 68,
                              color: _accent),
                          const SizedBox(height: 7),
                          Row(children: [
                            Text(_time(live.position),
                                style: const TextStyle(
                                    fontSize: 10, color: harborMuted)),
                            const Spacer(),
                            Text(_time(live.duration),
                                style: const TextStyle(
                                    fontSize: 10, color: harborMuted)),
                          ]),
                        ])),
                SizedBox(height: dense ? 12 : 16),
                Row(children: [
                  Text(t('Next up'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: harborMuted)),
                  const Spacer(),
                  if (next > 0)
                    Text('$next',
                        style:
                            const TextStyle(fontSize: 10, color: harborMuted)),
                ]),
                const SizedBox(height: 9),
                const Divider(height: 1),
                const SizedBox(height: 5),
                Expanded(
                    child: next > 0
                        ? ListView.builder(
                            itemExtent: 48,
                            itemCount: next,
                            itemBuilder: (_, i) => _songRow(
                                p.queue[p.currentIndex + i + 1], p.queue, i,
                                small: true))
                        : Center(
                            child: Text(t('Your queue will appear here.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    color: Color(0xFF72877B))))),
              ]);
        }),
      );
  Widget _bottomPlayer(PlayerState p, bool compact) => Container(
      key: const ValueKey('desktop-player-footer'),
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
          color: ref.read(harborThemeProvider).surface,
          border: Border.all(color: ref.read(harborThemeProvider).border),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        SizedBox(
            key: const ValueKey('footer-track-details'),
            width: compact ? 220 : 285,
            child: Row(children: [
              InkWell(
                  onTap: () => context.go(AppRoutes.desktopPlayer),
                  child: _art(p.currentSong, 54, playback: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(p.currentSong?.title ?? t('Nothing playing yet'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(
                        p.currentSong?.artist ??
                            t('Your next favorite is waiting.'),
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: harborMuted, fontSize: 12))
                  ])),
              if (p.currentSong != null)
                _icon(
                    ref.watch(favoritesProvider).contains(p.currentSong!.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    'Like song',
                    () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(p.currentSong!.id),
                    size: 19)
            ])),
        const SizedBox(width: 20),
        Expanded(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _transport(p),
                          SizedBox(height: 25, child: _progress(p))
                        ])))),
        const SizedBox(width: 20),
        _timerButton(),
        _icon(
            Icons.queue_music_rounded,
            MediaQuery.sizeOf(context).width < 1250
                ? 'Open player'
                : _queueOpen
                    ? 'Hide player panel'
                    : 'Show player panel', () {
          if (MediaQuery.sizeOf(context).width < 1250) {
            context.go(AppRoutes.desktopPlayer);
          } else {
            setState(() => _queueOpen = !_queueOpen);
          }
        }, color: _queueOpen ? _accent : harborMuted),
        _icon(
            p.volume == 0
                ? Icons.volume_off_outlined
                : Icons.volume_up_outlined,
            'Mute / unmute',
            () => ref
                .read(audioPlayerProvider.notifier)
                .setVolume(p.volume == 0 ? 1 : 0),
            size: 20),
        SizedBox(
            width: compact ? 65 : 100,
            child: Slider(
                value: p.volume.clamp(0, 1),
                onChanged: (v) =>
                    ref.read(audioPlayerProvider.notifier).setVolume(v))),
      ]));
  Widget _icon(IconData icon, String tooltip, VoidCallback onTap,
          {double size = 20, Color color = harborMuted, double width = 38}) =>
      SizedBox(
          width: width,
          height: 36,
          child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: t(tooltip),
              onPressed: onTap,
              icon: Icon(icon, size: size, color: color)));
  String _time(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}
