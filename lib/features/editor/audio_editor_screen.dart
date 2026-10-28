import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/app_toast.dart';

import '../../data/models/song_model.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/ffmpeg_service.dart';
import '../../services/cache_cleanup_service.dart';
import '../../data/repositories/song_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/action_history_model.dart';

class AudioEditorScreen extends ConsumerStatefulWidget {
  final SongModel song;

  const AudioEditorScreen({super.key, required this.song});

  @override
  ConsumerState<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends ConsumerState<AudioEditorScreen>
    with SingleTickerProviderStateMixin {
  late double _startTrim;
  late double _endTrim;
  double _volume = 1.0;
  bool _is8D = false;
  double _speed8D = 0.125;
  double _amount8D = 1.0;
  double _reverb8D = 0.3;
  double _fadeInSec = 0.0;
  double _fadeOutSec = 0.0;

  bool _isConverting = false;
  String? _statusMessage;
  DateTime _lastProgressTick = DateTime.fromMillisecondsSinceEpoch(0);

  AudioPlayer? _previewPlayer;
  bool _isPreviewPlaying = false;
  Duration _previewPosition = Duration.zero;

  // New: Effect Preview
  bool _isGeneratingPreview = false;
  AudioPlayer? _effectsPreviewPlayer;
  bool _isEffectsPreviewPlaying = false;

  /// Last generated effect preview; deleted before the next one is created.
  String? _previewFilePath;

  // Waveform data
  List<double> _waveformData = [];
  bool _isLoadingWaveform = true;

  // Custom name controller
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _startTrim = 0;
    _endTrim = widget.song.duration > 0 ? widget.song.duration / 1000.0 : 60;
    _nameController = TextEditingController(text: widget.song.title);
    _initPreviewPlayer();
    _loadWaveform();
  }

