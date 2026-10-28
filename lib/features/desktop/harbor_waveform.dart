import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'harbor_media_engine.dart';

/// 16-bit PCM is reduced on a worker isolate with bounded memory. FFmpeg and
/// analysis are cancelled together when a track is skipped.
typedef WaveformSlice = ({String path, int startMs, int lengthMs});

/// Retain only a bounded number of completed pages across the whole session.
class WaveformRetention {
  final int limit;
  final _pages = <WaveformSlice, void Function()>{};
  WaveformRetention({this.limit = 32}) : assert(limit > 0);
  int get length => _pages.length;
  void add(WaveformSlice page, void Function() release) {
    _pages.remove(page)?.call();
    _pages[page] = release;
    while (_pages.length > limit) {
      _pages.remove(_pages.keys.first)!();
    }
  }

  void close() {
    final releases = _pages.values.toList();
    _pages.clear();
    for (final release in releases) {
      release();
    }
  }
}

final waveformRetentionProvider = Provider<WaveformRetention>((ref) {
  final cache = WaveformRetention();
  ref.onDispose(cache.close);
  return cache;
});

final waveformProvider = FutureProvider.autoDispose
    .family<List<double>, String>((ref, file) => ref.watch(
        waveformWindowProvider((path: file, startMs: 0, lengthMs: 0)).future));

final waveformWindowProvider = FutureProvider.autoDispose
    .family<List<double>, WaveformSlice>((ref, window) async {
  final file = window.path;
  Process? process;
  Isolate? worker;
  ReceivePort? replies;
  StreamSubscription<dynamic>? subscription;
  Completer<SendPort>? ready;
  Completer<List<double>>? result;
  Completer<void>? acknowledgement;
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    process?.kill();
    worker?.kill(priority: Isolate.immediate);
    if (ready != null && !ready.isCompleted && replies != null) {
      ready.complete(replies.sendPort);
    }
    if (acknowledgement != null && !acknowledgement.isCompleted) {
      acknowledgement.complete();
    }
    if (result != null && !result.isCompleted) result.complete([]);
    replies?.close();
  });
  try {
    if (!await File(file).exists()) return [];
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (disposed) return [];
    replies = ReceivePort();
    ready = Completer<SendPort>();
    result = Completer<List<double>>();
    subscription = replies.listen((message) {
      if (message is SendPort) {
        if (ready != null && !ready.isCompleted) ready.complete(message);
      } else if (message == 'ack') {
        if (acknowledgement != null && !acknowledgement.isCompleted) {
          acknowledgement.complete();
        }
      } else if (message is List && !result!.isCompleted) {
        result.complete(message.whereType<double>().toList());
      }
    });
    worker = await Isolate.spawn(_waveformWorker, replies.sendPort);
    final input = await ready.future;
    if (disposed) return [];
    process = await Process.start(
        HarborMediaEngine.executable(),
        [
          '-hide_banner',
          '-loglevel',
          'error',
          '-threads',
          '1',
          if (window.startMs > 0) ...['-ss', '${window.startMs / 1000}'],
          '-i',
          file,
          if (window.lengthMs > 0) ...['-t', '${window.lengthMs / 1000}'],
          '-vn',
          '-sn',
          '-dn',
          '-ac',
          '1',
          '-f',
          's16le',
          'pipe:1'
        ],
        runInShell: false);
    if (disposed) {
      process.kill();
      return [];
    }
    final errorDrain = process.stderr.drain<void>();
    await for (final chunk in process.stdout) {
      if (disposed) break;
      acknowledgement = Completer<void>();
      input.send(TransferableTypedData.fromList(
          [chunk is Uint8List ? chunk : Uint8List.fromList(chunk)]));
      // Back-pressure bounds transfer memory even on very long recordings.
      await acknowledgement.future;
    }
    final exit = await process.exitCode;
    await errorDrain;
    process = null;
    if (disposed || exit != 0) return [];
    input.send(null);
    final values = await result.future;
    if (!disposed) {
      final link = ref.keepAlive();
      ref.read(waveformRetentionProvider).add(window, link.close);
    }
    return values;
  } catch (_) {
    return [];
  } finally {
    process?.kill();
    process = null;
    worker?.kill(priority: Isolate.immediate);
    worker = null;
    await subscription?.cancel();
    replies?.close();
    replies = null;
  }
});

void _waveformWorker(SendPort replies) {
  final messages = ReceivePort();
  final accumulator = PcmWaveformAccumulator();
  replies.send(messages.sendPort);
  messages.listen((message) {
    if (message == null) {
      replies.send(accumulator.finish());
      messages.close();
    } else if (message is TransferableTypedData) {
      accumulator.add(message.materialize().asUint8List());
      replies.send('ack');
    }
  });
}

