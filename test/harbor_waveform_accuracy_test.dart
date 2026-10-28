import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/features/desktop/harbor_waveform.dart';

Uint8List pcm(List<int> values) {
  final bytes = ByteData(values.length * 2);
  for (var i = 0; i < values.length; i++) {
    bytes.setInt16(i * 2, values[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void main() {
  test(
      '30-second pages map playback, page changes and final duration correctly',
      () {
    const length = Duration(seconds: 120);
    final middle = waveformViewport(length, const Duration(seconds: 48));
    expect(middle.start, const Duration(seconds: 30));
    expect(middle.end, const Duration(seconds: 60));
    expect(middle.progress, closeTo(.6, .00001));
    final next = waveformViewport(length, const Duration(seconds: 60));
    expect(next.start, const Duration(seconds: 60));
    expect(next.progress, 0);
    final last = waveformViewport(length, length);
    expect(last.start, const Duration(seconds: 90));
    expect(last.end, length);
    expect(last.progress, 1);
    final short = waveformViewport(
        const Duration(seconds: 18), const Duration(seconds: 9));
    expect(short.start, Duration.zero);
    expect(short.end, const Duration(seconds: 18));
    expect(short.progress, .5);
  });
  test('PCM analysis preserves silence, amplitude ratios and both endpoints',
      () {
    final accumulator = PcmWaveformAccumulator(samplesPerBin: 8);
    accumulator.add(pcm([
      ...List.filled(8, 8192),
      ...List.filled(8, 0),
      ...List.filled(8, 16384),
      ...List.filled(8, 8192),
    ]));
    final values = accumulator.finish();
    expect(values, [.25, 0, .5, .25]);
    expect(waveformDisplayAmplitudes(values, 4), [.25, 0, .5, .25]);
    final constant = waveformDisplayAmplitudes(List.filled(240, .5), 80);
    expect(constant.every((value) => value == .5), isTrue);
  });
  test('odd PCM chunk boundaries and long-file compaction retain real energy',
      () {
    final bytes = pcm(List.generate(32768, (i) => i.isEven ? 8192 : -8192));
    final accumulator = PcmWaveformAccumulator(samplesPerBin: 8, maxBins: 16);
    for (var i = 0; i < bytes.length; i += 13) {
      accumulator.add(Uint8List.sublistView(
          bytes, i, i + 13 > bytes.length ? bytes.length : i + 13));
    }
    final values = accumulator.finish();
    expect(values.length, lessThanOrEqualTo(16));
    expect(values.every((value) => (value - .25).abs() < .000001), isTrue);
  });
  test(
      'the high-resolution glossy logo source is preserved with its alpha channel',
      () async {
    final file = File('assets/images/harbor/brand-glossy-v9.png');
    expect(await file.exists(), isTrue);
    // PNG IHDR colour type 6 carries RGBA; the UI adds no rectangular frame.
    final bytes = await file.readAsBytes();
    // Verify the approved source without depending on a private design folder.
    expect(sha256.convert(bytes).toString(),
        '874c677c75c741871cd4ad83bd2c589154039612067472375e90d76d5deb6b4e');
    final header = ByteData.sublistView(bytes);
    expect(header.getUint32(16, Endian.big), 1254);
    expect(header.getUint32(20, Endian.big), 1254);
    expect(bytes[25], 6);
  });
}
