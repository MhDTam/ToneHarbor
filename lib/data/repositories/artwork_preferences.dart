import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String trackPictureKey(String path) =>
    'track:${Platform.isWindows ? path.replaceAll('\\', '/').toLowerCase() : path}';

enum PlaybackCover {
  waveform('Theme waveform'),
  plant('Sunlit plant');

  final String label;
  const PlaybackCover(this.label);

  static PlaybackCover fromPreferences(Map<String, String> images) =>
      PlaybackCover.values.firstWhere(
          (cover) => cover.name == images['preset:player'],
          orElse: () => PlaybackCover.plant);
}

final artworkPreferencesProvider =
    StateNotifierProvider<ArtworkPreferences, Map<String, String>>(
        (_) => ArtworkPreferences());

final artworkPreferencesReadyProvider = FutureProvider<void>(
    (ref) => ref.watch(artworkPreferencesProvider.notifier).ready);

/// Independent local artwork; original audio, embedded tags and source pictures
/// are never modified. Imported images are normalized and kept in app storage.
class ArtworkPreferences extends StateNotifier<Map<String, String>> {
  final Future<Directory> Function() directory;
  late final Future<void> ready = _load();
  ArtworkPreferences({Future<Directory> Function()? directory})
      : directory = directory ?? getApplicationSupportDirectory,
        super({}) {
    ready;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final decoded = jsonDecode(prefs.getString('harbor_artwork_v1') ?? '{}');
      if (mounted && decoded is Map) {
        state = decoded.map((key, value) => MapEntry('$key', '$value'))
          ..remove('preset:track');
      }
    } catch (_) {
      // Invalid preferences should not prevent browsing or playback.
    }
  }

  Future<void> setImage(String key, String source) async {
    await ready;
    final file = File(source);
    if (await file.length() > 30 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 30 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 30 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 30 MB.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final scale =
          math.min(1.0, 1600 / math.max(descriptor.width, descriptor.height));
      codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (descriptor.width * scale).round()),
          targetHeight: math.max(1, (descriptor.height * scale).round()));
      image = (await codec.getNextFrame()).image;
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw const FormatException('Could not read this image.');
      }
      final folder = Directory('${(await directory()).path}/harbor_artwork');
      await folder.create(recursive: true);
      final target =
          File('${folder.path}/${DateTime.now().microsecondsSinceEpoch}.png');
      await target.writeAsBytes(png.buffer.asUint8List(), flush: true);
      final updated = {...state, key: target.path};
      await _save(updated);
      if (mounted) state = updated;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  Future<void> reset(String key) async {
    await ready;
    final updated = {...state}..remove(key);
    await _save(updated);
    if (mounted) state = updated;
  }

  Future<void> selectPlaybackCover(PlaybackCover cover) async {
    await ready;
    final updated = {...state, 'preset:player': cover.name}
      ..remove('default:player');
    await _save(updated);
    if (mounted) state = updated;
  }

  Future<void> _save(Map<String, String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('harbor_artwork_v1', jsonEncode(value));
  }
}
