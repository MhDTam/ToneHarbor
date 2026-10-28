import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Locale Provider
// ─────────────────────────────────────────────────────────────────────────────
const _kLocaleKey = 'app_locale';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier({Locale? initialLocale})
      : super(initialLocale ?? const Locale('en'));

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey) ?? 'en';
    state = Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

final isFirstRunProvider = Provider<bool>((ref) {
  // Will be updated after initialization
  return false;
});
