import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/action_history_model.dart';
import '../../core/utils/app_toast.dart';
import 'dart:io';
import '../../data/models/song_model.dart';
import '../../data/repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../core/utils/artwork_widget.dart';

class EditingHubScreen extends ConsumerStatefulWidget {
  const EditingHubScreen({super.key});

  @override
  ConsumerState<EditingHubScreen> createState() => _EditingHubScreenState();
}

class _EditingHubScreenState extends ConsumerState<EditingHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Default tab = 0 (Tools), tab 1 = History
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppBackground(
      theme: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.editing),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: theme.primary,
            labelColor: theme.primary,
            unselectedLabelColor: theme.onSurface.withAlpha(150),
            tabs: [
              Tab(text: l10n.tools),
              Tab(text: l10n.history),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildToolsView(theme, l10n),
            const HistoryListView(filterType: 'editing'),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsView(dynamic theme, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Primary action — Add Audio to Edit
        _AddAudioCard(theme: theme, l10n: l10n),
        const SizedBox(height: 24),
        Text(
          l10n.tools,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.onSurface.withAlpha(180),
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          title: l10n.trimAudio,
          subtitle: l10n.editAudio,
          icon: Icons.content_cut_rounded,
          color: Colors.orangeAccent,
          theme: theme,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          title: l10n.eightDAudio,
          subtitle: l10n.eightDDescription,
          icon: Icons.surround_sound_rounded,
          color: Colors.purpleAccent,
          theme: theme,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          title: l10n.fadeEffects,
          subtitle: l10n.fadeIn,
          icon: Icons.graphic_eq_rounded,
          color: Colors.tealAccent,
          theme: theme,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Audio Card — primary CTA
// ─────────────────────────────────────────────────────────────────────────────
class _AddAudioCard extends ConsumerWidget {
  final dynamic theme;
  final AppLocalizations l10n;

  const _AddAudioCard({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSongPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primary.withAlpha(40),
              theme.primary.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primary.withAlpha(60), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.primary.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: theme.primary.withAlpha(100)),
              ),
              child: Icon(Icons.add_rounded, color: theme.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.addAudioToEdit,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.selectFromLibrary,
              style: TextStyle(
                fontSize: 13,
                color: theme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SongPickerSheet(
        onSongSelected: (song) {
          Navigator.pop(ctx);
          context.push(AppRoutes.editor, extra: song);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Song Picker Bottom Sheet — picks from library
// ─────────────────────────────────────────────────────────────────────────────
class _SongPickerSheet extends ConsumerStatefulWidget {
  final void Function(SongModel song) onSongSelected;

  const _SongPickerSheet({required this.onSongSelected});

  @override
  ConsumerState<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends ConsumerState<_SongPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final l10n = AppLocalizations.of(context)!;
    final songsAsync = ref.watch(songLibraryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.onSurface.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.selectFromLibrary,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (q) => setState(() => _search = q),
              decoration: InputDecoration(
                hintText: l10n.searchSongs,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.primary.withAlpha(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: songsAsync.when(
              data: (songs) {
                final filtered = _search.isEmpty
                    ? songs
                    : songs
                        .where((s) =>
                            s.title
                                .toLowerCase()
                                .contains(_search.toLowerCase()) ||
                            s.artist
                                .toLowerCase()
                                .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(l10n.noSongsFound,
                        style:
                            TextStyle(color: theme.onSurface.withAlpha(100))),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final song = filtered[i];
                    return ListTile(
                      leading: PlatformArtworkWidget(
                        id: song.id,
                        path: song.data,
                        size: 44,
                      ),
                      title: Text(song.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${song.artist}  •  ${song.durationFormatted}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.onSurface.withAlpha(120)),
                      ),
                      onTap: () => widget.onSongSelected(song),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final dynamic theme;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared History List — can be filtered by type
// ─────────────────────────────────────────────────────────────────────────────
class HistoryListView extends ConsumerStatefulWidget {
  final String? filterType;
  const HistoryListView({super.key, this.filterType});

  @override
  ConsumerState<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends ConsumerState<HistoryListView> {
  late Future<List<ActionHistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _historyFuture = IsarService.getActionHistory(type: widget.filterType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.watch(currentThemeDataProvider);

    return FutureBuilder<List<ActionHistoryModel>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: 80, color: theme.primary.withAlpha(50)),
                const SizedBox(height: 16),
                Text(
                  l10n.noHistoryYet,
                  style: TextStyle(color: theme.onSurface.withAlpha(120)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return _HistoryCard(
              item: item,
              theme: theme,
              l10n: l10n,
              onDeleted: () {
                setState(() => _refresh());
              },
            );
          },
        );
      },
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final ActionHistoryModel item;
  final dynamic theme;
  final AppLocalizations l10n;
  final VoidCallback onDeleted;

  const _HistoryCard({
    required this.item,
    required this.theme,
    required this.l10n,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat.yMMMd().add_Hm();
    final isConversion = item.type == 'conversion';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withAlpha(20)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isConversion ? Colors.blue : Colors.purple).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isConversion ? Icons.sync_rounded : Icons.auto_fix_high_rounded,
            color: isConversion ? Colors.blueAccent : Colors.purpleAccent,
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${isConversion ? l10n.convertVideo : l10n.editing} • ${item.fileSizeFormatted}',
              style: TextStyle(
                  fontSize: 12, color: theme.onSurface.withAlpha(150)),
            ),
            Text(
              dateFormat.format(item.timestamp),
              style: TextStyle(
                  fontSize: 10, color: theme.onSurface.withAlpha(100)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!item.isSuccess)
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 20),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => _showOptions(context, ref),
            ),
          ],
        ),
        onTap: () {
          final file = File(item.outputPath);
          if (file.existsSync()) {
            final song = SongModel(
              id: stablePathId(item.outputPath),
              title: item.title,
              artist: l10n.unknownArtist,
              album: l10n.unknownAlbum,
              data: item.outputPath,
              duration: 0,
              dateAdded: (item.timestamp.millisecondsSinceEpoch / 1000).round(),
            );

            // Just play the song — don't navigate to the full player
            // (the mini player will appear automatically)
            ref.read(audioPlayerProvider.notifier).playSong(song);
          } else {
            AppToast.error(context, l10n.failed);
          }
        },
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: Text(l10n.share),
              onTap: () {
                Navigator.pop(ctx);
                _shareOutput(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              title: Text(l10n.delete,
                  style: const TextStyle(color: Colors.redAccent)),
              onTap: () async {
                // Capture the navigator before the await (the dialog context
                // must not be used across an async gap).
                final navigator = Navigator.of(ctx);
                await IsarService.deleteAction(item.id);
                if (navigator.canPop()) navigator.pop();
                onDeleted();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareOutput(BuildContext context) async {
    final path = item.outputPath;
    if (!File(path).existsSync()) {
      AppToast.error(context, l10n.failed);
      return;
    }
    try {
      if (isMobile) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: item.title),
        );
      } else if (isWindows) {
        await Process.run('explorer.exe', ['/select,$path']);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [File(path).parent.path]);
      }
    } catch (e) {
      debugPrint('Share history item failed: $e');
      if (context.mounted) AppToast.error(context, l10n.failed);
    }
  }
}
