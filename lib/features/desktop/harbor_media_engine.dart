import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'harbor_audio_effects.dart';

/// FFmpeg command-line integration for Windows. Each job writes to its own
/// temporary directory beside the destination, then moves the result into place.
class HarborMediaEngine {
  Process? _running;
  bool _cancelled = false;
  bool _exporting = false;
  bool get running => _exporting;

  static String executable() {
    final bundled = path.join(
        path.dirname(Platform.resolvedExecutable), 'tools', 'ffmpeg.exe');
    if (File(bundled).existsSync()) return bundled;
    final workspace = path.join(Directory.current.path, 'tools', 'ffmpeg.exe');
    return File(workspace).existsSync() ? workspace : 'ffmpeg';
  }

  Future<double?> duration(String input) async {
    final result = await Process.run(
        executable(), ['-hide_banner', '-i', input],
        runInShell: false);
    final match = RegExp(r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)')
        .firstMatch('${result.stderr}');
    if (match == null) return null;
    return int.parse(match[1]!) * 3600 +
        int.parse(match[2]!) * 60 +
        double.parse(match[3]!);
  }

  void cancel() {
    _cancelled = true;
    _running?.kill();
  }

  Future<void> export(
      {required String input,
      required String output,
      double start = 0,
      double? end,
      double volume = 1,
      double fadeIn = 0,
      double fadeOut = 0,
      bool spatial = false,
      double rotation = 0.125,
      double depth = 1,
      double reverb = .3,
      AudioEditEffects effects = const AudioEditEffects(),
      void Function(double seconds)? onProgress}) async {
    if (running) throw StateError('A job is already running');
    _exporting = true;
    _cancelled = false;
    try {
      await _export(
          input: input,
          output: output,
          start: start,
          end: end,
          volume: volume,
          fadeIn: fadeIn,
          fadeOut: fadeOut,
          spatial: spatial,
          rotation: rotation,
          depth: depth,
          reverb: reverb,
          effects: effects,
          onProgress: onProgress);
    } finally {
      _exporting = false;
    }
  }

