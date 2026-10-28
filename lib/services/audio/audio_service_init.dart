// This file is only used on mobile platforms.
// On Windows/desktop, ToneHarborAudioHandler is created directly.
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio_handler.dart';

Future<ToneHarborAudioHandler> initAudioService({
  Color? notificationColor,
}) async {
  try {
    await _trySetHighRefreshRate();
  } catch (_) {}

  return await AudioService.init(
    builder: () => ToneHarborAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.musiconvert.mp3noads.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      // Accent colour of the system media notification, taken from the theme
      // the user selected (Android still controls the card's background/layout,
      // and follows the phone's light/dark mode).
      notificationColor: notificationColor,
      // audio_service asserts `!androidNotificationOngoing || androidStopForegroundOnPause`:
      // an "ongoing" notification only makes sense while the service is in the
      // foreground. Pairing ongoing=true with stopForegroundOnPause=false made
      // AudioService.init() throw on startup, so the app never booted on
      // Android. When paused, the service drops to a lower priority state and
      // the notification can be dismissed.
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
      androidNotificationClickStartsActivity: true,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );
}

Future<void> _trySetHighRefreshRate() async {
  // flutter_displaymode - Android only, may fail silently
  try {
    // Placeholder - will only work on Android
  } catch (_) {}
}
