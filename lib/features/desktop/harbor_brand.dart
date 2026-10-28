import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'harbor_themes.dart';

/// Shift hue while retaining white specular highlights, contrast and alpha.
/// This avoids flattening the glossy source into a monochrome tinted image.
ColorFilter harborBrandHue(Color accent) {
  final hue = HSVColor.fromColor(accent).hue;
  final sourceHue = HSVColor.fromColor(const Color(0xFF0BCFC5)).hue;
  final angle = (hue - sourceHue) * math.pi / 180;
  final c = math.cos(angle), s = math.sin(angle);
  final matrix = <double>[
    .213 + .787 * c - .213 * s,
    .715 - .715 * c - .715 * s,
    .072 - .072 * c + .928 * s,
    0,
    0,
    .213 - .213 * c + .143 * s,
    .715 + .285 * c + .140 * s,
    .072 - .072 * c - .283 * s,
    0,
    0,
    .213 - .213 * c - .787 * s,
    .715 - .715 * c + .715 * s,
    .072 + .928 * c + .072 * s,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  // Keep the theme's softer saturation without flattening white reflections.
  final saturation = (HSVColor.fromColor(accent).saturation /
          HSVColor.fromColor(const Color(0xFF0BCFC5)).saturation)
      .clamp(.65, 1.0);
  const luminance = [.213, .715, .072];
  for (var row = 0; row < 3; row++) {
    for (var column = 0; column < 3; column++) {
      final index = row * 5 + column;
      matrix[index] =
          matrix[index] * saturation + luminance[column] * (1 - saturation);
    }
  }
  return ColorFilter.matrix(matrix);
}

class HarborBrandMark extends ConsumerWidget {
  final double size;
  const HarborBrandMark({super.key, this.size = 44});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(harborThemeProvider).accent;
    final decodeWidth = (size * MediaQuery.devicePixelRatioOf(context) * 4)
        .ceil()
        .clamp(128, 768);
    return RepaintBoundary(
        child: ColorFiltered(
      key: const ValueKey('app-brand-tint'),
      colorFilter: harborBrandHue(accent),
      child: SizedBox.square(
          dimension: size,
          child: ClipOval(
              clipBehavior: Clip.antiAlias,
              child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const RadialGradient(
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent
                        ],
                        stops: [0, .935, 1],
                      ).createShader(rect),
                  child: Transform.scale(
                      scale: 1.08,
                      child: Image.asset(
                          'assets/images/harbor/brand-glossy-v9.png',
                          key: const ValueKey('app-brand-mark'),
                          width: size,
                          height: size,
                          fit: BoxFit.contain,
                          // Mipmaps preserve the fine grooves when shrinking the large master.
                          filterQuality: FilterQuality.medium,
                          isAntiAlias: true,
                          cacheWidth: decodeWidth))))),
    ));
  }
}
