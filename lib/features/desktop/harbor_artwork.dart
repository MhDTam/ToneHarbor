import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'harbor_themes.dart';
import 'harbor_custom_images.dart';
import '../../data/repositories/artwork_preferences.dart';
import '../../core/utils/harbor_image_memory.dart';

String harborPlantAsset(HarborTheme theme) => theme == HarborTheme.forest
    ? 'assets/images/harbor/window-cover-v2.webp'
    : 'assets/images/harbor/themed/${theme.name}-window-cover-v22.webp';

class HarborArtwork extends ConsumerWidget {
  final double size;
  final int seed;
  final bool playlist;
  final bool playback;
  const HarborArtwork(
      {super.key,
      required this.size,
      this.seed = 0,
      this.playlist = false,
      this.playback = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = playback
        ? ref.watch(
            artworkPreferencesProvider.select(PlaybackCover.fromPreferences))
        : PlaybackCover.waveform;
    final width = harborImageDecodeWidth(
        size, MediaQuery.devicePixelRatioOf(context),
        maximum: 1024);
    return RepaintBoundary(
        child: ClipRRect(
      borderRadius: BorderRadius.circular(size < 80 ? 7 : 14),
      child: HarborCustomImage(
        imageKey: playlist
            ? 'default:playlist'
            : playback
                ? 'default:player'
                : 'default:track',
        width: size,
        height: size,
        cacheWidth: width,
        fallback:
            HarborCoverImage(size: size, cover: cover, playlist: playlist),
      ),
    ));
  }
}

/// Built-in choices, also used by settings previews without custom overrides.
class HarborCoverImage extends ConsumerWidget {
  final double size;
  final PlaybackCover cover;
  final bool playlist;
  const HarborCoverImage(
      {super.key,
      required this.size,
      required this.cover,
      this.playlist = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(harborThemeProvider);
    final asset = playlist || cover == PlaybackCover.waveform
        ? 'assets/images/harbor/defaults/${theme.name}-${playlist ? 'playlist' : 'track'}.png'
        : harborPlantAsset(theme);
    return ColoredBox(
      color: theme.background,
      child: Image.asset(asset,
          key: const ValueKey('harbor-audio-artwork'),
          width: size,
          height: size,
          cacheWidth: harborImageDecodeWidth(
              size, MediaQuery.devicePixelRatioOf(context), maximum: 1024),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => CustomPaint(
              size: Size.square(size),
              painter: HarborAudioCoverPainter(theme, playlist: playlist))),
    );
  }
}

/// Code-native waveform artwork. Each theme has its own exported default, and
/// this painter also provides a no-I/O recovery path.
class HarborAudioCoverPainter extends CustomPainter {
  final HarborTheme theme;
  final bool playlist;
  const HarborAudioCoverPainter(this.theme, {this.playlist = false});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, accent = theme.accent;
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.35, -.45),
            radius: 1.25,
            colors: [
              Color.lerp(theme.background, accent, .19)!,
              theme.background
            ],
          ).createShader(rect));
    final center = Offset(w * .5, h * (playlist ? .45 : .5));
    final line = Paint()
      ..color = accent.withAlpha(24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .002;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(center, w * (.23 + i * .075), line);
    }
    const amplitudes = [
      .13,
      .25,
      .42,
      .29,
      .64,
      .92,
      .52,
      .78,
      .4,
      .57,
      .26,
      .35,
      .13
    ];
    final bar = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * .024;
    for (var i = 0; i < amplitudes.length; i++) {
      final x = w * .23 + i * w * .045;
      final length = h * .30 * amplitudes[i];
      bar.shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent, Color.lerp(accent, theme.background, .35)!])
          .createShader(
              Rect.fromLTWH(x, center.dy - h * .17, w * .03, h * .34));
      canvas.drawLine(Offset(x, center.dy - length / 2),
          Offset(x, center.dy + length / 2), bar);
    }
    if (playlist) {
      final paint = Paint()
        ..color = accent.withAlpha(110)
        ..strokeWidth = w * .012
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = h * (.72 + i * .045);
        canvas.drawLine(
            Offset(w * .38, y), Offset(w * (.63 - i * .035), y), paint);
        canvas.drawCircle(
            Offset(w * .32, y), math.max(1, w * .008), Paint()..color = accent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HarborAudioCoverPainter old) =>
      old.theme != theme || old.playlist != playlist;
}
