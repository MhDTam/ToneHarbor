import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';
import '../../services/audio/audio_handler.dart';
import '../utils/platform_utils.dart';
import '../../features/desktop/harbor_themes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme Provider
// ─────────────────────────────────────────────────────────────────────────────
const _kThemeKey = 'theme_id';

class ThemeNotifier extends StateNotifier<AppThemeId> {
  ThemeNotifier() : super(AppThemeId.darkOcean);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved != null) {
      final normalized = saved == 'ashura2' ? 'royalRed' : saved;
      state = AppThemeId.values.firstWhere(
        (e) => e.name == normalized,
        orElse: () => AppThemeId.darkOcean,
      );
    }
  }

  Future<void> setTheme(AppThemeId id, ToneHarborAudioHandler? handler) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, id.name);
    state = id;

    // Sync with background service
    if (handler != null) {
      await handler.customAction('setTheme', {'theme': id.name});
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeId>((ref) {
  return ThemeNotifier();
});

final currentThemeDataProvider = Provider<AppThemeData>((ref) {
  if (isDesktop) {
    final palette = ref.watch(harborThemeProvider);
    return AppThemeData(
      id: AppThemeId.darkOcean,
      nameKey: 'ToneHarbor',
      primary: palette.accent,
      secondary: palette.accent,
      background: palette.background,
      surface: palette.surface,
      onSurface: const Color(0xFFE0EBE5),
      accent: palette.accent,
      isDark: true,
      gradientColors: [palette.surface, palette.background],
    );
  }
  final id = ref.watch(themeProvider);
  return kAppThemes[id]!;
});
