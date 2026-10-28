import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HarborTheme { forest, ocean, violet, amber, crimson }

const harborDefaultTheme = HarborTheme.ocean;

extension HarborThemeColors on HarborTheme {
  String get label => switch (this) {
        HarborTheme.forest => 'Forest',
        HarborTheme.ocean => 'Ocean',
        HarborTheme.violet => 'Violet',
        HarborTheme.amber => 'Amber',
        HarborTheme.crimson => 'Crimson',
      };
  Color get accent => switch (this) {
        HarborTheme.forest => const Color(0xFF7CE791),
        HarborTheme.ocean => const Color(0xFF67D5ED),
        HarborTheme.violet => const Color(0xFFCFACFF),
        HarborTheme.amber => const Color(0xFFFFD17C),
        HarborTheme.crimson => const Color(0xFFFF98A6),
      };
  Color get background => switch (this) {
        HarborTheme.forest => const Color(0xFF0B1413),
        HarborTheme.ocean => const Color(0xFF081116),
        HarborTheme.violet => const Color(0xFF100D17),
        HarborTheme.amber => const Color(0xFF17120C),
        HarborTheme.crimson => const Color(0xFF180C10),
      };
  Color get surface => this == HarborTheme.forest
      ? const Color(0xFF101918)
      : Color.lerp(background, accent, .045)!;
  Color get sidebar => this == HarborTheme.forest
      ? const Color(0xFF0D1616)
      : Color.lerp(background, Colors.white, .015)!;
  Color get input => this == HarborTheme.forest
      ? const Color(0xFF111C20)
      : Color.lerp(surface, Colors.white, .025)!;
  Color get border => this == HarborTheme.forest
      ? const Color(0xFF22312E)
      : Color.lerp(background, accent, .14)!;
}

class HarborThemeNotifier extends StateNotifier<HarborTheme> {
  int _revision = 0;
  late final Future<void> ready = _load();
  HarborThemeNotifier() : super(harborDefaultTheme) {
    ready;
  }
  Future<void> _load() async {
    final revision = _revision;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('harbor_theme');
    if (mounted && revision == _revision) {
      final migrate = prefs.getBool('harbor_ocean_default_v1') != true;
      state = migrate && (saved == null || saved == 'forest')
          ? harborDefaultTheme
          : HarborTheme.values
                  .where((value) => value.name == saved)
                  .firstOrNull ??
              harborDefaultTheme;
      if (migrate) {
        await prefs.setBool('harbor_ocean_default_v1', true);
        if (revision == _revision) {
          await prefs.setString('harbor_theme', state.name);
        }
      }
    }
  }

  Future<void> setTheme(HarborTheme theme) async {
    _revision++;
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('harbor_theme', theme.name);
    await prefs.setBool('harbor_ocean_default_v1', true);
  }
}

final harborThemeProvider =
    StateNotifierProvider<HarborThemeNotifier, HarborTheme>(
        (ref) => HarborThemeNotifier());
