import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/desktop/harbor_window_frame.dart';

final isOverlayModeProvider = StateProvider<bool>((ref) => false);

class OverlaySettings {
  final double transparency;
  final bool blur;
  const OverlaySettings({this.transparency = 160.0, this.blur = true});
}

class OverlaySettingsNotifier extends StateNotifier<OverlaySettings> {
  Timer? _saveTimer;
  OverlaySettingsNotifier() : super(const OverlaySettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getDouble('overlay_transparency') ?? 160.0;
    final b = prefs.getBool('overlay_blur') ?? true;
    state = OverlaySettings(transparency: t, blur: b);
  }

  void updateTransparency(double t) {
    state = OverlaySettings(transparency: t, blur: state.blur);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 200), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('overlay_transparency', t);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void updateBlur(bool b) async {
    state = OverlaySettings(transparency: state.transparency, blur: b);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('overlay_blur', b);
  }

  void resetToDefault() async {
    state = const OverlaySettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('overlay_transparency');
    await prefs.remove('overlay_blur');
    await windowManager.setSize(const Size(380, 80));
    await windowManager.setAlignment(Alignment.bottomRight);
  }
}

final overlaySettingsProvider =
    StateNotifierProvider<OverlaySettingsNotifier, OverlaySettings>((ref) {
  return OverlaySettingsNotifier();
});

class OverlayModeManager {
  static String _previousRoute = '/';
  static Rect? _previousBounds;
  static bool _wasMaximized = false;

  static Future<void> enableOverlay(WidgetRef ref, BuildContext context) async {
    _previousRoute = GoRouterState.of(context).uri.toString();
    _previousBounds = await windowManager.getBounds();
    _wasMaximized = await windowManager.isMaximized();
    if (_wasMaximized) await windowManager.unmaximize();
    if (!context.mounted) return;
    ref.read(isOverlayModeProvider.notifier).state = true;
    context.go('/overlay');
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setHasShadow(false);
    await windowManager.setMaximizable(false);
    await windowManager.setMinimumSize(const Size(320, 80));
    await windowManager.setSize(const Size(480, 105));
    await windowManager.setResizable(true);
    await windowManager.setAlignment(Alignment.bottomRight);
  }

  static Future<void> disableOverlay(
      WidgetRef ref, BuildContext context) async {
    ref.read(isOverlayModeProvider.notifier).state = false;
    context.go(_previousRoute);
    await configureHarborWindowFrame();
    await windowManager.setMaximizable(true);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setMinimumSize(const Size(900, 650));
    if (_previousBounds != null) {
      await windowManager.setBounds(_previousBounds!);
    }
    if (_wasMaximized) await windowManager.maximize();
    await windowManager.setResizable(true);
    if (_previousBounds == null) await windowManager.center();
  }
}
