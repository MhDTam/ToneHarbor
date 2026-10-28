import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/data/repositories/artwork_preferences.dart';
import 'package:toneharbor/features/desktop/harbor_artwork.dart';
import 'package:toneharbor/features/desktop/harbor_themes.dart';
import 'package:toneharbor/features/desktop/harbor_settings.dart';
import 'package:toneharbor/core/utils/artwork_widget.dart';
import 'package:toneharbor/services/audio/artwork_provider.dart';

void main() {
  testWidgets(
      'portrait artwork bounds both decoded dimensions and rejects oversize files',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      final folder =
          await Directory.systemTemp.createTemp('harbor-image-bounds-');
      final prefs = ArtworkPreferences(directory: () async => folder);
      try {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawColor(const Color(0xFF286578), BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(100, 4000);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final source = File('${folder.path}/portrait.png');
        await source.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        await prefs.setImage('default:player', source.path);
        final codec = await ui.instantiateImageCodec(
            await File(prefs.state['default:player']!).readAsBytes());
        final decoded = (await codec.getNextFrame()).image;
        expect(decoded.width, 40);
        expect(decoded.height, 1600);
        decoded.dispose();
        codec.dispose();
        final oversized =
            await File('${folder.path}/large.png').open(mode: FileMode.write);
        await oversized.truncate(31 * 1024 * 1024);
        await oversized.close();
        final previous = prefs.state['default:player'];
        await expectLater(
            prefs.setImage('default:player', '${folder.path}/large.png'),
            throwsFormatException);
        expect(prefs.state['default:player'], previous);
      } finally {
        prefs.dispose();
        await folder.delete(recursive: true);
      }
    });
  });
  testWidgets('library and player defaults stay separate across every theme',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    await container.read(artworkPreferencesProvider.notifier).ready;
    expect(
        PlaybackCover.fromPreferences(
            container.read(artworkPreferencesProvider)),
        PlaybackCover.plant);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
            home: Row(children: [
          HarborArtwork(key: ValueKey('library-default'), size: 120),
          HarborArtwork(
              key: ValueKey('player-default'), size: 120, playback: true),
        ]))));
    String assetFor(String key) {
      final image = tester.widget<Image>(find.descendant(
          of: find.byKey(ValueKey(key)), matching: find.byType(Image)));
      return ((image.image as ResizeImage).imageProvider as AssetImage)
          .assetName;
    }

    for (final theme in HarborTheme.values) {
      await container.read(harborThemeProvider.notifier).setTheme(theme);
      await tester.pumpAndSettle();
      expect(assetFor('library-default'), endsWith('${theme.name}-track.png'));
      expect(assetFor('player-default'), harborPlantAsset(theme));
      expect(File(harborPlantAsset(theme)).existsSync(), isTrue);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets(
      'built-in playback choices update artwork and persist independently',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'harbor_artwork_v1': jsonEncode({
        'default:track': 'old-custom.png',
        'default:player': 'old-player-custom.png',
        'preset:track': 'neonOrb',
        'playlist:42': 'playlist-custom.png',
        trackPictureKey('song.mp3'): 'song-custom.png',
      })
    });
    final container = ProviderContainer();
    await container.read(artworkPreferencesProvider.notifier).ready;
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
          home: Scaffold(
              body: Column(children: [
        Expanded(child: HarborSettings()),
        HarborArtwork(key: ValueKey('chosen-cover'), size: 80, playback: true),
        HarborArtwork(key: ValueKey('library-cover'), size: 80),
        HarborArtwork(
            key: ValueKey('playlist-cover'), size: 80, playlist: true),
      ]))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pictures'));
    await tester.pumpAndSettle();
    for (final (name, asset) in [
      ('waveform', 'ocean-track.png'),
      ('plant', 'ocean-window-cover-v22.webp'),
    ]) {
      await tester.tap(find.byKey(ValueKey('playback-cover-$name')));
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.descendant(
          of: find.byKey(const ValueKey('chosen-cover')),
          matching: find.byType(Image)));
      expect(
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          endsWith(asset));
    }
    final images = container.read(artworkPreferencesProvider);
    expect(images.containsKey('default:player'), isFalse);
    expect(images['default:track'], 'old-custom.png');
    expect(images.containsKey('preset:track'), isFalse);
    expect(images['playlist:42'], 'playlist-custom.png');
    expect(images[trackPictureKey('song.mp3')], 'song-custom.png');
    final reloaded = ArtworkPreferences();
    await reloaded.ready;
    expect(PlaybackCover.fromPreferences(reloaded.state), PlaybackCover.plant);
    final libraryImage = tester.widget<Image>(find.descendant(
        of: find.byKey(const ValueKey('library-cover')),
        matching: find.byType(Image)));
    expect(
        ((libraryImage.image as ResizeImage).imageProvider as AssetImage)
            .assetName,
        endsWith('ocean-track.png'));
    final playlistImage = tester.widget<Image>(find.descendant(
        of: find.byKey(const ValueKey('playlist-cover')),
        matching: find.byType(Image)));
    expect(
        ((playlistImage.image as ResizeImage).imageProvider as AssetImage)
            .assetName,
        endsWith('ocean-playlist.png'));
    await tester.pumpWidget(const SizedBox());
    reloaded.dispose();
    container.dispose();
  });

  testWidgets(
      'imported artwork is copied, survives source removal and reload, and resets independently',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      final folder =
          await Directory.systemTemp.createTemp('toneharbor-artwork-test-');
      final source =
          await File('assets/images/harbor/defaults/forest-track.png')
              .copy('${folder.path}/chosen.png');
      final original = await source.readAsBytes();
      final prefs = ArtworkPreferences(directory: () async => folder);
      await prefs.ready;
      await prefs.setImage('playlist:42', source.path);
      await prefs.setImage('default:track', source.path);
      final installed = prefs.state['playlist:42']!;
      expect(installed, isNot(source.path));
      expect(await source.readAsBytes(), original);
      await source.delete();
      expect(await File(installed).exists(), isTrue);
      final reloaded = ArtworkPreferences(directory: () async => folder);
      await reloaded.ready;
      expect(reloaded.state['playlist:42'], installed);
      await reloaded.reset('playlist:42');
      expect(reloaded.state.containsKey('playlist:42'), isFalse);
      expect(reloaded.state.containsKey('default:track'), isTrue);
      prefs.dispose();
      reloaded.dispose();
      // Only the exact temporary directory created by this test is removed.
      expect(folder.path, contains('toneharbor-artwork-test-'));
      await folder.delete(recursive: true);
    });
  });

  testWidgets(
      'custom track picture takes priority over embedded and themed artwork',
      (tester) async {
    final custom =
        File('assets/images/harbor/defaults/amber-track.png').absolute.path;
    SharedPreferences.setMockInitialValues({
      'harbor_artwork_v1': jsonEncode({trackPictureKey('song.mp3'): custom})
    });
    var reads = 0;
    final container = ProviderContainer(overrides: [
      artworkBytesProvider.overrideWith((_, __) async {
        reads++;
        return File('assets/images/harbor/defaults/forest-track.png')
            .readAsBytes();
      }),
    ]);
    await container.read(artworkPreferencesProvider.notifier).ready;
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
            home: PlatformArtworkWidget(
                id: 1,
                path: 'song.mp3',
                size: 120,
                nullArtworkWidget: HarborArtwork(size: 120)))));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pumpAndSettle();
    final image = tester.widgetList<Image>(find.byType(Image)).firstWhere(
        (image) =>
            image.image is ResizeImage &&
            (image.image as ResizeImage).imageProvider is FileImage);
    expect(((image.image as ResizeImage).imageProvider as FileImage).file.path,
        custom);
    expect(image.color, isNull);
    expect(reads, 0, reason: 'A user cover must avoid embedded-art extraction');
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('missing custom picture falls back to the theme default',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'harbor_artwork_v1':
          jsonEncode({'default:playlist': 'missing-picture.png'})
    });
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: HarborArtwork(size: 120, playlist: true))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('harbor-audio-artwork')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('every theme has distinct audio and playlist defaults',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    await container
        .read(harborThemeProvider.notifier)
        .setTheme(HarborTheme.forest);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child:
            const MaterialApp(home: HarborArtwork(size: 160, playlist: true))));
    for (final theme in HarborTheme.values) {
      await container.read(harborThemeProvider.notifier).setTheme(theme);
      await tester.pumpAndSettle();
      final image = tester
          .widget<Image>(find.byKey(const ValueKey('harbor-audio-artwork')));
      expect(
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          endsWith('${theme.name}-playlist.png'));
      expect(
          File('assets/images/harbor/defaults/${theme.name}-track.png')
              .existsSync(),
          isTrue);
    }
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
