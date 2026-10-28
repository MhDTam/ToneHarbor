import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/services/audio/artwork_loader.dart';
import 'package:toneharbor/features/desktop/harbor_waveform.dart';

void main() {
  test('waveform cursor reuses RMS bars and refreshes on page or width change',
      () {
    final cache = WaveformDisplayCache();
    final source = List<double>.generate(1536, (i) => i.isEven ? .2 : .8);
    final bars = cache.amplitudes(source, 40);
    for (var i = 0; i < 60; i++) {
      expect(identical(cache.amplitudes(source, 40), bars), isTrue);
    }
    final resized = cache.amplitudes(source, 64);
    expect(resized, hasLength(64));
    expect(identical(resized, bars), isFalse);
    final silence = cache.amplitudes(List.filled(1536, 0.0), 64);
    expect(silence, everyElement(0.0));
  });
  test('artwork requests deduplicate and never exceed two disk readers',
      () async {
    var active = 0, peak = 0, reads = 0;
    final loader = ArtworkLoader(
        version: (_) async => 1,
        read: (_) async {
          reads++;
          active++;
          if (active > peak) peak = active;
          await Future<void>.delayed(const Duration(milliseconds: 1));
          active--;
          return Uint8List(4);
        });
    addTearDown(loader.close);
    final first = loader.load('same');
    expect(identical(first, loader.load('same')), isTrue);
    await Future.wait(
        [first, for (var i = 0; i < 40; i++) loader.load('track-$i')]);
    expect(peak, 2);
    expect(reads, 41);
    expect(loader.cachedBytes, 164);
  });

  test('LRU storage bounds bytes and entries and refreshes changed files',
      () async {
    var reads = 0, stamp = 1;
    final loader = ArtworkLoader(
        maxEntries: 3,
        maxBytes: 8,
        version: (_) async => stamp,
        read: (_) async {
          reads++;
          return Uint8List.fromList([stamp, 0, 0, 0]);
        });
    addTearDown(loader.close);
    for (final path in ['a', 'b', 'c']) {
      await loader.load(path);
    }
    expect(loader.cachedBytes, 8);
    expect(loader.cachedEntries, 2);
    await loader.load('c');
    expect(reads, 3);
    await loader.load('a');
    expect(reads, 4);
    stamp = 2;
    expect((await loader.load('a'))!.first, 2);
    expect(reads, 5);
    expect(loader.cachedBytes, lessThanOrEqualTo(8));
  });

  test('missing covers are cached and cancelled queued reads never start',
      () async {
    final gate = Completer<void>();
    final started = <String>[];
    final loader = ArtworkLoader(
        concurrency: 1,
        version: (_) async => 1,
        read: (path) async {
          started.add(path);
          if (path == 'first') await gate.future;
          return null;
        });
    addTearDown(loader.close);
    final first = loader.load('first');
    final cancelled = loader.load('cancelled');
    loader.cancel('cancelled', cancelled);
    final last = loader.load('last');
    expect(await cancelled, isNull);
    gate.complete();
    await Future.wait([first, last]);
    await loader.load('last');
    expect(started, ['first', 'last']);
  });

  test('closing the loader resolves pending reads and releases its cache',
      () async {
    final gate = Completer<void>();
    final loader = ArtworkLoader(
        version: (_) async => 1,
        read: (_) async {
          await gate.future;
          return Uint8List(8);
        });
    final requests = [for (var i = 0; i < 8; i++) loader.load('$i')];
    await Future<void>.delayed(Duration.zero);
    loader.close();
    expect(await Future.wait(requests), everyElement(isNull));
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(loader.cachedBytes, 0);
    expect(loader.cachedEntries, 0);
  });

  test('completed waveform retention never exceeds its page budget', () {
    final cache = WaveformRetention(limit: 3);
    final released = <int>[];
    for (var i = 0; i < 100; i++) {
      cache.add((path: 'audio', startMs: i * 30000, lengthMs: 30000),
          () => released.add(i));
      expect(cache.length, lessThanOrEqualTo(3));
    }
    expect(released.length, 97);
    cache.close();
    expect(released.length, 100);
    expect(cache.length, 0);
  });
}
