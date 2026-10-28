import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/core/utils/app_toast.dart';
import 'package:toneharbor/data/models/song_model.dart';
import 'package:toneharbor/features/desktop/harbor_themes.dart';
import 'package:toneharbor/features/desktop/harbor_track_menu.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/l10n/app_localizations.dart';

final _song = SongModel(
    id: 8,
    title: 'Evening reflections',
    artist: 'ToneHarbor Sessions',
    album: 'Quiet',
    data: 'C:/Music/evening.flac',
    duration: 264000,
    dateAdded: 1);

class _Harness {
  final ProviderContainer container;
  final BuildContext context;
  _Harness(this.container, this.context);
  Future<String?> menu(
          {Offset position = const Offset(160, 120), bool custom = true}) =>
      showHarborTrackMenu(context,
          globalPosition: position,
          song: _song,
          liked: false,
          customPicture: custom);
}

Future<_Harness> _mount(WidgetTester tester,
    {HarborTheme theme = HarborTheme.ocean,
    Size size = const Size(1200, 800),
    Locale locale = const Locale('en')}) async {
  SharedPreferences.setMockInitialValues({});
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final container = ProviderContainer();
  await container.read(harborThemeProvider.notifier).ready;
  await container.read(harborThemeProvider.notifier).setTheme(theme);
  late BuildContext context;
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('chrome-capture'),
      child: UncontrolledProviderScope(
          container: container,
          child: Consumer(
              builder: (_, ref, __) => MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildHarborTheme(ref.watch(harborThemeProvider)),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(body: Builder(builder: (value) {
                    context = value;
                    return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Library',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 20),
                              Expanded(
                                  child: ListView.builder(
                                      itemCount: 80,
                                      itemExtent: 64,
                                      itemBuilder: (_, i) => ListTile(
                                          leading: const Icon(Icons.graphic_eq),
                                          title: Text(i == 0
                                              ? _song.title
                                              : 'Track ${i + 1}'),
                                          subtitle: Text(_song.artist),
                                          trailing: const Text('04:24')))),
                            ]));
                  })))))));
  await tester.pumpAndSettle();
  return _Harness(container, context);
}

Future<void> _unmount(WidgetTester tester, _Harness harness) async {
  AppToast.dismiss();
  await tester.pumpWidget(const SizedBox());
  harness.container.dispose();
  debugDefaultTargetPlatformOverride = null;
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  expect(tester.takeException(), isNull);
}

Future<void> _hoverSubmenu(WidgetTester tester, String group) async {
  final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await pointer.addPointer(location: Offset.zero);
  await pointer
      .moveTo(tester.getCenter(find.byKey(ValueKey('track-menu-$group'))));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
  await pointer.removePointer();
}

