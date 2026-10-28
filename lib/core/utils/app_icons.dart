import 'package:flutter/material.dart';

/// Centralized app icons with corrections for Flutter RTL mirroring bugs.
abstract class AppIcons {
  /// Queue music icon with [matchTextDirection: false].
  /// Standard Flutter [Icons.queue_music_rounded] has [matchTextDirection: true],
  /// which in RTL languages (Arabic, Persian) mirrors the icon horizontally,
  /// causing the musical note (♪) to be flipped backwards and inverted.
  static const IconData queueMusic = IconData(
    0xf00d0,
    fontFamily: 'MaterialIcons',
    matchTextDirection: false,
  );
}
