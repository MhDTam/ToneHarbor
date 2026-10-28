import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/features/desktop/harbor_artwork.dart';
import 'package:toneharbor/features/desktop/harbor_themes.dart';

void main() {
  test('Export code-native default covers for every theme', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final folder = Directory('assets/images/harbor/defaults');
    await folder.create(recursive: true);
    for (final theme in HarborTheme.values) {
      for (final playlist in [false, true]) {
        final recorder = ui.PictureRecorder();
        HarborAudioCoverPainter(theme, playlist: playlist)
            .paint(Canvas(recorder), const Size(768, 768));
        final picture = recorder.endRecording();
        final image = await picture.toImage(768, 768);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
                '${folder.path}/${theme.name}-${playlist ? 'playlist' : 'track'}.png')
            .writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    }
  });
}
