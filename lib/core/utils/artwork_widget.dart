import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'platform_utils.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio/artwork_provider.dart';
import '../../data/repositories/artwork_preferences.dart';
import '../../features/desktop/harbor_custom_images.dart';
import 'harbor_image_memory.dart';

/// Cross-platform artwork widget.
/// Fetches embedded or system artwork for a given song ID/path.
class PlatformArtworkWidget extends ConsumerWidget {
  final int id;
  final String? path; // New: path for metadata extraction fallback
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final Widget? nullArtworkWidget;
  final BoxFit artworkFit;

  const PlatformArtworkWidget({
    super.key,
    required this.id,
    this.path,
    this.size = 48,
    this.iconColor,
    this.backgroundColor,
    this.nullArtworkWidget,
    this.artworkFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A valid user cover bypasses embedded-art extraction entirely. Keep the
    // fallback lazy so scrolling custom-covered tracks starts no disk workers.
    if (isDesktop && path != null) {
      if (ref.watch(artworkPreferencesReadyProvider).isLoading) {
        return _buildFallback(context);
      }
      final custom = ref.watch(artworkPreferencesProvider
          .select((images) => images[trackPictureKey(path!)]));
      final exists = custom == null
          ? null
          : ref.watch(customPictureExistsProvider(custom));
      if (exists?.isLoading == true) return _buildFallback(context);
      if (custom != null && exists?.valueOrNull == true) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size < 80 ? 7 : 14),
          child: Image.file(File(custom),
              width: size,
              height: size,
              fit: artworkFit,
              cacheWidth: harborImageDecodeWidth(
                  size, MediaQuery.devicePixelRatioOf(context)),
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Consumer(
                  builder: (context, fallbackRef, _) =>
                      _embeddedArtwork(context, fallbackRef))),
        );
      }
    }
    return _embeddedArtwork(context, ref);
  }

  Widget _embeddedArtwork(BuildContext context, WidgetRef ref) {
    // Mobile: look the artwork up by MediaStore id (cheap). Desktop: read the
    // embedded picture from the file. Songs without a real MediaStore id (e.g.
    // a file opened through "Open with") read the embedded picture instead.
    final useMediaStoreId = isMobile && isValidMediaStoreId(id);
    final AsyncValue<Uint8List?> artworkAsync = useMediaStoreId
        ? ref.watch(artworkBytesByIdProvider(id))
        : (path != null
            ? ref.watch(artworkBytesProvider(path!))
            : const AsyncData<Uint8List?>(null));

    final artwork = artworkAsync.when(
      data: (bytes) {
        if (bytes != null && bytes.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size < 80 ? 7 : 14),
            child: Image(
              image: ResizeImage(HarborMemoryImage(bytes),
                  width: harborImageDecodeWidth(
                      size, MediaQuery.devicePixelRatioOf(context))),
              width: size,
              height: size,
              fit: artworkFit,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => _buildFallback(context),
            ),
          );
        }
        return isMobile
            ? _buildFallback(context)
            : _buildMobileOrFallback(context);
      },
      loading: () => _buildFallback(context),
      error: (_, __) => _buildFallback(context),
    );
    return artwork;
  }

  Widget _buildMobileOrFallback(BuildContext context) {
    if (isDesktop) return _buildFallback(context);

    return _MobileArtworkBuilder(
      id: id,
      size: size,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      nullArtworkWidget: nullArtworkWidget,
      artworkFit: artworkFit,
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (nullArtworkWidget != null) return nullArtworkWidget!;
    return _DesktopArtwork(
      size: size,
      iconColor: iconColor ?? Theme.of(context).colorScheme.primary,
      backgroundColor: backgroundColor ??
          Theme.of(context).colorScheme.primary.withAlpha(30),
    );
  }
}

class _DesktopArtwork extends StatelessWidget {
  final double size;
  final Color iconColor;
  final Color backgroundColor;

  const _DesktopArtwork({
    required this.size,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.6,
          color: iconColor.withAlpha(180),
        ),
      ),
    );
  }
}

class _MobileArtworkBuilder extends StatelessWidget {
  final int id;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final Widget? nullArtworkWidget;
  final BoxFit artworkFit;

  const _MobileArtworkBuilder({
    required this.id,
    required this.size,
    this.iconColor,
    this.backgroundColor,
    this.nullArtworkWidget,
    this.artworkFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return nullArtworkWidget ??
          _DesktopArtwork(
            size: size,
            iconColor: iconColor ?? Theme.of(context).colorScheme.primary,
            backgroundColor: backgroundColor ??
                Theme.of(context).colorScheme.primary.withAlpha(30),
          );
    }

    return QueryArtworkWidget(
      id: id,
      type: ArtworkType.AUDIO,
      size: size.toInt(),
      artworkBorder: BorderRadius.circular(size * 0.2),
      artworkFit: artworkFit,
      nullArtworkWidget: nullArtworkWidget ??
          _DesktopArtwork(
            size: size,
            iconColor: iconColor ?? Theme.of(context).colorScheme.primary,
            backgroundColor: backgroundColor ??
                Theme.of(context).colorScheme.primary.withAlpha(30),
          ),
    );
  }
}
