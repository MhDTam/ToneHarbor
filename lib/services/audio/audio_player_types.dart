/// Cross-platform processing state enum
enum AppProcessingState { idle, loading, buffering, ready, completed }

/// Simple media item info class that works cross-platform
class MediaItemInfo {
  final int id;
  final String filePath;
  final String? album;
  final String title;
  final String? artist;
  final Duration? duration;
  final int albumId;
  final Uri? artUri;

  const MediaItemInfo({
    this.id = 0,
    this.filePath = '',
    this.album,
    this.title = '',
    this.artist,
    this.duration,
    this.albumId = 0,
    this.artUri,
  });
}

/// Simple playback state that works cross-platform
class PlaybackStateInfo {
  final bool playing;
  final AppProcessingState processingState;
  final Duration position;
  final double speed;

  const PlaybackStateInfo({
    this.playing = false,
    this.processingState = AppProcessingState.idle,
    this.position = Duration.zero,
    this.speed = 1.0,
  });
}