  Future<void> _initPreviewPlayer() async {
    _previewPlayer = AudioPlayer();
    try {
      await _previewPlayer!.setAudioSource(
        AudioSource.file(widget.song.data),
      );

      _previewPlayer!.positionStream.listen((pos) {
        if (mounted) {
          setState(() => _previewPosition = pos);
          // Auto-stop at trim end
          if (pos.inMilliseconds >= (_endTrim * 1000).toInt()) {
            _previewPlayer!.pause();
            _previewPlayer!
                .seek(Duration(milliseconds: (_startTrim * 1000).toInt()));
            if (mounted) setState(() => _isPreviewPlaying = false);
          }
        }
      });
      _previewPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPreviewPlaying = state.playing);
        }
      });
    } catch (e) {
      debugPrint('Preview player init error: $e');
    }
  }

  Future<void> _loadWaveform() async {
    try {
      final ffmpeg = ref.read(ffmpegServiceProvider);
      final data =
          await ffmpeg.extractWaveform(widget.song.data, samplesCount: 150);
      if (mounted) {
        setState(() {
          _waveformData = data;
          _isLoadingWaveform = false;
        });
      }
    } catch (e) {
      debugPrint('Waveform load error: $e');
      if (mounted) setState(() => _isLoadingWaveform = false);
    }
  }

  void _togglePreview() {
    if (_previewPlayer == null) return;
    if (_isPreviewPlaying) {
      _previewPlayer!.pause();
    } else {
      // If at end or outside trim range, seek to trim start
      final pos = _previewPosition.inMilliseconds;
      final start = (_startTrim * 1000).toInt();
      final end = (_endTrim * 1000).toInt();
      if (pos < start || pos >= end) {
        _previewPlayer!.seek(Duration(milliseconds: start));
      }
      _previewPlayer!.play();
    }
  }

  @override
  void dispose() {
    _previewPlayer?.dispose();
    _effectsPreviewPlayer?.dispose();
    _nameController.dispose();
    final preview = _previewFilePath;
    if (preview != null) {
      _previewFilePath = null;
      CacheCleanupService.deleteIfTemporary(preview);
    }
    super.dispose();
  }

  Future<void> _generateAndPlayPreview() async {
    if (_isConverting || _isGeneratingPreview) return;

    // Stop current players
    _previewPlayer?.pause();
    _effectsPreviewPlayer?.pause();

    setState(() {
      _isGeneratingPreview = true;
      _statusMessage = AppLocalizations.of(context)!.generatingPreview;
    });

    try {
      final ffmpeg = ref.read(ffmpegServiceProvider);
      final tempDir = await getTemporaryDirectory();
      final previewPath = p.join(
          tempDir.path, 'preview_${DateTime.now().millisecondsSinceEpoch}.mp3');

      // Drop the previous preview so the temp folder cannot grow forever.
      final previousPreview = _previewFilePath;
      if (previousPreview != null) {
        _previewFilePath = null;
        try {
          final previousFile = File(previousPreview);
          if (await previousFile.exists()) await previousFile.delete();
        } catch (_) {}
      }

      // Preview the first 15 seconds of the selection
      final startDuration = Duration(milliseconds: (_startTrim * 1000).toInt());
      final endDuration = Duration(
          milliseconds: min((_startTrim + 15) * 1000, _endTrim * 1000).toInt());

      final result = await ffmpeg.editAudio(
        widget.song.data,
        previewPath,
        start: startDuration,
        end: endDuration,
        volume: _volume,
        is8D: _is8D,
        speed8D: _speed8D,
        amount8D: _amount8D,
        reverb8D: _reverb8D,
        fadeInSec: _fadeInSec,
        fadeOutSec: _fadeOutSec,
        title: 'Preview',
      );

      if (result != null && mounted) {
        if (_effectsPreviewPlayer == null) {
          _effectsPreviewPlayer = AudioPlayer();
          _effectsPreviewPlayer!.playerStateStream.listen((state) {
            if (mounted) {
              setState(() => _isEffectsPreviewPlaying = state.playing);
            }
          });
        }
        await _effectsPreviewPlayer!.setAudioSource(AudioSource.file(result));
        _previewFilePath = result;
        _effectsPreviewPlayer!.play();
        setState(() => _statusMessage = null);
      } else {
        if (mounted) {
          AppToast.error(
              context, AppLocalizations.of(context)!.previewGenerationFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppLocalizations.of(context)!.audioSavedError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPreview = false;
          _statusMessage = null;
        });
      }
    }
  }

  String _truncateMiddle(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    final half = (maxLen - 3) ~/ 2;
    return '${text.substring(0, half)}...${text.substring(text.length - half)}';
  }

  String _formatDuration(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds.toInt() % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<bool> _ensureStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.isGranted) return true;
      if (await Permission.storage.isGranted) return true;

      final audio = await Permission.audio.request();
      if (audio.isGranted) return true;

      final legacyStorage = await Permission.storage.request();
      return legacyStorage.isGranted;
    }
    return true;
  }

  Future<void> _processAudio(bool replace) async {
    // Request storage permission first
    if (Platform.isAndroid) {
      final storageOk = await _ensureStoragePermission();
      if (!storageOk) {
        if (mounted) {
          AppToast.error(
              context, AppLocalizations.of(context)!.grantPermission);
        }
        return;
      }
    }

    setState(() {
      _isConverting = true;
      _statusMessage = AppLocalizations.of(context)!.processing;
    });

    // Pause preview if playing
    _previewPlayer?.pause();

    String? tempOutputPath;
    try {
      final ffmpeg = ref.read(ffmpegServiceProvider);

      final originalPath = widget.song.data;
      final Directory dir = File(originalPath).parent;
      final String basename = p.basenameWithoutExtension(originalPath);
      final String extension = p.extension(originalPath);

      final String customName = _nameController.text.trim();
      final String safeName = customName.isEmpty ? basename : customName;

      final tempDir = await getTemporaryDirectory();
      tempOutputPath = p.join(tempDir.path,
          'edited_${DateTime.now().millisecondsSinceEpoch}$extension');

      String finalOutputPath;
      if (replace) {
        finalOutputPath = originalPath;
      } else {
        finalOutputPath = p.join(dir.path, '${safeName}_edited$extension');
      }

      final startDuration = Duration(milliseconds: (_startTrim * 1000).toInt());
      final endDuration = Duration(milliseconds: (_endTrim * 1000).toInt());

      final resultPath = await ffmpeg.editAudio(
        originalPath,
        tempOutputPath,
        start: startDuration,
        end: endDuration,
        volume: _volume,
        is8D: _is8D,
        speed8D: _speed8D,
        amount8D: _amount8D,
        reverb8D: _reverb8D,
        fadeInSec: _fadeInSec,
        fadeOutSec: _fadeOutSec,
        title: safeName,
        onProgress: (sec) {
          if (!mounted) return;
          // Throttle: FFmpeg reports statistics very often and every setState
          // rebuilds the whole editor including the waveform.
          final now = DateTime.now();
          if (now.difference(_lastProgressTick) <
              const Duration(milliseconds: 200)) {
            return;
          }
          _lastProgressTick = now;
          final totalSec = _endTrim - _startTrim;
          final percent =
              totalSec > 0 ? (sec / totalSec * 100).clamp(0, 100).toInt() : 0;
          setState(() {
            _statusMessage =
                AppLocalizations.of(context)!.savingProgress(percent);
          });
        },
      );

      if (resultPath != null) {
        final tempFile = File(resultPath);
        String actualSavedPath = replace ? originalPath : finalOutputPath;
        if (replace) {
          try {
            await tempFile.copy(originalPath);
            await tempFile.delete();
            await OnAudioQuery().scanMedia(originalPath);
          } catch (e) {
            debugPrint(
                'Failed to replace original file: $e. Falling back to Music/MusiConvert.');
            try {
              final musicDir =
                  Directory('/storage/emulated/0/Music/MusiConvert');
              if (!await musicDir.exists()) {
                await musicDir.create(recursive: true);
              }
              actualSavedPath =
                  p.join(musicDir.path, '${safeName}_edited$extension');
              await tempFile.copy(actualSavedPath);
              await tempFile.delete();
              await OnAudioQuery().scanMedia(actualSavedPath);
            } catch (ex) {
              setState(() => _isConverting = false);
              if (mounted) {
                AppToast.error(
                    context, AppLocalizations.of(context)!.audioSavedError);
              }
              return;
            }
          }
        } else {
          try {
            await tempFile.copy(finalOutputPath);
            await tempFile.delete();
            await OnAudioQuery().scanMedia(finalOutputPath);
          } catch (e) {
            debugPrint(
                'Failed to save to destination: $e. Falling back to Music/MusiConvert.');
            try {
              final musicDir =
                  Directory('/storage/emulated/0/Music/MusiConvert');
              if (!await musicDir.exists()) {
                await musicDir.create(recursive: true);
              }
              actualSavedPath =
                  p.join(musicDir.path, '${safeName}_edited$extension');
              await tempFile.copy(actualSavedPath);
              await tempFile.delete();
              await OnAudioQuery().scanMedia(actualSavedPath);
            } catch (ex) {
              setState(() => _isConverting = false);
              if (mounted) {
                AppToast.error(
                    context, AppLocalizations.of(context)!.audioSavedError);
              }
              return;
            }
          }
        }

        final historyPathForRecord = actualSavedPath;

        // Record History
        try {
          final file = File(historyPathForRecord);
          final size = await file.length();
          await IsarService.saveAction(ActionHistoryModel()
            ..title = safeName
            ..type = 'editing'
            ..sourcePath = originalPath
            ..outputPath = historyPathForRecord
            ..timestamp = DateTime.now()
            ..fileSizeBytes = size
            ..isSuccess = true);
        } catch (e) {
          debugPrint('Failed to save action history: $e');
        }

        ref.invalidate(songLibraryProvider);

        if (mounted) {
          AppToast.success(
              context, AppLocalizations.of(context)!.audioSavedSuccess);
          context.pop();
        }
      } else {
        setState(() =>
            _statusMessage = AppLocalizations.of(context)!.processingFailed);
      }
    } catch (e) {
      if (mounted) {
        final errorText = e.toString().replaceAll('Exception: ', '');
        setState(() => _statusMessage = errorText);
      }
    } finally {
      if (tempOutputPath != null) {
        await CacheCleanupService.deleteIfTemporary(tempOutputPath);
      }
      if (mounted) setState(() => _isConverting = false);
    }
  }

  Widget _buildStatusIndicator(dynamic theme) {
    if (_statusMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          if (_isConverting || _isGeneratingPreview)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: theme.primary),
              ),
            ),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                  color: theme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.watch(currentThemeDataProvider);
    final totalDurationSec =
        widget.song.duration > 0 ? widget.song.duration / 1000.0 : 60.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editAudio),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: theme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status Indicator ──────────────────────────────────
            _buildStatusIndicator(theme),

            // ── Rename Section ────────────────────────────────────
            _buildRenameSection(theme),
            const SizedBox(height: 24),

            // ── File Name Display ──────────────────────────────────
            _buildFileNameHeader(theme),
            const SizedBox(height: 24),

            // ── Waveform + Trim Section ────────────────────────────
            _buildTrimSection(theme, totalDurationSec),
            const SizedBox(height: 8),

            // ── Playback Controls ──────────────────────────────────
            _buildPlaybackControls(theme, totalDurationSec),
            const SizedBox(height: 24),

            // ── Volume Control ─────────────────────────────────────
            _buildVolumeControl(theme),
            const SizedBox(height: 20),

            // ── Fade In / Fade Out ─────────────────────────────────
            _buildFadeControls(theme),
            const SizedBox(height: 20),

            // ── 8D Toggle ──────────────────────────────────────────
            _build8DToggle(theme),
            const SizedBox(height: 32),

            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  void _handleSeek(double dx, double width, double totalDuration) {
    if (width <= 0) return;
    double percent = (dx / width).clamp(0.0, 1.0);
    double targetSec = percent * totalDuration;

    // Check if within trim range
    if (targetSec < _startTrim) targetSec = _startTrim;
    if (targetSec > _endTrim) targetSec = _endTrim;

    _previewPlayer?.seek(Duration(milliseconds: (targetSec * 1000).toInt()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTIONS
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
              Text(AppLocalizations.of(context)!.renameFile,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            style: TextStyle(color: theme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterNewName,
              hintStyle: TextStyle(color: theme.onSurface.withAlpha(80)),
              filled: true,
              fillColor: theme.surface.withAlpha(80),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildFileNameHeader(dynamic theme) {
    final displayName = _truncateMiddle(widget.song.title, 32);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.music_note_rounded, color: theme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.song.artist}  •  ${_formatDuration(_endTrim - _startTrim)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.onSurface.withAlpha(120),
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.audio_file_rounded,
              color: theme.primary.withAlpha(80), size: 20),
        ],
      ),
    );
  }

  Widget _buildTrimSection(dynamic theme, double totalDuration) {
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
              Icon(Icons.content_cut_rounded, color: theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.trimAudio,
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
                  '${_formatDuration(_startTrim)} → ${_formatDuration(_endTrim)}',
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Waveform Visualization
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 100,
              child: _isLoadingWaveform
                  ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primary.withAlpha(100),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)!.loadingWaveform,
                            style: TextStyle(
                              color: theme.onSurface.withAlpha(80),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) => _handleSeek(
                              details.localPosition.dx,
                              constraints.maxWidth,
                              totalDuration),
                          onTapDown: (details) => _handleSeek(
                              details.localPosition.dx,
                              constraints.maxWidth,
                              totalDuration),
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, 100),
                            painter: _WaveformPainter(
                              waveformData: _waveformData,
                              primaryColor: theme.primary as Color,
                              inactiveColor:
                                  (theme.primary as Color).withAlpha(30),
                              trimStart: _startTrim / totalDuration,
                              trimEnd: _endTrim / totalDuration,
                              playbackPosition:
                                  _previewPosition.inMilliseconds /
                                      (totalDuration * 1000),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // Range Slider
          Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 8,
                  elevation: 4,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                trackHeight: 4,
              ),
              child: RangeSlider(
                values: RangeValues(_startTrim, _endTrim),
                min: 0,
                max: totalDuration,
                activeColor: theme.primary,
                inactiveColor: theme.primary.withAlpha(30),
                onChanged: (values) {
                  setState(() {
                    _startTrim = values.start;
                    _endTrim = values.end;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_startTrim),
                  style: TextStyle(
                    color: theme.onSurface.withAlpha(150),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${AppLocalizations.of(context)!.duration}: ${_formatDuration(_endTrim - _startTrim)}',
                  style: TextStyle(
                    color: theme.primary.withAlpha(180),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDuration(_endTrim),
                  style: TextStyle(
                    color: theme.onSurface.withAlpha(150),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(dynamic theme, double totalDuration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Seek backward 5s
        _controlButton(
          icon: Icons.replay_5_rounded,
          color: theme.onSurface.withAlpha(180),
          size: 28,
          onTap: () {
            final pos = _previewPosition - const Duration(seconds: 5);
            _previewPlayer?.seek(pos < Duration.zero ? Duration.zero : pos);
          },
        ),
        const SizedBox(width: 16),

        // Play / Pause
        GestureDetector(
          onTap: _togglePreview,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (theme.primary as Color).withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isPreviewPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Preview Effects Button
        _controlButton(
          icon: _isEffectsPreviewPlaying
              ? Icons.stop_circle_rounded
              : Icons.headphones_rounded,
          color: _isEffectsPreviewPlaying ? Colors.orangeAccent : theme.primary,
          size: 28,
          onTap: _isEffectsPreviewPlaying
              ? () => _effectsPreviewPlayer?.pause()
              : _generateAndPlayPreview,
        ),
        const SizedBox(width: 16),

        // Seek forward 5s
        _controlButton(
          icon: Icons.forward_5_rounded,
          color: theme.onSurface.withAlpha(180),
          size: 28,
          onTap: () {
            final maxMs = (_endTrim * 1000).toInt();
            final pos = _previewPosition + const Duration(seconds: 5);
            _previewPlayer?.seek(pos.inMilliseconds > maxMs
                ? Duration(milliseconds: maxMs)
                : pos);
          },
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }

  Widget _buildVolumeControl(dynamic theme) {
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
              Icon(
                _volume > 1.5
                    ? Icons.volume_up_rounded
                    : _volume > 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_mute_rounded,
                color: theme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.volume,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _volume == 1.0
                      ? theme.primary.withAlpha(20)
                      : _volume > 1.0
                          ? Colors.orange.withAlpha(20)
                          : Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(_volume * 100).toInt()}%',
                  style: TextStyle(
                    color: _volume == 1.0
                        ? theme.primary
                        : _volume > 1.0
                            ? Colors.orange
                            : Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('0%',
                  style: TextStyle(
                      color: theme.onSurface.withAlpha(80), fontSize: 10)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 3.0,
                    divisions: 30,
                    activeColor: _volume > 1.0 ? Colors.orange : theme.primary,
                    inactiveColor: theme.primary.withAlpha(30),
                    onChanged: (val) => setState(() => _volume = val),
                  ),
                ),
              ),
              Text('300%',
                  style: TextStyle(
                      color: theme.onSurface.withAlpha(80), fontSize: 10)),
            ],
          ),
          if (_volume > 2.0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.highVolumeWarning,
                    style: const TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFadeControls(dynamic theme) {
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
              Icon(Icons.tune_rounded, color: theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.fadeEffects,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),

          // Fade In
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: theme.primary.withAlpha(180), size: 16),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.fadeIn,
                        style: TextStyle(
                            color: theme.onSurface.withAlpha(180),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _fadeInSec,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    activeColor: theme.primary,
                    inactiveColor: theme.primary.withAlpha(30),
                    onChanged: (val) => setState(() => _fadeInSec = val),
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '${_fadeInSec.toStringAsFixed(1)}s',
                  style: TextStyle(
                    color: _fadeInSec > 0
                        ? theme.primary
                        : theme.onSurface.withAlpha(100),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Fade Out
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Row(
                  children: [
                    Icon(Icons.trending_down_rounded,
                        color: theme.primary.withAlpha(180), size: 16),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.fadeOut,
                        style: TextStyle(
                            color: theme.onSurface.withAlpha(180),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _fadeOutSec,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    activeColor: theme.primary,
                    inactiveColor: theme.primary.withAlpha(30),
                    onChanged: (val) => setState(() => _fadeOutSec = val),
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '${_fadeOutSec.toStringAsFixed(1)}s',
                  style: TextStyle(
                    color: _fadeOutSec > 0
                        ? theme.primary
                        : theme.onSurface.withAlpha(100),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build8DToggle(dynamic theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _is8D ? theme.primary.withAlpha(80) : theme.primary.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.spatial_audio_off_rounded,
                    color: theme.primary, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.eightDAudio,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                AppLocalizations.of(context)!.eightDDescription,
                style: TextStyle(
                  color: theme.onSurface.withAlpha(100),
                  fontSize: 12,
                ),
              ),
            ),
            value: _is8D,
            activeThumbColor: theme.primary,
            onChanged: (val) => setState(() => _is8D = val),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _is8D
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                            color: theme.onSurface.withAlpha(20), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.rotationSpeed,
                                style: TextStyle(
                                  color: theme.onSurface.withAlpha(180),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _speed8D < 0.1
                                    ? '${AppLocalizations.of(context)!.speedSlow} (<0.1 Hz)'
                                    : _speed8D > 0.3
                                        ? '${AppLocalizations.of(context)!.speedFast} (>${_speed8D.toStringAsFixed(1)} Hz)'
                                        : '${AppLocalizations.of(context)!.speedNormal} (${_speed8D.toStringAsFixed(2)} Hz)',
                                style: TextStyle(
                                  color: theme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.directions_walk_rounded,
                                color: theme.onSurface.withAlpha(80), size: 14),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12),
                                ),
                                child: Slider(
                                  value: _speed8D,
                                  min: 0.05,
                                  max: 0.50,
                                  divisions: 18,
                                  activeColor: theme.primary,
                                  inactiveColor: theme.primary.withAlpha(30),
                                  onChanged: (val) =>
                                      setState(() => _speed8D = val),
                                ),
                              ),
                            ),
                            Icon(Icons.directions_run_rounded,
                                color: theme.primary.withAlpha(180), size: 14),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 8D Intensity (Depth)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.effectIntensity,
                                style: TextStyle(
                                  color: theme.onSurface.withAlpha(180),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                            Text(
                              '${(_amount8D * 100).toInt()}%',
                              style: TextStyle(
                                color: theme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _amount8D,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            activeColor: theme.primary,
                            inactiveColor: theme.primary.withAlpha(30),
                            onChanged: (val) => setState(() => _amount8D = val),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 8D Reverb (Room Size)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.reverbDepth,
                                style: TextStyle(
                                  color: theme.onSurface.withAlpha(180),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                            Text(
                              _reverb8D < 0.2
                                  ? AppLocalizations.of(context)!.reverbSmall
                                  : _reverb8D > 0.7
                                      ? AppLocalizations.of(context)!
                                          .reverbLarge
                                      : AppLocalizations.of(context)!
                                          .reverbMedium,
                              style: TextStyle(
                                color: theme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _reverb8D,
                            min: 0.05,
                            max: 1.0,
                            divisions: 19,
                            activeColor: theme.primary,
                            inactiveColor: theme.primary.withAlpha(30),
                            onChanged: (val) => setState(() => _reverb8D = val),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic theme) {
    if (_isConverting) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.surface.withAlpha(120),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: theme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage ?? AppLocalizations.of(context)!.processing,
              style: TextStyle(
                  color: theme.onSurface, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
          ),
          onPressed: () => _processAudio(false),
          icon: const Icon(Icons.save_alt_rounded, size: 20),
          label: Text(AppLocalizations.of(context)!.saveAsNewFile,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _processAudio(true),
          icon: const Icon(Icons.sync_rounded, size: 20),
          label: Text(AppLocalizations.of(context)!.replaceOriginal,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Waveform Painter
// ═════════════════════════════════════════════════════════════════════════════
class _WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color primaryColor;
  final Color inactiveColor;
  final double trimStart; // 0.0 - 1.0
  final double trimEnd; // 0.0 - 1.0
  final double playbackPosition; // 0.0 - 1.0

  _WaveformPainter({
    required this.waveformData,
    required this.primaryColor,
    required this.inactiveColor,
    required this.trimStart,
    required this.trimEnd,
    required this.playbackPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) {
      // Draw placeholder bars
      _drawPlaceholder(canvas, size);
      return;
    }

    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;
    final maxHeight = size.height / 2 - 2;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth;
      final normalizedPos = i / waveformData.length;
      final isInTrimRange =
          normalizedPos >= trimStart && normalizedPos <= trimEnd;
      final isBeforePlayback = normalizedPos <= playbackPosition;

      Color barColor;
      if (isInTrimRange) {
        if (isBeforePlayback && playbackPosition > 0.001) {
          barColor = primaryColor;
        } else {
          barColor = primaryColor.withAlpha(120);
        }
      } else {
        barColor = inactiveColor;
      }

      final amplitude = waveformData[i].clamp(0.05, 1.0);
      final barHeight = amplitude * maxHeight;

      final paint = Paint()
        ..color = barColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(barWidth * 0.6, 1.5);

      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - barHeight),
        Offset(x + barWidth / 2, centerY + barHeight),
        paint,
      );
    }

    // Draw playback indicator line
    if (playbackPosition > 0.001 &&
        playbackPosition >= trimStart &&
        playbackPosition <= trimEnd) {
      final px = playbackPosition * size.width;
      final indicatorPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(px, 0),
        Offset(px, size.height),
        indicatorPaint,
      );
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final maxH = size.height / 2 - 4;
    const barCount = 60;
    final barWidth = size.width / barCount;
    final rng = Random(42);

    for (int i = 0; i < barCount; i++) {
      final amplitude = 0.1 + rng.nextDouble() * 0.5;
      final barHeight = amplitude * maxH;
      final x = i * barWidth;

      final paint = Paint()
        ..color = primaryColor.withAlpha(40)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(barWidth * 0.6, 1.5);

      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - barHeight),
        Offset(x + barWidth / 2, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.playbackPosition != playbackPosition ||
        oldDelegate.trimStart != trimStart ||
        oldDelegate.trimEnd != trimEnd ||
        oldDelegate.waveformData != waveformData ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