/// Adaptive equal-time bins preserve real RMS energy. Pairwise compaction
/// retains squared energy/sample counts, so duration cannot grow memory usage.
class PcmWaveformAccumulator {
  final int maxBins;
  int _binSize;
  final List<double> _energies = [];
  final List<int> _counts = [];
  double _energy = 0;
  int _count = 0;
  int? _lowByte;
  PcmWaveformAccumulator({this.maxBins = 1536, int samplesPerBin = 512})
      : assert(maxBins >= 4 && maxBins.isEven),
        assert(samplesPerBin > 0),
        _binSize = samplesPerBin;
  void add(Uint8List bytes) {
    for (final byte in bytes) {
      if (_lowByte == null) {
        _lowByte = byte;
        continue;
      }
      var sample = (byte << 8) | _lowByte!;
      _lowByte = null;
      if (sample >= 32768) sample -= 65536;
      final amplitude = sample / 32768;
      _energy += amplitude * amplitude;
      _count++;
      if (_count == _binSize) _flush();
    }
  }

  void _flush() {
    if (_count == 0) return;
    _energies.add(_energy);
    _counts.add(_count);
    _energy = 0;
    _count = 0;
    if (_energies.length >= maxBins) {
      for (var i = 0; i < _energies.length ~/ 2; i++) {
        _energies[i] = _energies[i * 2] + _energies[i * 2 + 1];
        _counts[i] = _counts[i * 2] + _counts[i * 2 + 1];
      }
      _energies.length = _energies.length ~/ 2;
      _counts.length = _counts.length ~/ 2;
      _binSize *= 2;
    }
  }

  List<double> finish() {
    _flush();
    return List.generate(_energies.length,
        (i) => math.sqrt(_energies[i] / _counts[i]).clamp(0.0, 1.0));
  }
}

/// RMS preserves loudness shape; peak maxima flatten heavily mastered audio.
List<double> waveformPeaks(Uint8List samples, {int bars = 240}) {
  if (samples.isEmpty || bars <= 0) return [];
  final count = samples.length < bars ? samples.length : bars;
  return List<double>.generate(count, (i) {
    final start = i * samples.length ~/ count;
    final end = (i + 1) * samples.length ~/ count;
    var energy = 0.0;
    for (var j = start; j < end; j++) {
      final amplitude = (samples[j] - 128) / 128;
      energy += amplitude * amplitude;
    }
    return math.sqrt(energy / math.max(1, end - start)).clamp(0.0, 1.0);
  });
}

class WaveformViewport {
  final Duration start, end;
  final double progress;
  const WaveformViewport(this.start, this.end, this.progress);
}

/// Fixed 30-second pages preserve a readable time scale and stable bar positions.
WaveformViewport waveformViewport(Duration duration, Duration position) {
  const windowMs = 30000;
  final total = duration.inMilliseconds;
  final current = math.max(
      0,
      total > 0
          ? position.inMilliseconds.clamp(0, total)
          : position.inMilliseconds);
  final pagePosition =
      total > 0 ? math.min(current, math.max(0, total - 1)) : current;
  final start = (pagePosition ~/ windowMs) * windowMs;
  final end = total > 0 ? math.min(total, start + windowMs) : start + windowMs;
  return WaveformViewport(
      Duration(milliseconds: start),
      Duration(milliseconds: end),
      ((current - start) / math.max(1, end - start)).clamp(0.0, 1.0));
}

String _waveTime(Duration time) {
  final seconds = time.inSeconds;
  final minutes = (seconds ~/ 60).remainder(60).toString().padLeft(2, '0');
  final tail = seconds.remainder(60).toString().padLeft(2, '0');
  return seconds >= 3600
      ? '${seconds ~/ 3600}:$minutes:$tail'
      : '$minutes:$tail';
}

class HarborWaveform extends ConsumerWidget {
  final String? path;
  final double progress;
  final Duration duration;
  final double height;
  final Color color;
  const HarborWaveform(
      {super.key,
      required this.path,
      required this.progress,
      this.duration = Duration.zero,
      this.height = 54,
      required this.color});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = Duration(
        milliseconds:
            (progress.clamp(0.0, 1.0) * duration.inMilliseconds).round());
    final view = waveformViewport(duration, position);
    final async = path == null || duration <= Duration.zero
        ? const AsyncData<List<double>>([])
        : ref.watch(waveformWindowProvider((
            path: path!,
            startMs: view.start.inMilliseconds,
            lengthMs: (view.end - view.start).inMilliseconds
          )));
    if (path != null &&
        duration > view.end &&
        view.end - position <= const Duration(seconds: 5)) {
      final nextEnd =
          math.min(duration.inMilliseconds, view.end.inMilliseconds + 30000);
      // Prepare the next page before the cursor reaches it, without a visual jump.
      ref.watch(waveformWindowProvider((
        path: path!,
        startMs: view.end.inMilliseconds,
        lengthMs: nextEnd - view.end.inMilliseconds
      )));
    }
    return RepaintBoundary(
        child: SizedBox(
      height: height + 18,
      width: double.infinity,
      child: Column(children: [
        SizedBox(
            height: 18,
            child: path == null || duration == Duration.zero
                ? const SizedBox.shrink()
                : Row(children: [
                    Icon(Icons.zoom_in_rounded,
                        size: 12, color: color.withAlpha(130)),
                    const SizedBox(width: 5),
                    Text('${_waveTime(view.start)} — ${_waveTime(view.end)}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF94A6AF))),
                    const Spacer(),
                    Text('${(view.end - view.start).inSeconds}s',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF70868E))),
                  ])),
        SizedBox(
            height: height,
            width: double.infinity,
            child: async.when(
              data: (values) => _WaveformPlot(
                  samples: values, progress: view.progress, color: color),
              loading: () => Center(
                  child: LinearProgressIndicator(
                      minHeight: 1,
                      color: color.withAlpha(100),
                      backgroundColor: color.withAlpha(15))),
              error: (_, __) =>
                  CustomPaint(painter: _WavePainter(const [], 0, color)),
            )),
      ]),
    ));
  }
}

