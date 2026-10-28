import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Hiding the caption alone leaves Windows 10's colored non-client side frame.
Future<void> configureHarborWindowFrame() async {
  if (Platform.isWindows) {
    await windowManager.setAsFrameless();
    // Do not extend a DWM frame back into the client area.
    await windowManager.setHasShadow(false);
  } else {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setHasShadow(true);
  }
}

/// Replace native resize borders with invisible desktop hit areas.
class HarborWindowFrame extends StatelessWidget {
  final Widget child;
  const HarborWindowFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Platform.isWindows
      ? DragToResizeArea(
          key: const ValueKey('window-resize-edges'),
          resizeEdgeSize: 4,
          resizeEdgeColor: Colors.transparent,
          child: child)
      : child;
}
