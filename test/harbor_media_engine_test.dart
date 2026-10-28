import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:toneharbor/features/desktop/harbor_media_engine.dart';
import 'package:toneharbor/features/desktop/harbor_batch_converter.dart';
import 'package:toneharbor/core/utils/audio_formats.dart';
import 'package:toneharbor/data/repositories/song_repository.dart';
import 'package:toneharbor/services/audio/artwork_provider.dart';
import 'package:toneharbor/services/audio/metadata_scan.dart';
import 'package:toneharbor/features/desktop/harbor_audio_effects.dart';
import 'package:toneharbor/services/audio/safe_metadata_reader.dart';
import 'package:toneharbor/services/ffmpeg_service.dart';
import 'package:toneharbor/features/desktop/harbor_waveform.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late Directory dir;
  late String source;
  final executable = HarborMediaEngine.executable();
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('toneharbor-test-');
    source = p.join(dir.path, 'input.wav');
    final result = await Process.run(executable, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=440:duration=3',
      '-c:a',
      'pcm_s16le',
      source,
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  });
  tearDownAll(() async {
    await dir.delete(recursive: true);
  });

  test(
    'metadata failure and cancellation release file handles before returning',
    () async {
      final corrupt = File(p.join(dir.path, 'corrupt-metadata.mp3'));
      await corrupt.writeAsString('unsupported metadata');
      expect(() => readAudioTags(corrupt.path), throwsA(anything));
      await corrupt.rename(p.join(dir.path, 'corrupt-renamed.mp3'));
      final cancelled = await File(
        source,
      ).copy(p.join(dir.path, 'cancel-metadata.wav'));
      final scan = MetadataScan();
      final reading = scan.read(List.filled(10000, cancelled.path));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      scan.cancel();
      await reading;
      final moved = await cancelled.rename(
        p.join(dir.path, 'cancel-renamed.wav'),
      );
      expect(await moved.exists(), isTrue);
    },
  );

  test(
    'editor speed, sample rate, channels and fades affect the real output',
    () async {
      final engine = HarborMediaEngine();
      final output = p.join(dir.path, 'edited-speed.wav');
      await engine.export(
        input: source,
        output: output,
        start: .5,
        end: 2.5,
        fadeIn: .1,
        fadeOut: .2,
        effects: const AudioEditEffects(
          speed: 2,
          sampleRate: 22050,
          channels: 2,
        ),
      );
      expect(await engine.duration(output), closeTo(1, .06));
      final details = await Process.run(executable, [
        '-hide_banner',
        '-i',
        output,
      ]);
      expect('${details.stderr}', contains('22050 Hz'));
      expect('${details.stderr}', contains('stereo'));
      final decoded = await Process.run(executable, [
        '-hide_banner',
        '-loglevel',
        'error',
        '-i',
        output,
        '-ac',
        '1',
        '-f',
        's16le',
        'pipe:1',
      ], stdoutEncoding: null);
      expect(decoded.exitCode, 0);
      final samples = ByteData.sublistView(
        Uint8List.fromList(decoded.stdout as List<int>),
      );
      double energy(int start, int count) {
        var total = 0.0;
        for (var i = start; i < start + count; i++) {
          final value = samples.getInt16(i * 2, Endian.little) / 32768;
          total += value * value;
        }
        return total / count;
      }

      final count = samples.lengthInBytes ~/ 2;
      final middle = energy(9000, 500);
      expect(energy(0, 200), lessThan(middle * .1));
      expect(energy(count - 200, 200), lessThan(middle * .1));
      expect(middle, greaterThan(.0001));
    },
  );

  test(
    'editor equalizer, normalization, denoise and spatial filters export together',
    () async {
      final engine = HarborMediaEngine();
      final output = p.join(dir.path, 'editor-effects.flac');
      await engine.export(
        input: source,
        output: output,
        start: .25,
        end: 2.25,
        volume: 1.2,
        spatial: true,
        fadeOut: .2,
        effects: const AudioEditEffects(
          bass: 3,
          mid: 2,
          treble: -1,
          normalize: true,
          denoise: true,
          sampleRate: 48000,
          channels: 2,
        ),
      );
      expect(await engine.duration(output), closeTo(2, .08));
      expect(await File(output).length(), greaterThan(1000));
      final details = await Process.run(executable, [
        '-hide_banner',
        '-i',
        output,
      ]);
      expect('${details.stderr}', contains('48000 Hz'));
      expect('${details.stderr}', contains('stereo'));
      final flac = await File(output).readAsBytes();
      expect(String.fromCharCodes(flac.take(4)), 'fLaC');
      final streamInfo = ByteData.sublistView(flac);
      expect(
        streamInfo.getUint16(10, Endian.big),
        4096,
        reason: 'Filtered output must not infer an oversized FLAC block',
      );
      final decoded = await Process.run(executable, [
        '-hide_banner',
        '-loglevel',
        'error',
        '-i',
        output,
        '-f',
        'null',
        '-',
      ]);
      expect(decoded.exitCode, 0, reason: '${decoded.stderr}');
      expect(await File(source).exists(), isTrue);
    },
  );

  test(
    'editor exports every offered format with compatible settings',
    () async {
      for (final format in ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'opus']) {
        final output = p.join(dir.path, 'editor-format.$format');
        await HarborMediaEngine().export(
          input: source,
          output: output,
          start: .2,
          end: 1.2,
          effects: const AudioEditEffects(
            sampleRate: 48000,
            channels: 1,
            bitrateKbps: 192,
          ),
        );
        expect(await File(output).length(), greaterThan(500), reason: format);
        final decoded = await Process.run(executable, [
          '-hide_banner',
          '-loglevel',
          'error',
          '-i',
          output,
          '-f',
          'null',
          '-',
        ]);
        expect(decoded.exitCode, 0, reason: '$format: ${decoded.stderr}');
      }
    },
  );

  test('library accepts audio files and excludes video containers', () async {
    for (final extension in libraryAudioExtensions) {
      expect(
        isLibraryAudioFile('C:/Music/track.${extension.toUpperCase()}'),
        isTrue,
      );
    }
    for (final extension in [
      'mp4',
      'mkv',
      'webm',
      'avi',
      'wmv',
      'mov',
      '3gp',
      'm4v',
    ]) {
      expect(isLibraryAudioFile('C:/Music/video.$extension'), isFalse);
    }
    expect(isLibraryAudioFile('C:/folder.mp3/noextension'), isFalse);
    final video = File(p.join(dir.path, 'excluded-video.mp4'));
    await video.writeAsString('original');
    expect(await getExcludedSongsOnDevice([video.path]), isEmpty);
    expect(await video.readAsString(), 'original');
  });

  test(
    'metadata worker returns native tags and recovers unreadable files',
    () async {
      final scan = MetadataScan();
      addTearDown(scan.cancel);
      final rows = await scan.read([source, p.join(dir.path, 'missing.wav')]);
      expect(rows, hasLength(2));
      expect(rows.first[0], source);
      expect(rows.first[3], inInclusiveRange(2900, 3100));
      expect(rows.first[4], isTrue);
      expect(rows.last[4], isFalse);
    },
  );

  test(
    'cancelling a metadata scan completes startup and running work safely',
    () async {
      for (final duringStartup in [true, false]) {
        final scan = MetadataScan();
        final reading = scan.read(List.filled(10000, source));
        if (!duringStartup) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        scan.cancel();
        scan.cancel();
        expect(await reading.timeout(const Duration(seconds: 3)), isEmpty);
        expect(scan.cancelled, isTrue);
        expect(await scan.read([source]), isEmpty);
      }
    },
  );

  test(
    'batch converts multiple inputs, preserves names and continues after errors',
    () async {
      final output = await Directory(p.join(dir.path, 'batch-output')).create();
      final existing = File(p.join(output.path, 'input_toneharbor.mp3'));
      await existing.writeAsString('keep this file');
      final jobs = await HarborBatchConverter().convert(
        inputs: [source, p.join(dir.path, 'missing.mp4'), source],
        outputDirectory: output.path,
        format: 'mp3',
        onUpdate: (_) {},
      );
      expect(jobs.map((job) => job.status), [
        BatchJobStatus.completed,
        BatchJobStatus.failed,
        BatchJobStatus.completed,
      ]);
      expect(jobs.first.output, endsWith('input_toneharbor (2).mp3'));
      expect(jobs.last.output, endsWith('input_toneharbor (3).mp3'));
      expect(await existing.readAsString(), 'keep this file');
      expect(await File(jobs.first.output!).length(), greaterThan(100));
      expect(await File(jobs.last.output!).length(), greaterThan(100));
      expect(
        await HarborMediaEngine().duration(jobs.last.output!),
        inInclusiveRange(2.9, 3.2),
      );
      expect(await File(source).exists(), isTrue);
    },
  );

  test('cancelling a batch stops scheduling the remaining files', () async {
    final output = await Directory(p.join(dir.path, 'cancel-batch')).create();
    final converter = HarborBatchConverter();
    final jobs = await converter.convert(
      inputs: [source, source],
      outputDirectory: output.path,
      format: 'wav',
      onUpdate: (jobs) {
        if (jobs.any((job) => job.status == BatchJobStatus.converting)) {
          converter.cancel();
        }
      },
    );
    expect(jobs.every((job) => job.status == BatchJobStatus.cancelled), isTrue);
    expect(await output.list().toList(), isEmpty);
  });

  test('encodes audio and applies trim and volume', () async {
    final engine = HarborMediaEngine();
    final output = p.join(dir.path, 'edited.mp3');
    final progress = <double>[];
    await engine.export(
      input: source,
      output: output,
      start: .5,
      end: 1.5,
      volume: .5,
      onProgress: progress.add,
    );
    expect(await File(output).length(), greaterThan(100));
    final duration = await engine.duration(output);
    expect(duration, isNotNull);
    expect(duration!, inInclusiveRange(.9, 1.2));
    expect(progress, isNotEmpty);
  });
  test('waveform is derived from actual PCM and decoded audio', () async {
    expect(
      waveformPeaks(
        Uint8List.fromList(List.filled(500, 128)),
      ).every((v) => v == 0),
      isTrue,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(waveformProvider(source), (_, __) {});
    addTearDown(subscription.close);
    final peaks = await container.read(waveformProvider(source).future);
    expect(peaks, isNotEmpty);
    expect(peaks.any((v) => v > .02), isTrue);
  });

  test(
    'waveform windows decode only the requested real audio interval',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final request = (path: source, startMs: 1000, lengthMs: 500);
      final subscription = container.listen(
        waveformWindowProvider(request),
        (_, __) {},
      );
      addTearDown(subscription.close);
      final values = await container.read(
        waveformWindowProvider(request).future,
      );
      expect(values, isNotEmpty);
      expect(values.length, lessThan(100));
      expect(values.any((value) => value > .02), isTrue);
      final outside = (path: source, startMs: 5000, lengthMs: 1000);
      final emptySubscription = container.listen(
        waveformWindowProvider(outside),
        (_, __) {},
      );
      addTearDown(emptySubscription.close);
      expect(
        await container.read(waveformWindowProvider(outside).future),
        isEmpty,
      );
    },
  );

  test('extracts audio from a video', () async {
    final video = p.join(dir.path, 'video.mp4');
    final result = await Process.run(executable, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      'color=c=black:s=64x64:r=5:d=1',
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=440:duration=1',
      '-c:v',
      'libx264',
      '-c:a',
      'aac',
      '-shortest',
      video,
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final output = p.join(dir.path, 'converted.m4a');
    await HarborMediaEngine().export(input: video, output: output);
    expect(await File(output).length(), greaterThan(100));
    expect((await HarborMediaEngine().duration(output))!, greaterThan(.8));
  });

  test('exports stereo spatial audio', () async {
    final output = p.join(dir.path, 'spatial.mp3');
    await HarborMediaEngine().export(
      input: source,
      output: output,
      spatial: true,
      rotation: .15,
      depth: .8,
      reverb: .2,
    );
    expect(await File(output).length(), greaterThan(100));
    final result = await Process.run(executable, [
      '-hide_banner',
      '-i',
      output,
    ]);
    expect('${result.stderr}', contains('stereo'));
  });

  test('updates metadata and artwork on Windows', () async {
    final original = p.join(dir.path, 'metadata-original.mp3');
    final tagged = p.join(dir.path, 'metadata-edited.mp3');
    await HarborMediaEngine().export(input: source, output: original);
    final result = await FFmpegService().updateAudioMetadata(
      inputPath: original,
      outputPath: tagged,
      title: 'ToneHarbor test',
      artist: 'Example artist',
      imagePath: p.absolute('assets/images/harbor/listening-room.png'),
    );
    expect(result, tagged);
    final info = await Process.run(executable, ['-hide_banner', '-i', tagged]);
    expect('${info.stderr}', contains('ToneHarbor test'));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      (await container.read(artworkBytesProvider(tagged).future))?.length,
      greaterThan(100),
    );
    expect(await File(original).exists(), isTrue);
  });

  test('refuses to overwrite an existing output', () async {
    final output = p.join(dir.path, 'existing.mp3');
    await File(output).writeAsString('original');
    await expectLater(
      HarborMediaEngine().export(input: source, output: output),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File(output).readAsString(), 'original');
  });

  test('rejects invalid trim before creating a file', () async {
    final output = p.join(dir.path, 'invalid.mp3');
    await expectLater(
      HarborMediaEngine().export(
        input: source,
        output: output,
        start: 2,
        end: 1,
      ),
      throwsArgumentError,
    );
    expect(await File(output).exists(), isFalse);
  });

  test('immediate cancellation stops the job and leaves no output', () async {
    final output = p.join(dir.path, 'cancelled.mp3');
    final engine = HarborMediaEngine();
    final job = engine.export(input: source, output: output);
    engine.cancel();
    await expectLater(job, throwsA(isA<MediaExportCancelled>()));
    expect(await File(output).exists(), isFalse);
    expect(engine.running, isFalse);
  });

  test('loads embedded cover artwork from a real audio file', () async {
    final cover = p.absolute('assets/images/harbor/listening-room.png');
    final track = p.join(dir.path, 'cover.mp3');
    final result = await Process.run(executable, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-i',
      source,
      '-i',
      cover,
      '-map',
      '0:a',
      '-map',
      '1:v',
      '-c:a',
      'libmp3lame',
      '-c:v',
      'mjpeg',
      '-disposition:v',
      'attached_pic',
      track,
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final bytes = await container.read(artworkBytesProvider(track).future);
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(100));
  });
}
