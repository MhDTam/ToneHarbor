import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/core/utils/harbor_image_memory.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/data/repositories/playlist_repository.dart';
import 'package:toneharbor/features/desktop/harbor_media_engine.dart';

void main() {
  testWidgets('lightweight cover cache preserves animated artwork frames',
      (tester) async {
    late Uint8List bytes;
    await tester.runAsync(() async {
      final result = await Process.run(
          HarborMediaEngine.executable(),
          [
            '-hide_banner',
            '-loglevel',
            'error',
            '-f',
            'lavfi',
            '-i',
            'testsrc=size=16x16:rate=4:duration=0.5',
            '-frames:v',
            '2',
            '-f',
            'gif',
            'pipe:1',
          ],
          stdoutEncoding: null);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      bytes = Uint8List.fromList(result.stdout as List<int>);
    });
    final frames = <int>{};
    await tester.pumpWidget(MaterialApp(
        home: Image(
      image: HarborMemoryImage(bytes),
      width: 32,
      height: 32,
      frameBuilder: (_, child, frame, __) {
        if (frame != null) frames.add(frame);
        return child;
      },
    )));
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(frames, contains(0));
    expect(frames.any((frame) => frame > 0), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('cover cache keys share identity without retaining encoded image data',
      () async {
    final bytes = Uint8List(4 * 1024 * 1024);
    final previous =
        await MemoryImage(bytes).obtainKey(ImageConfiguration.empty);
    expect(identical(previous.bytes, bytes), isTrue);
    final key =
        await HarborMemoryImage(bytes).obtainKey(ImageConfiguration.empty);
    expect(key.runtimeType, Object,
        reason: 'Cache keys must not own source bytes');
    expect(await HarborMemoryImage(bytes).obtainKey(ImageConfiguration.empty),
        same(key));
    expect(
        await HarborMemoryImage(Uint8List.fromList(bytes))
            .obtainKey(ImageConfiguration.empty),
        isNot(same(key)),
        reason: 'Updated file contents must get a fresh cache entry');
  });

  test(
      'decode buckets round up at Windows display scaling and retain size caps',
      () {
    for (final dpr in [1.0, 1.25, 1.5, 2.0]) {
      for (var size = 32; size <= 500; size++) {
        final width = harborImageDecodeWidth(size.toDouble(), dpr);
        expect(width, greaterThanOrEqualTo((size * dpr).ceil()));
        expect(width - (size * dpr).ceil(), lessThanOrEqualTo(64));
      }
    }
    expect(harborImageDecodeWidth(2000, 2), 1600);
    expect(harborImageDecodeWidth(2000, 2, maximum: 1024), 1024);
  });

  test('visited playlist results are released after their last consumer closes',
      () async {
    var disposed = 0;
    final container = ProviderContainer(overrides: [
      playlistSongsProvider.overrideWith((ref, id) async {
        ref.onDispose(() => disposed++);
        return [
          SongModel(
              id: id,
              title: '$id',
              artist: '',
              album: '',
              data: '$id.mp3',
              duration: 1000,
              dateAdded: 0)
        ];
      }),
    ]);
    addTearDown(container.dispose);
    for (var id = 1; id <= 40; id++) {
      final provider = playlistSongsProvider(id);
      final listener = container.listen(provider, (_, __) {});
      expect((await container.read(provider.future)).single.id, id);
      listener.close();
      await container.pump();
    }
    expect(disposed, 40);
    expect(
        container
            .getAllProviderElements()
            .where((e) => e.provider.from == playlistSongsProvider),
        isEmpty);
  });

  testWidgets(
      'resizing cover reuses decoded images instead of retaining each pixel size',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox).first);
    final cache = PaintingBinding.instance.imageCache;
    final previousBytes = cache.maximumSizeBytes,
        previousCount = cache.maximumSize;
    addTearDown(() {
      cache.clear();
      cache.clearLiveImages();
      cache.maximumSizeBytes = previousBytes;
      cache.maximumSize = previousCount;
    });
    const asset =
        AssetImage('assets/images/harbor/themed/ocean-window-cover-v22.webp');
    Future<Map<String, int>> measure({required bool bucketed}) async {
      cache.clear();
      cache.clearLiveImages();
      cache.maximumSize = bucketed ? 192 : 256;
      cache.maximumSizeBytes = (bucketed ? 48 : 64) * 1024 * 1024;
      for (var size = 260; size <= 360; size += 2) {
        await tester.runAsync(() => precacheImage(
            ResizeImage(asset,
                width: bucketed
                    ? harborImageDecodeWidth(size.toDouble(), 1)
                    : size),
            context));
        await tester.pump();
      }
      return {
        'entries': cache.currentSize,
        'decodedBytes': cache.currentSizeBytes
      };
    }

    final before = await measure(bucketed: false);
    final after = await measure(bucketed: true);
    expect(before['entries'], 51);
    expect(after['entries'], 2);
    expect(after['decodedBytes']!, lessThan(before['decodedBytes']! ~/ 5));
    if (const bool.fromEnvironment('HARBOR_MEMORY_PROFILE')) {
      await tester.runAsync(() async {
        await Directory('output').create(recursive: true);
        await File('output/memory-v21-resize-metrics.json')
            .writeAsString(jsonEncode({
          'scenario':
              'Same plant cover at 51 widths from 260 to 360 physical pixels',
          'before': before,
          'after': after,
          'note':
              'Decoded image-cache bytes measured in Flutter tests; not total process RAM or an FPS benchmark.',
        }));
      });
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'lightweight provider decodes covers, shares cache and handles corrupt data',
      (tester) async {
    late Uint8List bytes;
    await tester.runAsync(() async {
      bytes = await File('assets/images/harbor/defaults/ocean-track.png')
          .readAsBytes();
    });
    await tester.pumpWidget(MaterialApp(
        home: Row(children: [
      Image(
          image: ResizeImage(HarborMemoryImage(bytes), width: 64),
          width: 64,
          height: 64),
      Image(
          image: ResizeImage(HarborMemoryImage(bytes), width: 64),
          width: 64,
          height: 64),
    ])));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await tester.pumpAndSettle();
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final first = images[0].image.resolve(ImageConfiguration.empty);
    final second = images[1].image.resolve(ImageConfiguration.empty);
    expect(first.completer, same(second.completer));
    expect(find.byType(RawImage), findsNWidgets(2));
    expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .every((w) => w.image != null),
        isTrue);
    await tester.pumpWidget(MaterialApp(
        home: Image(
      image: HarborMemoryImage(Uint8List.fromList([1, 2, 3])),
      errorBuilder: (_, __, ___) => const Text('Recovered cover'),
    )));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await tester.pumpAndSettle();
    expect(find.text('Recovered cover'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
