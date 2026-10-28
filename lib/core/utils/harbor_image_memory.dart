import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Round up to reusable physical sizes without lowering display resolution.
/// Resizing a window must not retain a decoded cover for every single pixel.
int harborImageDecodeWidth(double logicalWidth, double pixelRatio,
    {int minimum = 64, int maximum = 1600}) {
  final physical = (logicalWidth * pixelRatio).ceil();
  final step = physical <= 128 ? 32 : 64;
  return ((physical + step - 1) ~/ step * step).clamp(minimum, maximum);
}

final _imageTokens = Expando<Object>('harbor-encoded-image-identity');

/// Flutter's MemoryImage uses itself as its cache key, keeping the original
/// encoded bytes alive for every cached cover even after our byte LRU evicts it.
/// This provider keys the image by a weakly associated token instead. The codec
/// and animation handling remain Flutter's own implementation.
class HarborMemoryImage extends ImageProvider<Object> {
  final Uint8List bytes;
  HarborMemoryImage(this.bytes);

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(_imageTokens[bytes] ??= Object());

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
          codec: _load(decode),
          scale: 1,
          debugLabel: 'ToneHarbor embedded cover');

  Future<ui.Codec> _load(ImageDecoderCallback decode) async =>
      decode(await ui.ImmutableBuffer.fromUint8List(bytes));
}
