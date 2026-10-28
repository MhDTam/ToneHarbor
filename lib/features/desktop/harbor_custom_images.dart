import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/artwork_preferences.dart';
import 'harbor_strings.dart';
import '../../core/utils/app_toast.dart';

final customPictureExistsProvider = FutureProvider.autoDispose
    .family<bool, String>((_, path) => File(path).exists());

Future<void> chooseHarborPicture(
    BuildContext context, WidgetRef ref, String key) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
      dialogTitle: harborText(context, 'Change picture'),
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await ref.read(artworkPreferencesProvider.notifier).setImage(key, path);
  } catch (e) {
    if (context.mounted) {
      AppToast.error(
          context, '${harborText(context, 'Could not load picture')}: $e');
    }
  }
}

/// The user's choice wins over a theme asset or embedded cover. Missing/corrupt
/// custom files recover to their normal fallback, with bounded image decoding.
class HarborCustomImage extends ConsumerWidget {
  final String imageKey;
  final Widget fallback;
  final double? width, height;
  final int cacheWidth;
  final BoxFit fit;
  const HarborCustomImage(
      {super.key,
      required this.imageKey,
      required this.fallback,
      this.width,
      this.height,
      this.cacheWidth = 960,
      this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref
        .watch(artworkPreferencesProvider.select((images) => images[imageKey]));
    if (path == null) return fallback;
    if (ref.watch(customPictureExistsProvider(path)).valueOrNull != true) {
      return fallback;
    }
    return Image.file(File(path),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback);
  }
}
