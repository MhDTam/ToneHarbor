import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';

String harborFolderPath(SongModel song) {
  final path = song.data.replaceAll('\\', '/');
  final slash = path.lastIndexOf('/');
  if (slash == 2 && path[1] == ':') return path.substring(0, 3);
  return slash < 0 ? 'Music' : path.substring(0, slash + (slash == 0 ? 1 : 0));
}

class HarborFolders extends ConsumerStatefulWidget {
  final Map<String, List<SongModel>> folders;
  final ValueChanged<String> onOpen;
  final ValueChanged<List<SongModel>> onPlay;
  final VoidCallback onAdd;
  const HarborFolders(
      {super.key,
      required this.folders,
      required this.onOpen,
      required this.onPlay,
      required this.onAdd});
  @override
  ConsumerState<HarborFolders> createState() => _HarborFoldersState();
}

class _HarborFoldersState extends ConsumerState<HarborFolders> {
  String sort = 'Name';
  int duration(String path) =>
      widget.folders[path]!.fold(0, (sum, song) => sum + song.duration);
  String name(String path) =>
      path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? path;
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(harborThemeProvider);
    String t(String s) => harborText(context, s);
    final paths = widget.folders.keys.toList()
      ..sort((a, b) => switch (sort) {
            'Tracks' =>
              widget.folders[b]!.length.compareTo(widget.folders[a]!.length),
            'Duration' => duration(b).compareTo(duration(a)),
            _ => name(a).toLowerCase().compareTo(name(b).toLowerCase()),
          });
    return LayoutBuilder(builder: (_, bounds) {
      final showPath = bounds.maxWidth >= 700;
      return Column(key: const ValueKey('desktop-folder-browser'), children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              Text('${paths.length} ${t('Folders')}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const Spacer(),
              PopupMenuButton<String>(
                  tooltip: t('Sort folders'),
                  initialValue: sort,
                  onSelected: (value) => setState(() => sort = value),
                  itemBuilder: (_) => [
                        for (final value in ['Name', 'Tracks', 'Duration'])
                          CheckedPopupMenuItem(
                              value: value,
                              checked: sort == value,
                              child: Text(t(value)))
                      ],
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        const Icon(Icons.sort, size: 17),
                        const SizedBox(width: 6),
                        Text(t(sort), style: const TextStyle(fontSize: 12))
                      ]))),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 17),
                  label: Text(t('Add folder'))),
            ])),
        Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: theme.surface,
                border: Border(bottom: BorderSide(color: theme.border))),
            child: Row(children: [
              Expanded(
                  flex: 3,
                  child: Text(t('Name'),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11))),
              if (showPath)
                Expanded(
                    flex: 4,
                    child: Text(t('Location'),
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11))),
              SizedBox(
                  width: 56,
                  child: Text(t('Tracks'),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11))),
              SizedBox(
                  width: 74,
                  child: Text(t('Duration'),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11))),
              const SizedBox(width: 66),
            ])),
        Expanded(
            child: ListView.separated(
                itemCount: paths.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: theme.border.withAlpha(100)),
                itemBuilder: (_, i) {
                  final path = paths[i], songs = widget.folders[path]!;
                  final total = Duration(milliseconds: duration(path));
                  return InkWell(
                      key: ValueKey('folder-path-$path'),
                      onTap: () => widget.onOpen(path),
                      child: SizedBox(
                          height: 72,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(children: [
                              Expanded(
                                  flex: 3,
                                  child: Row(children: [
                                    Icon(Icons.folder_open_outlined,
                                        color: theme.accent, size: 25),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(name(path),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                          if (!showPath) ...[
                                            const SizedBox(height: 4),
                                            Text(path,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 10))
                                          ],
                                        ])),
                                  ])),
                              if (showPath)
                                Expanded(
                                    flex: 4,
                                    child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        child: Text(path,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11)))),
                              SizedBox(
                                  width: 56,
                                  child: Text('${songs.length}',
                                      style: const TextStyle(fontSize: 12))),
                              SizedBox(
                                  width: 74,
                                  child: Text(
                                      '${total.inHours > 0 ? '${total.inHours}:' : ''}${(total.inHours > 0 ? total.inMinutes.remainder(60) : total.inMinutes).toString().padLeft(2, '0')}:${total.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12))),
                              IconButton(
                                  tooltip: t('Play folder'),
                                  key: ValueKey('play-folder-$path'),
                                  onPressed: () => widget.onPlay(songs),
                                  icon: Icon(Icons.play_arrow_rounded,
                                      color: theme.accent, size: 21)),
                              const Icon(Icons.chevron_right,
                                  size: 18, color: Colors.white38),
                            ]),
                          )));
                })),
      ]);
    });
  }
}
