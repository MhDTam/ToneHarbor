import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/features/desktop/harbor_shortcuts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('shortcut changes are saved only after successful registration',
      () async {
    if (!Platform.isWindows) return;
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('toneharbor/hotkeys');
    final ready = Completer<void>();
    var registrations = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'unregisterAll') return null;
      final values = Map<Object?, Object?>.from(call.arguments as Map);
      registrations++;
      if (registrations == HarborAction.values.length) ready.complete();
      return values['key'] != 0x58;
    });
    final container = ProviderContainer();
    addTearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final shortcuts = container.read(harborShortcutsProvider.notifier);
    await ready.future;
    expect(
        await shortcuts.update(
            HarborAction.playPause, const HarborBinding(3, 0x4b)),
        isTrue);
    expect(container.read(harborShortcutsProvider)[HarborAction.playPause]!.key,
        0x4b);
    expect(
        (await SharedPreferences.getInstance())
            .getString('toneharbor_shortcuts'),
        contains('[3,75]'));
    expect(
        await shortcuts.update(
            HarborAction.playPause, const HarborBinding(3, 0x27)),
        isFalse);
    expect(
        await shortcuts.update(
            HarborAction.playPause, const HarborBinding(3, 0x58)),
        isFalse);
    expect(container.read(harborShortcutsProvider)[HarborAction.playPause]!.key,
        0x4b);
    await shortcuts.reset();
    expect(container.read(harborShortcutsProvider)[HarborAction.playPause]!.key,
        0x50);
  });
}
