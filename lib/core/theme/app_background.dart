import 'package:flutter/material.dart';
import 'app_themes.dart';

/// Full-screen themed background.
///
/// Draws the theme gradient and, when the theme has one, an artwork image on
/// top. The image is covered by a top/bottom gradient scrim (not a flat tint)
/// so the artwork stays vivid in the middle while headers and the bottom bar
/// remain readable. Falls back to the gradient if the image asset is missing.
class AppBackground extends StatelessWidget {
  final AppThemeData theme;
  final Widget child;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const AppBackground({
    super.key,
    required this.theme,
    required this.child,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    final image = theme.backgroundImage;
    if (image == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: theme.gradientColors,
          ),
        ),
        child: child,
      );
    }

    final bg = theme.background;
    return Container(
      color: bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: theme.gradientColors,
                ),
              ),
            ),
          ),
          // Optional uniform darkening of the artwork (per theme).
          if (theme.backgroundImageOverlay > 0)
            ColoredBox(color: bg.withAlpha(theme.backgroundImageOverlay)),
          // Vertical scrim: dark behind the header and bottom navigation,
          // almost clear in the middle so the artwork is not washed out.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bg.withAlpha(215),
                  bg.withAlpha(40),
                  bg.withAlpha(35),
                  bg.withAlpha(225),
                ],
                stops: const [0.0, 0.30, 0.62, 1.0],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
