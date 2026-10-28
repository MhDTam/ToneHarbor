import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../features/desktop/harbor_media_engine.dart';

final ffmpegServiceProvider = Provider((ref) => FFmpegService());

class FFmpegService {
  /// Result of FFmpeg operation
  /// [path] is non-null on success. [error] is non-null on failure.
  Future<({String? path, String? error, FFmpegSession? session})>
      convertVideoToAudio(
    String inputPath,
    String outputPath, {
    String? title,
    String? subtitle,
    double? totalDurationSec,
    String codec = 'libmp3lame',
    void Function(double progressSec)? onProgress,
    void Function(int sessionId)? onSessionStarted,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return (path: null, error: "Unsupported platform.", session: null);
    }

    // Check if input file exists
    if (!await File(inputPath).exists()) {
      return (path: null, error: "Input video file not found.", session: null);
    }

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // Fast path: when the source audio codec already matches the target, copy
    // the stream instead of re-encoding. This is near-instant and lossless.
    final sourceCodec = await _audioCodec(inputPath);
    final isAac = codec == 'aac';
    final canCopy = sourceCodec != null &&
        ((isAac && sourceCodec == 'aac') || (!isAac && sourceCodec == 'mp3'));

    final List<String> codecArgs;
    if (canCopy) {
      codecArgs = ["-c:a", "copy"];
    } else if (isAac) {
      codecArgs = ["-c:a", "aac", "-b:a", "192k"];
    } else {
      codecArgs = ["-c:a", "libmp3lame", "-q:a", "2"];
    }

    final args = [
      "-y",
      // Let FFmpeg decide how many threads to use for decoding.
      "-threads", "0",
      "-i", inputPath,
      "-vn",
      if (title != null) ...["-metadata", "title=$title"],
      "-metadata", "comment=Converted on $dateStr",
      ...codecArgs,
      outputPath
    ];

    final completer = Completer<ReturnCode?>();
    DateTime lastNotificationUpdate = DateTime.fromMillisecondsSinceEpoch(0);

    final displayTitle = title ?? 'ToneHarbor';
    final displaySubtitle = subtitle ?? 'Converting video to audio...';

    // Keep the CPU awake and start the Foreground Service so conversion survives
    // the screen locking or app moving to the background without getting frozen.
    await _acquireWakeLock(title: displayTitle, subtitle: displaySubtitle);
    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        args,
        (completedSession) async {
          final rc = await completedSession.getReturnCode();
          if (!completer.isCompleted) completer.complete(rc);
        },
        (log) {
          debugPrint('FFmpeg log: ${log.getMessage()}');
        },
        (statistics) {
          if (statistics.getTime() >= 0) {
            final sec = statistics.getTime() / 1000.0;
            if (onProgress != null) onProgress(sec);

            final now = DateTime.now();
            if (now.difference(lastNotificationUpdate) >=
                const Duration(seconds: 1)) {
              lastNotificationUpdate = now;
              final progress =
                  (totalDurationSec != null && totalDurationSec > 0)
                      ? (sec / totalDurationSec * 100).clamp(0, 100).toInt()
                      : -1;
              _updateProgress(
                progress,
                title: displayTitle,
                subtitle: displaySubtitle,
              );
            }
          }
        },
      );

      // Publish the session id as soon as it exists: the cancel button needs it
      // while the conversion is still running (it used to be assigned only after
      // completion, which made cancelling impossible).
      final startedSessionId = session.getSessionId();
      if (startedSessionId != null) onSessionStarted?.call(startedSessionId);

      final returnCode = await completer.future.timeout(
        const Duration(minutes: 15),
        onTimeout: () => null,
      );

      // A timed out session would keep encoding and keep writing the file.
      if (returnCode == null) {
        _cancelSession(session);
      }

      if (ReturnCode.isSuccess(returnCode)) {
        // Callers move the file to its final destination and scan it there, so
        // scanning this (temporary) path would only add phantom MediaStore rows.
        return (path: outputPath, error: null, session: session);
      }

      if (ReturnCode.isCancel(returnCode)) {
        return (path: null, error: "CANCELLED", session: session);
      }

      // Detailed error logging
      final logs = await session.getAllLogs();
      final errorMsg =
          logs.reversed.take(5).map((l) => l.getMessage()).join("\n");
      debugPrint('FFmpeg conversion failed: $errorMsg');