  Future<void> _export(
      {required String input,
      required String output,
      required double start,
      required double? end,
      required double volume,
      required double fadeIn,
      required double fadeOut,
      required bool spatial,
      required double rotation,
      required double depth,
      required double reverb,
      required AudioEditEffects effects,
      required void Function(double seconds)? onProgress}) async {
    if (!await File(input).exists()) {
      throw const FileSystemException('Input file does not exist');
    }
    if (path.equals(path.normalize(input), path.normalize(output))) {
      throw ArgumentError('Input and output must be different');
    }
    if (await File(output).exists()) {
      throw const FileSystemException(
          'Output file already exists; choose another name');
    }
    effects.validate();
    if (!start.isFinite ||
        start < 0 ||
        (end != null && (!end.isFinite || end <= start)) ||
        !volume.isFinite ||
        volume < 0 ||
        !fadeIn.isFinite ||
        fadeIn < 0 ||
        !fadeOut.isFinite ||
        fadeOut < 0) {
      throw ArgumentError('End time must be after the start time');
    }
    final extension = path.extension(output).toLowerCase();
    if (effects.sampleRate != null &&
        !audioEditSampleRates(extension.substring(1))
            .contains(effects.sampleRate)) {
      throw ArgumentError('Unsupported sample rate for $extension');
    }
    final codec = switch (extension) {
      '.mp3' => [
          '-c:a',
          'libmp3lame',
          if (effects.bitrateKbps == null) ...[
            '-q:a',
            '2'
          ] else ...[
            '-b:a',
            '${effects.bitrateKbps}k'
          ]
        ],
      '.m4a' => ['-c:a', 'aac', '-b:a', '${effects.bitrateKbps ?? 192}k'],
      '.wav' => ['-c:a', 'pcm_s16le'],
      '.flac' => ['-c:a', 'flac'],
      '.ogg' => ['-c:a', 'libvorbis', '-q:a', '5'],
      '.opus' => ['-c:a', 'libopus', '-b:a', '${effects.bitrateKbps ?? 160}k'],
      _ => throw ArgumentError('Unsupported output format: $extension'),
    };
    final outputDir = Directory(path.dirname(output));
    if (!await outputDir.exists()) {
      throw const FileSystemException('Output folder does not exist');
    }
    final tempDir = await outputDir.createTemp('.toneharbor-');
    final temporary = path.join(tempDir.path, 'output$extension');
    final outputDuration = end == null ? null : (end - start) / effects.speed;
    final filters = <String>[
      if (end != null) 'atrim=duration=${end - start}',
      'asetpts=PTS-STARTPTS',
      ...effects.filters,
      'volume=$volume'
    ];
    if (spatial) {
      final delay = (50 + reverb.clamp(0, 1) * 1950).round();
      final decay = (0.1 + reverb.clamp(0, 1) * 0.7).toStringAsFixed(2);
      filters.add('aformat=channel_layouts=stereo');
      filters.add('aecho=0.8:0.9:$delay:$decay');
      filters.add(
          'apulsator=hz=${rotation.clamp(.01, 1.0)}:amount=${depth.clamp(0.0, 1.0)}');
    }
    if (outputDuration != null) filters.add('atrim=duration=$outputDuration');
    if (fadeIn > 0) {
      filters.add(
          'afade=t=in:st=0:d=${outputDuration == null ? fadeIn : fadeIn.clamp(0, outputDuration)}');
    }
    if (fadeOut > 0 && outputDuration != null) {
      final length = fadeOut.clamp(0.0, outputDuration);
      filters.add('afade=t=out:st=${outputDuration - length}:d=$length');
    }
    if (volume > 1 ||
        effects.bass > 0 ||
        effects.mid > 0 ||
        effects.treble > 0) {
      filters.add('alimiter=limit=0.98:level=false');
    }
    final args = <String>[
      '-hide_banner',
      '-loglevel',
      'error',
      '-nostats',
      '-progress',
      'pipe:1',
      '-n',
      '-filter_threads',
      '1',
      if (start > 0) ...['-ss', '$start'],
      '-i',
      input,
      '-vn',
      '-map',
      '0:a:0',
      '-af',
      filters.join(','),
      if (effects.channels != null) ...['-ac', '${effects.channels}'],
      if (effects.sampleRate != null || effects.normalize) ...[
        '-ar',
        '${effects.sampleRate ?? 48000}'
      ],
      ...codec,
      temporary
    ];
    try {
      if (_cancelled) throw const MediaExportCancelled();
      final process =
          await Process.start(executable(), args, runInShell: false);
      _running = process;
      if (_cancelled) process.kill();
      final errors = StringBuffer();
      final stdoutDone = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('out_time_us=')) {
          final micros = int.tryParse(line.substring('out_time_us='.length));
          if (micros != null) onProgress?.call(micros / 1000000);
        }
      }).asFuture<void>();
      final stderrDone = process.stderr.transform(utf8.decoder).listen((text) {
        if (errors.length < 8000) errors.write(text);
      }).asFuture<void>();
      final code = await process.exitCode.timeout(const Duration(hours: 2),
          onTimeout: () {
        process.kill();
        throw TimeoutException('Export timed out');
      });
      await Future.wait([stdoutDone, stderrDone]);
      if (_cancelled) throw const MediaExportCancelled();
      if (code != 0) {
        throw ProcessException(
            executable(), args, errors.toString().trim(), code);
      }
      if (!await File(temporary).exists()) {
        throw const FileSystemException('Encoder produced no output');
      }
      // Windows rename does not replace an existing destination. Check again
      // after encoding so an existing file is never deliberately overwritten.
      if (await File(output).exists()) {
        throw const FileSystemException(
            'Output file already exists; choose another name');
      }
      await File(temporary).rename(output);
    } finally {
      _running = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    }
  }
}

class MediaExportCancelled implements Exception {
  const MediaExportCancelled();
  @override
  String toString() => 'Cancelled';
}
