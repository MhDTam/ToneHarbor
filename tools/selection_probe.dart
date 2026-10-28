// Native Windows regression probe. Uses generated silent fixtures, no user DB.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/services/audio/audio_handler.dart';
import 'package:toneharbor/features/desktop/harbor_media_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const root = String.fromEnvironment(
    'PROBE_DIR',
    defaultValue: 'output/selection-probe',
  );
  final report = <String, Object?>{};
  Future<void> save() async {
    await Directory(root).create(recursive: true);
    await File(
      '$root/results.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  }

  try {
    await Directory(root).create(recursive: true);
    final songs = <SongModel>[];
    for (var i = 0; i < 3; i++) {
      final path = '$root/track-$i.wav';
      final generated = await Process.run(HarborMediaEngine.executable(), [
        '-y',
        '-hide_banner',
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'aevalsrc=0:d=2:s=44100',
        '-c:a',
        'pcm_s16le',
        path,
      ]);
      if (generated.exitCode != 0) throw StateError('${generated.stderr}');
      songs.add(
        SongModel(
          id: i + 1,
          title: 'Track $i',
          artist: '',
          album: '',
          data: path,
          duration: 2000,
          dateAdded: i,
        ),
      );
    }
    final engine = AudioPlayer();
    final handler = ToneHarborAudioHandler(player: engine);
    await handler.setVolume(0);
    await handler.setQueueFromSongs(songs, 0);
    final selected = <int>[];
    for (final index in [1, 0, 2, 1, 2, 0, 1, 0]) {
      await handler.skipToQueueItem(index).timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (handler.currentIndex != index) {
        throw StateError('Selected $index but got ${handler.currentIndex}');
      }
      selected.add(handler.currentIndex!);
    }
    report['manualSelections'] = selected;
    await save();
    final rapid = [
      handler.skipToQueueItem(1),
      handler.skipToQueueItem(2),
      handler.skipToQueueItem(0),
    ];
    await Future.wait(rapid).timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (handler.currentIndex != 0) {
      throw StateError('Latest rapid selection lost');
    }
    report['rapidSelection'] = handler.currentIndex;
    await handler.currentIndexStream
        .firstWhere((i) => i == 1)
        .timeout(const Duration(seconds: 5));
    report['naturalCompletionAdvancedTo'] = handler.currentIndex;
    handler.setSleepBoundary(track: true);
    await handler.skipToQueueItem(0);
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (handler.playing) {
      throw StateError('Sleep boundary did not pause playback');
    }
    if (handler.currentIndex != 0) {
      throw StateError('Sleep boundary advanced the queue');
    }
    report['endOfTrackStoppedWithoutSkipping'] = true;
    await engine.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    report['engineDisposed'] = true;
    report['passed'] = true;
    await save();
    exit(0);
  } catch (e, st) {
    report['passed'] = false;
    report['error'] = '$e';
    report['stack'] = '$st';
    await save();
    exit(1);
  }
}