      if (returnCode == null) {
        return (path: null, error: "Conversion timed out.", session: session);
      }
      return (
        path: null,
        error: errorMsg.isNotEmpty ? errorMsg : "Unknown FFmpeg error.",
        session: session
      );
    } finally {
      await _releaseWakeLock();
    }
  }

  /// Audio codec name of the first audio stream, or null when it cannot be
  /// determined.
  Future<String?> _audioCodec(String inputPath) async {
    try {
      final info = await FFprobeKit.getMediaInformation(inputPath);
      final media = info.getMediaInformation();
      if (media == null) return null;
      for (final stream in media.getStreams()) {
        if (stream.getType() == 'audio') return stream.getCodec();
      }
    } catch (e) {
      debugPrint('FFprobe audio codec detection failed: $e');
    }
    return null;
  }

  static const MethodChannel _lockChannel =
      MethodChannel('com.musiconvert.mp3noads/lock');

  Future<void> _acquireWakeLock({String? title, String? subtitle}) async {
    if (!Platform.isAndroid) return;
    try {
      await _lockChannel.invokeMethod('acquireWakeLock', {
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      });
    } catch (_) {}
  }

  Future<void> _updateProgress(int progress,
      {String? title, String? subtitle}) async {
    if (!Platform.isAndroid) return;
    try {
      await _lockChannel.invokeMethod('updateConversionProgress', {
        'progress': progress,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      });
    } catch (_) {}
  }

  Future<void> showCompletionNotification({
    required String title,
    required String message,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _lockChannel.invokeMethod('showCompletionNotification', {
        'title': title,
        'message': message,
      });
    } catch (_) {}
  }

  Future<void> _releaseWakeLock() async {
    if (!Platform.isAndroid) return;
    try {
      await _lockChannel.invokeMethod('releaseWakeLock');
    } catch (_) {}
  }

  /// Get Duration of a video or audio file using FFprobeKit.
  Future<double> getDuration(String path) async {
    final info = await FFprobeKit.getMediaInformation(path);
    final mediaInfo = info.getMediaInformation();
    if (mediaInfo == null) return 0;

    final durationStr = mediaInfo.getDuration();
    if (durationStr == null) return 0;

    return double.tryParse(durationStr) ?? 0;
  }

  /// Extract a thumbnail from a video file.
  /// Saves the thumbnail to the system temp directory and returns its path.
  Future<String?> extractThumbnail(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath =
        '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final args = [
      "-y",
      "-i", videoPath,
      "-ss", "00:00:01", // Capture at 1 second
      "-vframes", "1",
      "-s", "256x256",
      thumbPath
    ];

    final session = await FFmpegKit.executeWithArguments(args);
    final rc = await session.getReturnCode();

    if (ReturnCode.isSuccess(rc)) {
      return thumbPath;
    }
    return null;
  }

  /// Cancels a session that is still running. `getSessionId()` is nullable and
  /// therefore cannot be passed to [FFmpegKit.cancel] directly.
  void _cancelSession(FFmpegSession session) {
    final id = session.getSessionId();
    if (id != null) FFmpegKit.cancel(id);
  }

  /// Cancel an ongoing session.
  void cancelSession(int? sessionId) {
    if (sessionId != null) {
      FFmpegKit.cancel(sessionId);
    } else {
      FFmpegKit.cancel();
    }
  }

  Future<String?> editAudio(
    String inputPath,
    String outputPath, {
    Duration? start,
    Duration? end,
    double volume = 1.0,
    bool is8D = false,
    double speed8D = 0.125,
    double amount8D = 1.0,
    double reverb8D = 0.3,
    double fadeInSec = 0.0,
    double fadeOutSec = 0.0,
    String? title,
    void Function(double progressSec)? onProgress,
    void Function(int sessionId)? onSessionStarted,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError("FFmpeg not supported on this platform.");
    }

    final List<String> args = ["-y"];

    if (start != null) {
      args.addAll(["-ss", "${start.inMilliseconds / 1000.0}"]);
    }
    if (end != null) {
      final double duration =
          (end.inMilliseconds - (start?.inMilliseconds ?? 0)) / 1000.0;
      args.addAll(["-t", "$duration"]);
    }

    args.addAll(["-threads", "0", "-i", inputPath]);

    List<String> filters = [];
    if (volume != 1.0) {
      filters.add("volume=$volume");
    }
    if (is8D) {
      // Professional 8D sound:
      // 1. aecho: simulates spatial reverb/room size
      // delays: scaled between 50ms (small room) and 2000ms (large stage)
      // decays: scaled between 0.1 and 0.8
      final double delay8D = 50 + (reverb8D * 1950);
      final double decay8D = 0.1 + (reverb8D * 0.7);

      // 2. apulsator: handles the panning (rotation)
      // hz determines the speed
      // amount determines the intensity (depth of panning)
      filters.add(
          "aecho=0.8:0.9:$delay8D:$decay8D,apulsator=hz=$speed8D:amount=$amount8D");
    }
    if (fadeInSec > 0) {
      filters.add("afade=t=in:st=0:d=$fadeInSec");
    }
    if (fadeOutSec > 0) {
      // Calculate the start time of fade out relative to the trimmed segment
      final trimmedDuration =
          (end != null ? end.inMilliseconds / 1000.0 : 0.0) -
              (start != null ? start.inMilliseconds / 1000.0 : 0.0);
      if (trimmedDuration > fadeOutSec) {
        final fadeOutStart = trimmedDuration - fadeOutSec;
        filters.add("afade=t=out:st=$fadeOutStart:d=$fadeOutSec");
      }
    }

    if (filters.isNotEmpty) {
      args.addAll(["-af", filters.join(",")]);
    }

    if (title != null && title.isNotEmpty) {
      args.addAll(["-metadata", "title=$title"]);
    }

    // Determine the codec from the output extension. Everything that is not
    // listed used to fall back to libmp3lame, which made FFmpeg abort with
    // "Could not write header" for e.g. .flac / .ogg / .opus / .wma outputs.
    final ext = outputPath.toLowerCase();
    if (ext.endsWith('.m4a') || ext.endsWith('.mp4') || ext.endsWith('.aac')) {
      args.addAll(["-c:a", "aac", "-b:a", "192k"]);
    } else if (ext.endsWith('.wav')) {
      args.addAll(["-c:a", "pcm_s16le"]);
    } else if (ext.endsWith('.flac')) {
      args.addAll(["-c:a", "flac"]);
    } else if (ext.endsWith('.ogg') || ext.endsWith('.opus')) {
      args.addAll(["-c:a", "libvorbis", "-q:a", "5"]);
    } else if (ext.endsWith('.wma')) {
      args.addAll(["-c:a", "wmav2", "-b:a", "192k"]);
    } else {
      args.addAll(["-c:a", "libmp3lame", "-q:a", "2"]);
    }

    args.add(outputPath);

    final completer = Completer<ReturnCode?>();

    await _acquireWakeLock(
        title: title != null ? 'Editing: $title' : 'Editing audio...');
    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        args,
        (completedSession) async {
          final rc = await completedSession.getReturnCode();
          if (!completer.isCompleted) completer.complete(rc);
        },
        (log) {
          debugPrint('FFmpeg edit log: ${log.getMessage()}');
        },
        (statistics) {
          if (onProgress != null && statistics.getTime() >= 0) {
            onProgress(statistics.getTime() / 1000.0);
          }
        },
      );

      final startedSessionId = session.getSessionId();
      if (startedSessionId != null) onSessionStarted?.call(startedSessionId);

      final returnCode = await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => null,
      );
      if (returnCode == null) _cancelSession(session);
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      }

      // Log errors on failure
      final logs = await session.getAllLogs();
      final errorMsg =
          logs.reversed.take(10).map((l) => l.getMessage()).join("\n");
      debugPrint('FFmpeg edit failure: $errorMsg');

      throw Exception('FFmpeg failed (see logs): $errorMsg');
    } finally {
      await _releaseWakeLock();
    }
  }

  /// Extract waveform amplitude data from an audio file using FFmpeg.
  /// Returns a list of normalized amplitude values (0.0 - 1.0).
  Future<List<double>> extractWaveform(String inputPath,
      {int samplesCount = 200}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return [];

    // Use the astats filter to get per-sample RMS values, sample every N frames
    // Simple approach: use volumedetect and parse peaks, or use
    // the showwavespic approach to get an image and parse pixels.
    // Best lightweight approach: use -af "aformat=channel_layouts=mono,
    // compand" and read raw PCM data.

    // We'll use FFmpeg to output raw mono 8-bit PCM data and read the amplitude directly.
    final tempDir = Directory.systemTemp;
    final rawPath =
        '${tempDir.path}/waveform_${DateTime.now().millisecondsSinceEpoch}.raw';

    // Use low sample rate to get manageable amount of data, then downsample to target
    final args = [
      "-y",
      "-i", inputPath,
      "-ac", "1",
      "-ar", "200", // 200 Hz - gives us 200 samples per second
      "-f", "u8",
      "-acodec", "pcm_u8",
      rawPath,
    ];

    final completer = Completer<ReturnCode?>();
    final session = await FFmpegKit.executeWithArgumentsAsync(
      args,
      (completedSession) async {
        final rc = await completedSession.getReturnCode();
        if (!completer.isCompleted) completer.complete(rc);
      },
      (l) {},
      (st) {},
    );

    final returnCode = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => null,
    );

    if (!ReturnCode.isSuccess(returnCode)) {
      if (returnCode == null) _cancelSession(session);
      // Never leave partially written temp data behind.
      try {
        final rawFile = File(rawPath);
        if (await rawFile.exists()) await rawFile.delete();
      } catch (_) {}
      return [];
    }

    try {
      final rawFile = File(rawPath);
      if (!await rawFile.exists()) return [];

      final bytes = await rawFile.readAsBytes();
      await rawFile.delete();

      if (bytes.isEmpty) return [];

      // Downsample to desired count
      final List<double> waveform = [];
      final chunkSize =
          (bytes.length / samplesCount).ceil().clamp(1, bytes.length);

      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, bytes.length);
        double maxVal = 0;
        for (int j = i; j < end; j++) {
          // Convert unsigned 8-bit (0-255, center at 128) to amplitude
          final amplitude = (bytes[j] - 128).abs() / 128.0;
          if (amplitude > maxVal) maxVal = amplitude;
        }
        waveform.add(maxVal);
      }

      // Trim or pad to exact count
      while (waveform.length > samplesCount) {
        waveform.removeLast();
      }
      while (waveform.length < samplesCount) {
        waveform.add(0.0);
      }

      return waveform;
    } catch (e) {
      debugPrint('Waveform extraction error: $e');
      return [];
    }
  }

  Future<String?> renameAndTagAudio(
    String inputPath,
    String outputPath,
    String newTitle,
  ) async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;

    final args = [
      "-y",
      "-i",
      inputPath,
      "-map",
      "0",
      "-c",
      "copy",
      "-metadata",
      "title=$newTitle",
      outputPath
    ];

    final completer = Completer<ReturnCode?>();

    final session = await FFmpegKit.executeWithArgumentsAsync(
      args,
      (completedSession) async {
        final rc = await completedSession.getReturnCode();
        if (!completer.isCompleted) completer.complete(rc);
      },
      (l) {},
      (st) {},
    );

    final returnCode = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => null,
    );

    if (returnCode == null) _cancelSession(session);
    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    }
    return null;
  }

  /// Update audio metadata including Title, Artist, Album, and Cover Art
  Future<String?> updateAudioMetadata({
    required String inputPath,
    required String outputPath,
    String? title,
    String? artist,
    String? album,
    String? imagePath,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isWindows) {
      return null;
    }

    final args = ["-y", "-i", inputPath];

    if (imagePath != null && imagePath.isNotEmpty) {
      args.addAll(["-i", imagePath]);
      args.addAll(["-map", "0:a", "-map", "1:v"]);
      args.addAll(["-c", "copy"]);
      args.addAll(["-disposition:v", "attached_pic"]); // Crucial for cover arts
    } else {
      args.addAll(["-map", "0", "-c", "copy"]);
    }

    if (title != null) args.addAll(["-metadata", "title=$title"]);
    if (artist != null) args.addAll(["-metadata", "artist=$artist"]);
    if (album != null) args.addAll(["-metadata", "album=$album"]);

    args.add(outputPath);

    if (Platform.isWindows) {
      final result = await Process.run(HarborMediaEngine.executable(), args,
          runInShell: false);
      if (result.exitCode == 0 && await File(outputPath).exists()) {
        return outputPath;
      }
      debugPrint('FFmpeg metadata update failed: ${result.stderr}');
      return null;
    }

    final completer = Completer<ReturnCode?>();

    final session = await FFmpegKit.executeWithArgumentsAsync(
      args,
      (completedSession) async {
        final rc = await completedSession.getReturnCode();
        if (!completer.isCompleted) completer.complete(rc);
      },
      (log) {
        debugPrint('FFmpeg metadata update log: ${log.getMessage()}');
      },
      (st) {},
    );

    final returnCode = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => null,
    );

    if (returnCode == null) _cancelSession(session);
    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    }
    return null;
  }
}
