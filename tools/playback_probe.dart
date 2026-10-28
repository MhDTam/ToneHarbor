// Windows codec/decoder probe. Does not open the app, preferences or database.
// flutter build windows --release --target tools/playback_probe.dart --no-pub
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:toneharbor/features/desktop/harbor_media_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const directory = String.fromEnvironment(
    'PROBE_DIR',
    defaultValue: 'output/playback-probe',
  );
  final result = <String, Object?>{};
  Future<void> save() => File(
    '$directory/results.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(result));
  try {
    await Directory(directory).create(recursive: true);
    final ffmpeg = HarborMediaEngine.executable();
    const encoders = {
      'wav': 'pcm_s16le',
      'mp3': 'libmp3lame',
      'm4a': 'aac',
      'aac': 'aac',
      'flac': 'flac',
      'wma': 'wmav2',
      'ogg': 'libvorbis',
      'opus': 'libopus',
    };
    final player = AudioPlayer();
    final errors = <String>[];
    final subscription = player.playbackEventStream.listen(
      (_) {},
      onError: (Object e) {
        errors.add('$e');
      },
    );
    final formats = <String, Object?>{};
    result['formats'] = formats;
    for (final entry in encoders.entries) {
      final file = '$directory/tone.${entry.key}';
      final generated = await Process.run(ffmpeg, [
        '-y',
        '-hide_banner',
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'aevalsrc=0:d=5:s=44100',
        '-ac',
        '2',
        '-c:a',
        entry.value,
        file,
      ]);
      if (generated.exitCode != 0) {
        formats[entry.key] = {'generationError': '${generated.stderr}'};
        continue;
      }
      try {
        final timer = Stopwatch()..start();
        final duration = await player
            .setFilePath(file)
            .timeout(const Duration(seconds: 5));
        await player.processingStateStream
            .firstWhere((s) => s == ProcessingState.ready)
            .timeout(const Duration(seconds: 5));
        await player.setVolume(0);
        unawaited(player.play().catchError((Object e) {}));
        await player.positionStream
            .firstWhere((p) => p.inMilliseconds >= 100)
            .timeout(const Duration(seconds: 3));
        formats[entry.key] = {
          'decoded': true,
          'durationMs': (player.duration ?? duration)?.inMilliseconds,
          'loadAndAdvanceMs': timer.elapsedMilliseconds,
        };
        await player.pause();
      } catch (e) {
        formats[entry.key] = {'decoded': false, 'error': '$e'};
        await player.stop();
      }
      await save();
    }
    result['formats'] = formats;
    final samples = <String, List<int>>{};
    for (final stopFirst in [false]) {
      final times = <int>[];
      for (var i = 0; i < 24; i++) {
        final file = '$directory/tone.${i.isEven ? 'mp3' : 'wav'}';
        final timer = Stopwatch()..start();
        if (stopFirst) await player.stop();
        await player.setFilePath(file).timeout(const Duration(seconds: 5));
        await player.processingStateStream
            .firstWhere((s) => s == ProcessingState.ready)
            .timeout(const Duration(seconds: 5));
        times.add(timer.elapsedMicroseconds);
      }
      samples[stopFirst ? 'stopThenLoadUs' : 'replaceSourceUs'] = times;
    }
    result['switchTiming'] = samples;
    result['platformErrors'] = errors;
    await save();
    await subscription.cancel();
    await player.dispose();
  } catch (e, st) {
    result['fatal'] = '$e\n$st';
  }
  await File(
    '$directory/results.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(result));
  exit(result.containsKey('fatal') ? 1 : 0);
}