void main() {
  testWidgets(
      'submenus support mouse clicks and directional keyboard navigation',
      (tester) async {
    final harness = await _mount(tester);
    var result = harness.menu();
    await tester.pumpAndSettle();
    for (var i = 0; i < 7; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('track-menu-edit')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(await result, 'edit');
    result = harness.menu();
    await tester.pumpAndSettle();
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    final point =
        tester.getCenter(find.byKey(const ValueKey('track-menu-file-group')));
    await pointer.moveTo(point);
    await tester.pump(const Duration(milliseconds: 16));
    await pointer.down(point);
    await pointer.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('track-menu-copy')), findsOneWidget);
    await pointer.removePointer();
    await _unmount(tester, harness);
    expect(await result, isNull);
  });
  testWidgets(
      'compact menu preserves file and edit actions in keyboard capable submenus',
      (tester) async {
    final harness = await _mount(tester);
    final selected = harness.menu();
    await tester.pumpAndSettle();
    final play = find.byKey(const ValueKey('track-menu-play'));
    final remove = find.byKey(const ValueKey('track-menu-delete'));
    expect(tester.getRect(remove).bottom - tester.getRect(play).top,
        lessThan(420));
    expect(find.byKey(const ValueKey('track-menu-copy')), findsNothing);
    await _hoverSubmenu(tester, 'file-group');
    expect(find.byKey(const ValueKey('track-menu-details')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('track-menu-copy')));
    await tester.pumpAndSettle();
    expect(await selected, 'copy');
    expect(play, findsNothing);
    final edit = harness.menu();
    await tester.pumpAndSettle();
    await _hoverSubmenu(tester, 'edit-group');
    expect(
        find.byKey(const ValueKey('track-menu-resetPicture')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('track-menu-convert')));
    await tester.pumpAndSettle();
    expect(await edit, 'convert');
    await _unmount(tester, harness);
  });

  testWidgets(
      'menu dismisses outside, with Escape, on replacement and owner disposal',
      (tester) async {
    var harness = await _mount(tester);
    var result = harness.menu();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await result, isNull);
    result = harness.menu();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(1000, 700));
    await tester.pumpAndSettle();
    expect(await result, isNull);
    final first = harness.menu();
    await tester.pumpAndSettle();
    result = harness.menu();
    await tester.pumpAndSettle();
    expect(await first, isNull);
    await _unmount(tester, harness);
    expect(await result, isNull);
    harness = await _mount(tester);
    result = harness.menu();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('track-menu-play')));
    await tester.pumpAndSettle();
    expect(await result, 'play');
    await _unmount(tester, harness);
  });

  testWidgets(
      'menu stays on screen at window edges and follows all live themes',
      (tester) async {
    final harness = await _mount(tester, size: const Size(900, 650));
    final result = harness.menu(position: const Offset(895, 645));
    await tester.pumpAndSettle();
    for (final theme in HarborTheme.values) {
      await harness.container
          .read(harborThemeProvider.notifier)
          .setTheme(theme);
      await tester.pumpAndSettle();
      final anchor = tester
          .widget<MenuAnchor>(find.byKey(const ValueKey('desktop-track-menu')));
      expect(anchor.style!.backgroundColor!.resolve({}), theme.surface);
      for (final id in ['play', 'delete', 'edit-group']) {
        final rect = tester.getRect(find.byKey(ValueKey('track-menu-$id')));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(900));
        expect(rect.bottom, lessThanOrEqualTo(650));
      }
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await result, isNull);
    await _unmount(tester, harness);
  });

  testWidgets('desktop scrollbars remain thin and theme tinted while scrolling',
      (tester) async {
    final harness = await _mount(tester);
    expect(find.byType(Scrollbar), findsWidgets);
    for (final theme in HarborTheme.values) {
      await harness.container
          .read(harborThemeProvider.notifier)
          .setTheme(theme);
      await tester.pumpAndSettle();
      final style = Theme.of(harness.context).scrollbarTheme;
      expect(style.thickness!.resolve({}), 3);
      expect(style.thickness!.resolve({WidgetState.hovered}), 5);
      expect(style.thickness!.resolve({WidgetState.dragged}), 6);
      expect(style.thumbColor!.resolve({}), theme.accent.withAlpha(65));
      expect(style.trackColor!.resolve({}), Colors.transparent);
    }
    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(200));
    await _unmount(tester, harness);
  });

  testWidgets(
      'desktop notice is compact, themed, accessible, and explicitly dismissible',
      (tester) async {
    final harness = await _mount(tester);
    AppToast.success(harness.context, 'File path copied');
    await tester.pumpAndSettle();
    final notice = find.byKey(const ValueKey('desktop-notice'));
    expect(tester.getSize(notice).width, 380);
    expect(tester.getSize(notice).height, lessThan(80));
    expect(tester.getTopLeft(notice).dy, 76);
    expect(find.descendant(of: notice, matching: find.byType(BackdropFilter)),
        findsNothing);
    expect(find.descendant(of: notice, matching: find.byType(ScaleTransition)),
        findsNothing);
    expect(
        find.descendant(
            of: notice,
            matching: find.byWidgetPredicate((widget) =>
                widget is Semantics && widget.properties.liveRegion == true)),
        findsOneWidget);
    for (final theme in HarborTheme.values) {
      await harness.container
          .read(harborThemeProvider.notifier)
          .setTheme(theme);
      await tester.pump();
      expect(tester.widget<Material>(notice).color, theme.surface);
    }
    await tester.tap(find.byKey(const ValueKey('desktop-notice-close')));
    await tester.pumpAndSettle();
    expect(notice, findsNothing);
    await _unmount(tester, harness);
  });

  testWidgets(
      'notice timeout pauses for reading and replacement/disposal cancels pending work',
      (tester) async {
    var harness = await _mount(tester);
    AppToast.show(harness.context,
        message: 'First', duration: const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse
        .moveTo(tester.getCenter(find.byKey(const ValueKey('desktop-notice'))));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('First'), findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    AppToast.success(harness.context, 'Replaced');
    await tester.pump();
    AppToast.error(harness.context, 'Latest');
    await tester.pumpAndSettle();
    expect(find.text('Replaced'), findsNothing);
    expect(find.text('Latest'), findsOneWidget);
    await mouse.removePointer();
    // Let the overlay owner dispose while a timed notification is still open.
    await tester.pumpWidget(const SizedBox());
    harness.container.dispose();
    harness = await _mount(tester);
    AppToast.success(harness.context, 'New owner');
    await tester.pumpAndSettle();
    expect(find.text('New owner'), findsOneWidget);
    await _unmount(tester, harness);
  });

  testWidgets('Arabic menu and notice fit a narrow desktop', (tester) async {
    final harness = await _mount(tester,
        locale: const Locale('ar'), size: const Size(900, 650));
    final result = harness.menu(position: const Offset(30, 80));
    AppToast.success(harness.context, 'تمت إضافة المقطع إلى قائمة التشغيل');
    await tester.pumpAndSettle();
    await _hoverSubmenu(tester, 'edit-group');
    expect(find.text('تحرير الصوت'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('track-menu-edit')));
    await tester.pumpAndSettle();
    expect(await result, 'edit');
    await _unmount(tester, harness);
  });

  if (const bool.fromEnvironment('HARBOR_PREVIEW')) {
    for (final theme in [HarborTheme.ocean, HarborTheme.forest]) {
      testWidgets('capture desktop controls ${theme.name}', (tester) async {
        await tester.runAsync(() async {
          await (FontLoader('Segoe UI')
                ..addFont(File(r'C:\Windows\Fonts\segoeui.ttf')
                    .readAsBytes()
                    .then((b) => ByteData.sublistView(b))))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
        final harness = await _mount(tester, theme: theme);
        final result = harness.menu(position: const Offset(170, 145));
        AppToast.success(harness.context, '3 tracks added to queue');
        await tester.pumpAndSettle();
        await _hoverSubmenu(tester, 'edit-group');
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('chrome-capture')));
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('output').create(recursive: true);
          await File('output/ToneHarbor-desktop-controls-v23-${theme.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await _unmount(tester, harness);
        expect(await result, isNull);
      });
    }
  }
}