/// Cache only one page's reduced bars. Cursor ticks reuse the same amplitudes;
/// a new page or width immediately rebuilds the real RMS shape.
class WaveformDisplayCache {
  List<double>? _source;
  int? _count;
  List<double> _bars = const [];
  List<double> amplitudes(List<double> samples, int count) {
    if (!identical(_source, samples) || _count != count) {
      _source = samples;
      _count = count;
      _bars = waveformDisplayAmplitudes(samples, count);
    }
    return _bars;
  }
}

class _WaveformPlot extends StatefulWidget {
  final List<double> samples;
  final double progress;
  final Color color;
  const _WaveformPlot(
      {required this.samples, required this.progress, required this.color});
  @override
  State<_WaveformPlot> createState() => _WaveformPlotState();
}

class _WaveformPlotState extends State<_WaveformPlot> {
  final _cache = WaveformDisplayCache();
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, bounds) {
        final count = (bounds.maxWidth / 7).floor().clamp(12, 64);
        return CustomPaint(
            painter: _WavePainter(_cache.amplitudes(widget.samples, count),
                widget.progress, widget.color));
      });
}

/// Aggregate only real squared amplitudes, with no positional taper or invented
/// oscillation. Silence remains exactly zero at every zoom level.
List<double> waveformDisplayAmplitudes(List<double> samples, int count) {
  if (samples.isEmpty || count <= 0) return [];
  count = math.min(count, samples.length);
  return List.generate(count, (i) {
    final start = i * samples.length ~/ count;
    final end = (i + 1) * samples.length ~/ count;
    var energy = 0.0;
    for (var j = start; j < end; j++) {
      final value = samples[j].isFinite ? samples[j].clamp(0.0, 1.0) : 0.0;
      energy += value * value;
    }
    return math.sqrt(energy / (end - start));
  });
}

class _WavePainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color color;
  _WavePainter(this.samples, this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = size.height / 2;
    final done = progress.clamp(0.0, 1.0);
    final split = size.width * done;
    final idle = Color.lerp(color, const Color(0xFF8097A3), .68)!;
    canvas.drawLine(
        Offset(0, center),
        Offset(size.width, center),
        Paint()
          ..color = idle.withAlpha(40)
          ..strokeWidth = .8);
    final bars = samples;
    if (bars.isNotEmpty) {
      final peak = bars.fold<double>(0, math.max);
      // A single global display gain preserves every relative amplitude.
      final gain = peak > 0 ? math.min(4.0, .90 / peak) : 1.0;
      final step = size.width / bars.length;
      final paint = Paint()
        ..strokeWidth = (step * .46).clamp(2.0, 4.0)
        ..strokeCap = StrokeCap.round;
      final played = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withAlpha(175),
          Color.lerp(color, Colors.white, .12)!,
          color.withAlpha(175)
        ],
        stops: const [0, .5, 1],
      ).createShader(Offset.zero & size);
      for (var i = 0; i < bars.length; i++) {
        if (bars[i] <= 0) continue;
        final x = (i + .5) * step;
        final height =
            (bars[i] * gain * (size.height - 8)).clamp(.5, size.height - 4);
        paint.shader = x <= split ? played : null;
        paint.color = x <= split ? color : idle.withAlpha(115);
        canvas.drawLine(Offset(x, center - height / 2),
            Offset(x, center + height / 2), paint);
      }
    }
    if (done > 0 && done < 1) {
      canvas.drawLine(
          Offset(split, 4),
          Offset(split, size.height - 4),
          Paint()
            ..color = color.withAlpha(185)
            ..strokeWidth = 1);
      canvas.drawCircle(
          Offset(split, size.height - 3), 1.7, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.samples != samples || old.progress != progress || old.color != color;
}
