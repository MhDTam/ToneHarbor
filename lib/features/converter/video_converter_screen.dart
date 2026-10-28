import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../../core/router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/file_naming.dart';
import '../../core/utils/platform_utils.dart';
import '../../services/ffmpeg_service.dart';
import '../../services/cache_cleanup_service.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/models/song_model.dart';
import '../../services/audio/audio_player_service.dart';
import '../../core/utils/app_toast.dart';
import '../../l10n/app_localizations.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/action_history_model.dart';
import '../editor/editing_hub_screen.dart';

/// Video containers the converter accepts. The picker is already filtered to
/// `video/*`; this is a second guard for OEM pickers that ignore the filter.
const Set<String> _kVideoExtensions = {
  '.mp4',
  '.mkv',
  '.mov',
  '.avi',
  '.flv',
  '.wmv',
  '.webm',
  '.3gp',
  '.m4v',
  '.mpg',
  '.mpeg',
  '.ts',
  '.mts',
  '.m2ts',
  '.vob',
  '.ogv',
};

bool _isVideoFile(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return false;
  return _kVideoExtensions.contains(path.substring(dot).toLowerCase());
}

class VideoConverterScreen extends ConsumerStatefulWidget {
  const VideoConverterScreen({super.key});

  @override
  ConsumerState<VideoConverterScreen> createState() =>
      _VideoConverterScreenState();
}

