import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/repositories/custom_library_repository.dart';
import '../../services/ffmpeg_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../core/utils/app_toast.dart';
import '../../services/audio/artwork_provider.dart';
import '../../l10n/app_localizations.dart';

class MetadataEditorScreen extends ConsumerStatefulWidget {
  final SongModel song;

  const MetadataEditorScreen({super.key, required this.song});

  @override
  ConsumerState<MetadataEditorScreen> createState() =>
      _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends ConsumerState<MetadataEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _artistCtrl;
  late TextEditingController _albumCtrl;

  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.song.title);
    _artistCtrl = TextEditingController(
        text: (widget.song.artist == '<unknown>' ||
                widget.song.artist == 'Unknown Artist')
            ? ''
            : widget.song.artist);
    _albumCtrl = TextEditingController(
        text: (widget.song.album == '<unknown>' ||
                widget.song.album == 'Unknown Album')
            ? ''
            : widget.song.album);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      final pickedPath = result?.files.single.path;
      if (pickedPath != null && mounted) {
        setState(() {
          _selectedImagePath = pickedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, '${AppLocalizations.of(context)!.failedPickImage}: $e');
      }
    }
  }

  Future<void> _saveMetadata() async {
    if (_titleCtrl.text.trim().isEmpty) {
      AppToast.error(context, AppLocalizations.of(context)!.titleEmptyError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (Platform.isAndroid && isMobile) {
        if (!await Permission.audio.isGranted) {
          await Permission.audio.request();
        }
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
      }

      final ffmpeg = ref.read(ffmpegServiceProvider);
      final file = File(widget.song.data);
      if (!await file.exists()) {
        throw Exception('Original file not found');
      }

      // Keep the source container: `-c copy` cannot write MP3 data into a
      // .m4a/.flac/.wav file, FFmpeg aborts with "Could not write header".
      final sourceExt = p.extension(widget.song.data);
      final tempPath = p.join(
        Directory.systemTemp.path,
        'meta_${DateTime.now().millisecondsSinceEpoch}$sourceExt',
      );

      // Execute FFmpeg metadata update
      final newPath = await ffmpeg.updateAudioMetadata(
        inputPath: widget.song.data,
        outputPath: tempPath,
        title: _titleCtrl.text.trim(),
        artist: _artistCtrl.text.trim(),
        album: _albumCtrl.text.trim(),
        imagePath: _selectedImagePath,
      );

      if (newPath != null) {
        final tempFile = File(newPath);
        // Safe move: write to same directory
        final finalPath = widget.song.data;

        String actualFinalPath = finalPath;
        if (isDesktop) {
          // Stage beside the original so the final renames stay on one volume.
          // Keep a backup until the replacement has succeeded.
          final staged = File(
              '$finalPath.toneharbor-stage-${DateTime.now().microsecondsSinceEpoch}');
          final backupPath =
              '$finalPath.toneharbor-backup-${DateTime.now().microsecondsSinceEpoch}';
          await tempFile.copy(staged.path);
          if (ref.read(audioPlayerProvider).currentSong?.id == widget.song.id) {
            await ref.read(audioPlayerProvider.notifier).stop();
          }
          await file.rename(backupPath);
          try {
            await staged.rename(finalPath);
          } catch (_) {
            await File(backupPath).rename(finalPath);
            rethrow;
          }
          try {
            await File(backupPath).delete();
          } catch (e) {
            debugPrint('Metadata backup retained: $e');
          }
          try {
            await tempFile.delete();
          } catch (_) {}
        } else {
          try {
            await tempFile.copy(finalPath);
            await tempFile.delete();
          } catch (e) {
            try {
              await tempFile.rename(finalPath);
            } catch (_) {
              try {
                final musicDir =
                    Directory('/storage/emulated/0/Music/MusiConvert');
                if (!await musicDir.exists()) {
                  await musicDir.create(recursive: true);
                }
                final safeTitle = _titleCtrl.text
                    .trim()
                    .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                actualFinalPath = p.join(musicDir.path, '$safeTitle$sourceExt');
                await tempFile.copy(actualFinalPath);
                await tempFile.delete();
              } catch (_) {}
            }
          }
        }

        if (_titleCtrl.text.trim().isNotEmpty) {
          await ref
              .read(customLibraryProvider.notifier)
              .setSongTitle(actualFinalPath, _titleCtrl.text.trim());
        }

        if (isMobile) {
          try {
            final aq = OnAudioQuery();
            await aq.scanMedia(actualFinalPath);
            if (actualFinalPath != finalPath) await aq.scanMedia(finalPath);
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (_) {}
        }

        // Refresh library and artwork
        ref.invalidate(songLibraryProvider);
        ref.invalidate(artworkBytesProvider(widget.song.data));
        if (isMobile) ref.invalidate(artworkBytesByIdProvider(widget.song.id));

        if (mounted) {
          AppToast.success(
              context, AppLocalizations.of(context)!.audioSavedSuccess);
          context.pop();
        }
      } else {
        throw Exception('FFmpeg failed to update metadata');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
            context, '${AppLocalizations.of(context)!.audioSavedError}: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final primary = theme.primary;

    // Combine current existing art with the selected image
    final artworkAsync = (isMobile && isValidMediaStoreId(widget.song.id))
        ? ref.watch(artworkBytesByIdProvider(widget.song.id))
        : ref.watch(artworkBytesProvider(widget.song.data));

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editInfo),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isSaving)
            TextButton.icon(
              onPressed: _saveMetadata,
              icon: Icon(Icons.check_rounded, color: primary),
              label: Text(AppLocalizations.of(context)!.save,
                  style:
                      TextStyle(color: primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primary),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.savingChanges),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickCoverImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: primary.withAlpha(50), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withAlpha(20),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _selectedImagePath != null
                                ? Image.file(File(_selectedImagePath!),
                                    fit: BoxFit.cover)
                                : artworkAsync.when(
                                    data: (bytes) {
                                      if (bytes != null && bytes.isNotEmpty) {
                                        return Image.memory(bytes,
                                            fit: BoxFit.cover);
                                      }
                                      return Icon(Icons.library_music_rounded,
                                          size: 80,
                                          color: primary.withAlpha(100));
                                    },
                                    loading: () => const Center(
                                        child: CircularProgressIndicator()),
                                    error: (_, __) => Icon(
                                        Icons.library_music_rounded,
                                        size: 80,
                                        color: primary.withAlpha(100)),
                                  ),
                          ),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(100),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_rounded,
                                    color: Colors.white, size: 36),
                                const SizedBox(height: 8),
                                Text(AppLocalizations.of(context)!.changeCover,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildTextField(
                    label: AppLocalizations.of(context)!.trackTitle,
                    ctrl: _titleCtrl,
                    icon: Icons.title_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: AppLocalizations.of(context)!.artistName,
                    ctrl: _artistCtrl,
                    icon: Icons.person_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: AppLocalizations.of(context)!.albumTitle,
                    ctrl: _albumCtrl,
                    icon: Icons.album_rounded,
                    theme: theme,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController ctrl,
      required IconData icon,
      required dynamic theme}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.primary),
        filled: true,
        fillColor: theme.surface.withAlpha(120),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.primary.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.primary),
        ),
      ),
    );
  }
}
