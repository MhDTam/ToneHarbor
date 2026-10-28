import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/features/desktop/harbor_window_frame.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('window_manager');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'isFullScreen' ? false : null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test(
      'normal window configuration removes the native frame without reintroducing DWM edges',
      () async {
    if (!Platform.isWindows) return;
    // The same policy is used at startup and after leaving the mini player.
    for (var transition = 0; transition < 2; transition++) {
      calls.clear();
      await configureHarborWindowFrame();
      expect(
          calls.map((call) => call.method), ['setAsFrameless', 'setHasShadow']);
      expect((calls.last.arguments as Map)['hasShadow'], isFalse);
    }
  });

  testWidgets('dragging an invisible side edge still requests native resizing',
      (tester) async {
    if (!Platform.isWindows) return;
    await tester.pumpWidget(const MaterialApp(
        home: HarborWindowFrame(
            child: Scaffold(body: Center(child: Text('Desktop'))))));
    final gesture = await tester.startGesture(const Offset(1, 200));
    await gesture.moveTo(const Offset(28, 200));
    await gesture.up();
    await tester.pumpAndSettle();
    final resize = calls.where((call) => call.method == 'startResizing');
    expect(resize, hasLength(1));
    expect((resize.single.arguments as Map)['left'], isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
