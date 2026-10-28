import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../l10n/app_localizations.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';

VoidCallback? _dismissTrackMenu;

/// A hover timer can fire after a click already opened the submenu. Reopening
/// an open Flutter menu closes it first, so keep that second request harmless.
class _HarborSubmenuController extends MenuController {
  @override
  void open({Offset? position}) {
    if (!isOpen) super.open(position: position);
  }
}

/// One anchored desktop menu for mouse/right-click and player overflow buttons.
/// Flutter owns submenu placement, focus traversal and keyboard navigation.
Future<String?> showHarborTrackMenu(
  BuildContext context, {
  required Offset globalPosition,
  required SongModel song,
  required bool liked,
  required bool customPicture,
}) {
  _dismissTrackMenu?.call();
  final overlay = Overlay.of(context, rootOverlay: true);
  final box = overlay.context.findRenderObject() as RenderBox;
  final point = box.globalToLocal(globalPosition);
  final result = Completer<String?>();
  final controller = MenuController();
  late OverlayEntry entry;
  var finished = false;
  late VoidCallback dismiss;
  void detach() {
    if (identical(_dismissTrackMenu, dismiss)) _dismissTrackMenu = null;
    if (!result.isCompleted) result.complete(null);
  }

  void finish(String? choice) {
    if (finished) return;
    finished = true;
    if (!result.isCompleted) result.complete(choice);
    controller.close();
    entry.remove();
    entry.dispose();
    detach();
  }

  dismiss = () => finish(null);
  entry = OverlayEntry(
      builder: (_) => Positioned(
            left: point.dx.clamp(8.0, box.size.width - 8),
            top: point.dy.clamp(8.0, box.size.height - 8),
            child: InheritedTheme.captureAll(
                context,
                _TrackMenu(
                  song: song,
                  liked: liked,
                  customPicture: customPicture,
                  controller: controller,
                  onSelected: finish,
                  onClosed: dismiss,
                  onDisposed: () {
                    finished = true;
                    detach();
                  },
                )),
          ));
  _dismissTrackMenu = dismiss;
  overlay.insert(entry);
  return result.future;
}

class _TrackMenu extends ConsumerStatefulWidget {
  final SongModel song;
  final bool liked, customPicture;
  final MenuController controller;
  final ValueChanged<String> onSelected;
  final VoidCallback onClosed, onDisposed;
  const _TrackMenu(
      {required this.song,
      required this.liked,
      required this.customPicture,
      required this.controller,
      required this.onSelected,
      required this.onClosed,
      required this.onDisposed});
  @override
  ConsumerState<_TrackMenu> createState() => _TrackMenuState();
}

class _TrackMenuState extends ConsumerState<_TrackMenu> {
  // Focus the menu surface rather than an action: moving directly from an
  // initially focused MenuItemButton to a submenu can close that submenu while
  // Flutter applies the pending focus change after a fast mouse click.
  final _firstItemFocus =
      FocusNode(debugLabel: 'Track menu', skipTraversal: true);
  final _editMenu = _HarborSubmenuController();
  final _fileMenu = _HarborSubmenuController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.open(position: Offset.zero);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _firstItemFocus.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _firstItemFocus.dispose();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(harborThemeProvider);
    final l = AppLocalizations.of(context)!;
    String t(String key) => harborText(context, key);
    final style = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(theme.surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Color(0x44000000)),
      elevation: const WidgetStatePropertyAll(4),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(5)),
      minimumSize: const WidgetStatePropertyAll(Size(280, 0)),
      maximumSize: const WidgetStatePropertyAll(Size(320, double.infinity)),
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      side: WidgetStatePropertyAll(BorderSide(color: theme.border)),
    );
    ButtonStyle buttonStyle([Color? color]) => ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(270, 32)),
          maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 32)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          textStyle: const WidgetStatePropertyAll(TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 12,
              fontWeight: FontWeight.w400)),
          foregroundColor:
              WidgetStatePropertyAll(color ?? const Color(0xFFE2EBEF)),
          iconColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered)
                  ? color ?? theme.accent
                  : color ?? const Color(0xFF9BACB7)),
          overlayColor: WidgetStatePropertyAll(theme.accent.withAlpha(16)),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        );
    Widget item(String id, IconData icon, String text, {Color? color}) =>
        MenuItemButton(
          key: ValueKey('track-menu-$id'),
          closeOnActivate: false,
          style: buttonStyle(color),
          leadingIcon: Icon(icon, size: 16),
          onPressed: () => widget.onSelected(id),
          child: Text(text),
        );
    Widget group(
            String id, IconData icon, String label, List<Widget> children) =>
        SubmenuButton(
          key: ValueKey('track-menu-$id'),
          controller: id == 'edit-group' ? _editMenu : _fileMenu,
          hoverOpenDelay: const Duration(milliseconds: 150),
          style: buttonStyle(),
          menuStyle: style,
          leadingIcon: Icon(icon, size: 16),
          menuChildren: children,
          child: Text(t(label)),
        );
    Widget divider() =>
        Divider(height: 9, indent: 6, endIndent: 6, color: theme.border);
    return MenuAnchor(
      key: const ValueKey('desktop-track-menu'),
      controller: widget.controller,
      style: style,
      onClose: widget.onClosed,
      menuChildren: [
        Focus(
            focusNode: _firstItemFocus,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: SizedBox(
                    width: 250,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Segoe UI',
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                                child: Text(widget.song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'Segoe UI',
                                        fontSize: 10,
                                        color: Color(0xFF94A6AF)))),
                            Text(widget.song.durationFormatted,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                    fontFamily: 'Segoe UI',
                                    fontSize: 10,
                                    color: Color(0xFF94A6AF)))
                          ]),
                        ])))),
        divider(),
        item('play', Icons.play_arrow_rounded, t('Play now')),
        item('next', Icons.playlist_play_rounded, t('Play next')),
        item('queue', Icons.queue_music_rounded, t('Add to queue')),
        divider(),
        item(
            'favorite',
            widget.liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            widget.liked ? l.removeFromFavorites : l.addToFavorites),
        item('playlist', Icons.playlist_add_rounded, l.addToPlaylist),
        item('select', Icons.checklist_rounded, t('Select track')),
        divider(),
        group('edit-group', Icons.tune_rounded, 'Edit track', [
          item('edit', Icons.graphic_eq_rounded, t('Edit audio')),
          item('convert', Icons.sync_rounded, t('Convert audio')),
          divider(),
          item('metadata', Icons.edit_note_rounded, t('Edit metadata')),
          item('rename', Icons.drive_file_rename_outline_rounded, l.renameSong),
          item('picture', Icons.image_outlined, t('Change picture')),
          if (widget.customPicture)
            item('resetPicture', Icons.restore_rounded,
                t('Restore default picture')),
        ]),
        group('file-group', Icons.insert_drive_file_outlined, 'File', [
          item('details', Icons.info_outline_rounded, t('Track details')),
          item('copy', Icons.copy_rounded, t('Copy file path')),
          item('folder', Icons.folder_open_rounded, l.showInFolder),
        ]),
        divider(),
        item('remove', Icons.remove_circle_outline_rounded, l.removeFromLibrary,
            color: const Color(0xFFE9BD7C)),
        item('delete', Icons.delete_outline_rounded, l.deletePermanently,
            color: const Color(0xFFEE9AA6)),
      ],
      builder: (_, __, ___) => const SizedBox(width: 1, height: 1),
    );
  }
}