class _VideoConverterScreenState extends ConsumerState<VideoConverterScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedVideoPath;
  String? _thumbnailPath;
  double _videoDuration = 0.0;
  bool _isConverting = false;
  double _progress = 0;
  String? _statusMessage;
  String _selectedFormat = 'MP3';
  int? _currentSessionId;
  DateTime _lastProgressTick = DateTime.fromMillisecondsSinceEpoch(0);

  // Custom name controller
  late TextEditingController _nameController;

  // Success state
  bool _conversionDone = false;
  String? _savedFileName;
  String? _savedFilePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    final video = _selectedVideoPath;
    final thumb = _thumbnailPath;
    if (video != null) CacheCleanupService.deleteIfTemporary(video);
    if (thumb != null) CacheCleanupService.deleteIfTemporary(thumb);
    super.dispose();
  }

  Future<void> _pickVideo() async {
    if (isDesktop) {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );
      final path = r?.files.single.path;
      if (path == null || !mounted) return;
      if (!_isVideoFile(path)) {
        AppToast.error(context, AppLocalizations.of(context)!.selectVideoOnly);
        return;
      }
      _handlePickedVideo(path);
      return;
    }

    // Mobile: open Gallery directly (no bottom sheet with Files)
    try {
      final video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null && mounted) {
        _handlePickedVideo(video.path);
      }
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
    }
  }

  Future<void> _handlePickedVideo(String path) async {
    final oldVideo = _selectedVideoPath;
    final oldThumb = _thumbnailPath;
    if (oldVideo != null && oldVideo != path) {
      CacheCleanupService.deleteIfTemporary(oldVideo);
    }
    if (oldThumb != null) {
      CacheCleanupService.deleteIfTemporary(oldThumb);
    }

    final videoBasename = p.basenameWithoutExtension(path);

    setState(() {
      _selectedVideoPath = path;
      _progress = 0;
      _statusMessage = AppLocalizations.of(context)!.extractingVideoInfo;
      _thumbnailPath = null;
      _videoDuration = 0.0;
      _conversionDone = false;
      _savedFileName = null;
      _nameController.text = videoBasename;
    });

    try {
      final ffmpeg = ref.read(ffmpegServiceProvider);
      final duration = await ffmpeg.getDuration(path);
      final thumb = await ffmpeg.extractThumbnail(path);

      if (mounted) {
        setState(() {
          _videoDuration = duration;
          _thumbnailPath = thumb;
          _statusMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error getting video info: $e');
      if (mounted) setState(() => _statusMessage = null);
    }
  }

  void _cancel() {
    if (_currentSessionId != null) {
      ref.read(ffmpegServiceProvider).cancelSession(_currentSessionId);
      if (mounted) {
        AppToast.info(
            context, AppLocalizations.of(context)!.conversionCancelled);
      }
      setState(() {
        _isConverting = false;
        _statusMessage = AppLocalizations.of(context)!.conversionCancelled;
        _progress = 0;
      });
    }
  }

  void _resetForNewConversion() {
    final oldVideo = _selectedVideoPath;
    final oldThumb = _thumbnailPath;
    if (oldVideo != null) CacheCleanupService.deleteIfTemporary(oldVideo);
    if (oldThumb != null) CacheCleanupService.deleteIfTemporary(oldThumb);

    setState(() {
      _selectedVideoPath = null;
      _thumbnailPath = null;
      _videoDuration = 0.0;
      _progress = 0;
      _statusMessage = null;
      _conversionDone = false;
      _savedFileName = null;
      _nameController.clear();
    });
  }

  Future<void> _convert() async {
    if (_selectedVideoPath == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isConverting = true;
      _progress = 0;
      _statusMessage = l10n.startingConversion;
      _conversionDone = false;
    });

    String? tempOutputPath;
    try {
      final ffmpeg = ref.read(ffmpegServiceProvider);

      if (Platform.isAndroid) {
        // Notification permission for the foreground conversion service notification.
        // Photo / video picking uses the system picker which requires zero storage permissions.
        try {
          await Permission.notification.request();
        } catch (_) {}
      }

      // Use custom name from text field (sanitised so it cannot escape the
      // output folder).
      final customName = sanitizeFileName(_nameController.text);
      final videoBasename = customName.isNotEmpty
          ? customName
          : p.basenameWithoutExtension(_selectedVideoPath!);
      // AAC goes into an .m4a container: it is more compatible than raw .aac
      // and lets the audio be stream-copied instead of re-encoded.
      final ext = _selectedFormat == 'AAC' ? 'm4a' : 'mp3';
      final fileName = '$videoBasename.$ext';

      final cacheDir = await getTemporaryDirectory();
      tempOutputPath = p.join(
          cacheDir.path, 'conv_${DateTime.now().millisecondsSinceEpoch}.$ext');

      final result = await ffmpeg.convertVideoToAudio(
        _selectedVideoPath!,
        tempOutputPath,
        codec: _selectedFormat == 'AAC' ? 'aac' : 'libmp3lame',
        title: fileName,
        subtitle: l10n.converting,
        totalDurationSec: _videoDuration > 0 ? _videoDuration : null,
        onSessionStarted: (id) => _currentSessionId = id,
        onProgress: (sec) {
          if (!mounted) return;
          // Throttle: FFmpeg reports statistics very often and every setState
          // rebuilds this whole screen.
          final now = DateTime.now();
          if (now.difference(_lastProgressTick) <
              const Duration(milliseconds: 200)) {
            return;
          }
          _lastProgressTick = now;
          setState(() {
            if (_videoDuration > 0) {
              _progress = (sec / _videoDuration).clamp(0.0, 1.0);
              _statusMessage =
                  '${l10n.converting}... ${(_progress * 100).toStringAsFixed(0)}%';
            } else {
              _statusMessage = '${l10n.processed}: ${sec.toStringAsFixed(1)}s';
            }
          });
        },
      );
      final resultPath = result.path;
      final resultError = result.error;

      if (resultError == 'CANCELLED') return;

      if (resultPath != null) {
        String finalDestDir = '/storage/emulated/0/Music/MusiConvert';
        try {
          final dir = Directory(finalDestDir);
          if (!await dir.exists()) await dir.create(recursive: true);
        } catch (e) {
          debugPrint('Error creating MusiConvert dir: $e');
          finalDestDir = '/storage/emulated/0/Music';
        }

        final publicFile = File(p.join(finalDestDir, fileName));
        bool moveSuccess = false;
        try {
          await File(resultPath).copy(publicFile.path);
          await File(resultPath).delete();
          moveSuccess = true;
        } catch (e) {
          debugPrint('Move to public Music failed: $e. Using fallback.');
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            final fallbackPath = p.join(extDir.path, fileName);
            try {
              await File(resultPath).copy(fallbackPath);
              await File(resultPath).delete();
              finalDestDir = extDir.path;
              moveSuccess = true;
            } catch (e2) {
              debugPrint('Fallback move failed: $e2');
            }
          }
        }

        if (!moveSuccess) {
          if (mounted) {
            setState(() {
              _statusMessage = l10n.failedToSave;
            });
          }
          return;
        }

        final finalPath = p.join(finalDestDir, fileName);

        try {
          final aq = OnAudioQuery();
          await aq.scanMedia(finalPath);
          await Future.delayed(const Duration(milliseconds: 500));

          // Record History
          try {
            final file = File(finalPath);
            final size = await file.length();
            await IsarService.saveAction(ActionHistoryModel()
              ..title = videoBasename
              ..type = 'conversion'
              ..sourcePath = _selectedVideoPath!
              ..outputPath = finalPath
              ..timestamp = DateTime.now()
              ..fileSizeBytes = size
              ..isSuccess = true);
          } catch (e) {
            debugPrint('Failed to save conversion history: $e');
          }

          ref.invalidate(songLibraryProvider);
        } catch (_) {}

        ffmpeg.showCompletionNotification(
          title: l10n.conversionDone,
          message: l10n.savedAs(fileName),
        );

        if (mounted) {
          setState(() {
            _conversionDone = true;
            _savedFileName = fileName;
            _savedFilePath = finalPath;
            _statusMessage = null;
            _progress = 1.0;
          });
        }

        // Clean up cached video and thumbnail immediately upon successful conversion
        final oldVideo = _selectedVideoPath;
        final oldThumb = _thumbnailPath;
        _selectedVideoPath = null;
        _thumbnailPath = null;
        if (oldVideo != null) {
          await CacheCleanupService.deleteIfTemporary(oldVideo);
        }
        if (oldThumb != null) {
          await CacheCleanupService.deleteIfTemporary(oldThumb);
        }
      } else {
        ffmpeg.showCompletionNotification(
          title: l10n.conversionFailed,
          message: resultError ?? l10n.unknown,
        );
        if (mounted) {
          setState(() {
            _statusMessage =
                '${l10n.conversionFailed}:\n${resultError ?? l10n.unknown}';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = '${l10n.error}: $e');
    } finally {
      await CacheCleanupService.deleteIfTemporary(tempOutputPath);
      if (mounted) {
        setState(() {
          _isConverting = false;
          _currentSessionId = null;
        });
      }
    }
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '00:00';
    final dur = Duration(seconds: seconds.toInt());
    final min = dur.inMinutes.toString().padLeft(2, '0');
    final sec = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: AppBackground(
        theme: theme,
        child: SafeArea(
          top: isMobile,
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 20,
                    isDesktop ? 20 : 12, isDesktop ? 28 : 20, 0),
                child: Row(
                  children: [
                    Text(
                      l10n.convertVideoToAudio,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isDesktop ? 24 : null,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          Icon(Icons.settings_rounded, color: theme.onSurface),
                      tooltip: l10n.settings,
                      onPressed: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
              ),
              // TabBar
              TabBar(
                indicatorColor: theme.primary,
                labelColor: theme.primary,
                unselectedLabelColor: theme.onSurface.withAlpha(150),
                tabs: [
                  Tab(text: l10n.convertVideo),
                  Tab(text: l10n.history),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Converter
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        children: [
                          // ── Success State ──────────────────────────────────
                          if (_conversionDone && _savedFileName != null)
                            _buildSuccessCard(theme)
                          // ── Normal States ──────────────────────────────────
                          else ...[
                            // Video Preview Section
                            if (_selectedVideoPath == null)
                              _buildEmptyState(theme)
                            else
                              _buildVideoPreview(theme),

                            const SizedBox(height: 24),

                            // Controls Section
                            if (!_isConverting) ...[
                              // ── Rename Section ──────────────────────────
                              if (_selectedVideoPath != null)
                                _buildRenameSection(theme),

                              if (_selectedVideoPath != null)
                                const SizedBox(height: 16),

                              // Select Video Button
                              _buildActionButton(
                                onPressed: _pickVideo,
                                icon: Icons.video_file_rounded,
                                label: l10n.selectDifferentVideo,
                                theme: theme,
                                isPrimary: false,
                                visible: _selectedVideoPath != null,
                              ),

                              const SizedBox(height: 16),

                              // Format Selection
                              if (_selectedVideoPath != null)
                                _buildFormatSelector(theme),

                              const SizedBox(height: 24),

                              // Convert Button
                              _buildActionButton(
                                onPressed: _selectedVideoPath == null
                                    ? _pickVideo
                                    : _convert,
                                icon: _selectedVideoPath == null
                                    ? Icons.video_call_rounded
                                    : Icons.sync_rounded,
                                label: _selectedVideoPath == null
                                    ? l10n.selectVideo
                                    : l10n.convertToAudio,
                                theme: theme,
                                isPrimary: true,
                                visible: true,
                              ),
                            ] else ...[
                              // Converting State
                              _buildConvertingState(theme),
                            ],
                          ],
                        ],
                      ),
                    ),
                    // Tab 2: History
                    const HistoryListView(filterType: 'conversion'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRenameSection(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.outputName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedFormat == 'AAC' ? '.m4a' : '.mp3',
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            style: TextStyle(color: theme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterOutputFilename,
              hintStyle: TextStyle(color: theme.onSurface.withAlpha(80)),
              filled: true,
              fillColor: theme.surface.withAlpha(80),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.music_note_rounded,
                  color: theme.primary.withAlpha(120), size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primary.withAlpha(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.primary.withAlpha(100), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector(dynamic theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withAlpha(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.audio_file_rounded,
              color: theme.primary.withAlpha(150), size: 18),
          const SizedBox(width: 10),
          Text(AppLocalizations.of(context)!.format,
              style: TextStyle(
                color: theme.onSurface.withAlpha(180),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
          const Spacer(),
          _buildFormatChip('MP3', theme),
          const SizedBox(width: 8),
          _buildFormatChip('AAC', theme),
        ],
      ),
    );
  }

  Widget _buildConvertingState(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          // Animated progress ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    color: theme.primary,
                    strokeWidth: 4,
                    backgroundColor: theme.primary.withAlpha(20),
                  ),
                ),
                if (_progress > 0)
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Icon(Icons.sync_rounded, color: theme.primary, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage ?? AppLocalizations.of(context)!.converting,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.pleaseWaitMoment,
            style: TextStyle(
              color: theme.onSurface.withAlpha(80),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: theme.surface.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _cancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.cancel),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(dynamic theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Success animation container
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.surface.withAlpha(120),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00E676).withAlpha(60)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withAlpha(20),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Success icon with glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withAlpha(25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withAlpha(30),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00E676),
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                l10n.extractionComplete,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00E676),
                ),
              ),
              const SizedBox(height: 8),

              // Filename display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.surface.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primary.withAlpha(20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note_rounded,
                        color: theme.primary, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _savedFileName ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              Text(
                '${l10n.savedTo} Music/MusiConvert',
                style: TextStyle(
                  color: theme.onSurface.withAlpha(100),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons - 3 rows
        // Play Now - primary action
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              if (_savedFilePath != null) {
                final songs = ref.read(songLibraryProvider).valueOrNull ?? [];
                final match =
                    songs.where((s) => s.data == _savedFilePath).toList();
                if (match.isNotEmpty) {
                  ref
                      .read(audioPlayerProvider.notifier)
                      .playSong(match.first, queue: match, index: 0);
                  context.push(AppRoutes.player);
                } else {
                  // Create a temporary SongModel from path
                  final tempSong = SongModel(
                    id: stablePathId(_savedFilePath!),
                    title: p.basenameWithoutExtension(_savedFilePath!),
                    artist: l10n.unknownArtist,
                    album: l10n.unknownAlbum,
                    data: _savedFilePath!,
                    duration: 0,
                    dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  );
                  ref.read(audioPlayerProvider.notifier).playSong(tempSong);
                  context.push(AppRoutes.player);
                }
              }
            },
            icon: const Icon(Icons.play_circle_rounded, size: 22),
            label: Text(l10n.play,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // View Library + Convert Another
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.library),
                  icon: Icon(Icons.library_music_rounded,
                      size: 18, color: theme.onSurface),
                  label: Text(l10n.library,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.onSurface,
                      )),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.onSurface.withAlpha(50)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _resetForNewConversion,
                  icon:
                      Icon(Icons.add_rounded, size: 18, color: theme.onSurface),
                  label: Text(l10n.convertAnother,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.onSurface,
                      )),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.onSurface.withAlpha(50)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(dynamic theme) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: theme.surface.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.video_collection_rounded,
            size: 80,
            color: theme.primary.withAlpha(100),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.chooseVideoToStart,
          style: TextStyle(color: theme.onSurface.withAlpha(120), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(dynamic theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.surface.withAlpha(60),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withAlpha(30),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
                image: _thumbnailPath != null
                    ? DecorationImage(
                        image: FileImage(File(_thumbnailPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _thumbnailPath == null
                  ? Center(
                      child: CircularProgressIndicator(color: theme.primary))
                  : null,
            ),
            if (_videoDuration > 0)
              Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(_videoDuration),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.secondsVideo(_videoDuration.toStringAsFixed(0)),
          style: TextStyle(color: theme.onSurface.withAlpha(150), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFormatChip(String label, dynamic theme) {
    final isSelected = _selectedFormat == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.primary : theme.onSurface.withAlpha(50),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : theme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required dynamic theme,
    required bool isPrimary,
    required bool visible,
    Color? colorOverride,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 56,
      decoration: isPrimary
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (colorOverride ?? theme.primary).withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            )
          : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? (colorOverride ?? theme.primary)
              : theme.surface.withAlpha(40),
          foregroundColor:
              isPrimary ? theme.onPrimary : (colorOverride ?? theme.onSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: (colorOverride ?? theme.onSurface).withAlpha(50)),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
