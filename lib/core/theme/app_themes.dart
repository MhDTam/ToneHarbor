import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App Theme IDs
// ─────────────────────────────────────────────────────────────────────────────
enum AppThemeId {
  darkOcean,
  desertSand,
  aurora,
  midnight,
  lightBreeze,
  goldBlack,
  greenGrey,
  warmBrown,
  quran,
  ashura,
  ashura3,
  ramadan,
  blueSky,
  royalRed,
  emeraldGold,
  lavender,
  crescentTeal,
  royalCrimson,
}

class AppThemeData {
  final AppThemeId id;
  final String nameKey; // localization key
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color accent;
  final bool isDark;
  final List<Color> gradientColors;

  /// Optional full-screen artwork (asset path). When set, it is drawn over the
  /// gradient with a scrim of [backgroundImageOverlay].
  final String? backgroundImage;

  /// 0-255 alpha of the scrim drawn over [backgroundImage] (higher = darker).
  final int backgroundImageOverlay;

  /// Text/icon colour to use on top of [primary] (auto: dark on light colours,
  /// light on dark colours).
  Color get onPrimary =>
      primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  const AppThemeData({
    required this.id,
    required this.nameKey,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.accent,
    required this.isDark,
    required this.gradientColors,
    this.backgroundImage,
    this.backgroundImageOverlay = 150,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Predefined Themes
// ─────────────────────────────────────────────────────────────────────────────
const Map<AppThemeId, AppThemeData> kAppThemes = {
  AppThemeId.darkOcean: AppThemeData(
    id: AppThemeId.darkOcean,
    nameKey: 'darkOcean',
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF0077B6),
    background: Color(0xFF0A1118),
    surface: Color(0xFF132236),
    onSurface: Color(0xFFE1F5FE),
    accent: Color(0xFF1DE9B6),
    isDark: true,
    gradientColors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  ),
  AppThemeId.desertSand: AppThemeData(
    id: AppThemeId.desertSand,
    nameKey: 'desertSand',
    primary: Color(0xFFFF3D00),
    secondary: Color(0xFFC47B3A),
    background: Color(0xFF120608),
    surface: Color(0xFF260D12),
    onSurface: Color(0xFFFFF3E0),
    accent: Color(0xFFFFC400),
    isDark: true,
    gradientColors: [Color(0xFF2D1016), Color(0xFF1A0B0E), Color(0xFF0D0405)],
  ),
  AppThemeId.aurora: AppThemeData(
    id: AppThemeId.aurora,
    nameKey: 'aurora',
    primary: Color(0xFFF50057),
    secondary: Color(0xFF4568DC),
    background: Color(0xFF0B0410),
    surface: Color(0xFF1D0A31),
    onSurface: Color(0xFFF3E5F5),
    accent: Color(0xFF7E57C2),
    isDark: true,
    gradientColors: [Color(0xFF2C1A4A), Color(0xFF1D0A31), Color(0xFF0B0410)],
  ),
  AppThemeId.midnight: AppThemeData(
    id: AppThemeId.midnight,
    nameKey: 'midnight',
    primary: Color(0xFF1DE9B6),
    secondary: Color(0xFF00BFA5),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    onSurface: Color(0xFFE0F2F1),
    accent: Color(0xFF00BFA5),
    isDark: true,
    gradientColors: [Color(0xFF0A0A0A), Color(0xFF050505), Color(0xFF000000)],
  ),
  AppThemeId.lightBreeze: AppThemeData(
    id: AppThemeId.lightBreeze,
    nameKey: 'lightBreeze',
    primary: Color(0xFF00897B),
    secondary: Color(0xFF26A69A),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A2E2B),
    accent: Color(0xFF00BFA5),
    isDark: false,
    gradientColors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA), Color(0xFFEBEDF0)],
  ),
  AppThemeId.goldBlack: AppThemeData(
    id: AppThemeId.goldBlack,
    nameKey: 'goldBlack',
    primary: Color(0xFFFFD700),
    secondary: Color(0xFFDAA520),
    background: Color(0xFF000000),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFFFFFFF),
    accent: Color(0xFFFFD700),
    isDark: true,
    gradientColors: [Color(0xFF121212), Color(0xFF080808), Color(0xFF000000)],
  ),
  AppThemeId.greenGrey: AppThemeData(
    id: AppThemeId.greenGrey,
    nameKey: 'greenGrey',
    primary: Color(0xFF66BB6A),
    secondary: Color(0xFF4CAF50),
    background: Color(0xFF1E2723),
    surface: Color(0xFF2C3933),
    onSurface: Color(0xFFE8F5E9),
    accent: Color(0xFF81C784),
    isDark: true,
    gradientColors: [Color(0xFF1E2723), Color(0xFF18201C), Color(0xFF111714)],
  ),
  AppThemeId.warmBrown: AppThemeData(
    id: AppThemeId.warmBrown,
    nameKey: 'warmBrown',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFA0785A),
    background: Color(0xFF1A1210),
    surface: Color(0xFF2A1F1A),
    onSurface: Color(0xFFF5EDE6),
    accent: Color(0xFFE8C9A0),
    isDark: true,
    gradientColors: [Color(0xFF2A1F1A), Color(0xFF1F1612), Color(0xFF130E0B)],
  ),
  // ── Religious themes (artwork backgrounds in assets/images/themes/) ────────
  AppThemeId.quran: AppThemeData(
    id: AppThemeId.quran,
    nameKey: 'quran',
    primary: Color(0xFFD4AF37), // gold leaf
    secondary: Color(0xFF1E6E62), // deep teal
    background: Color(0xFF06110F),
    surface: Color(0xFF0E211E),
    onSurface: Color(0xFFEDE7D0),
    accent: Color(0xFFC9A227),
    isDark: true,
    gradientColors: [Color(0xFF071512), Color(0xFF0A1A18), Color(0xFF06110F)],
    backgroundImage: 'assets/images/themes/quran.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.ashura: AppThemeData(
    id: AppThemeId.ashura,
    nameKey: 'ashura',
    primary: Color(0xFFC62828), // deep red
    secondary: Color(0xFF7F1D1D),
    background: Color(0xFF0A0303),
    surface: Color(0xFF1A0808),
    onSurface: Color(0xFFF3E3E3),
    accent: Color(0xFFE53935),
    isDark: true,
    gradientColors: [Color(0xFF1A0505), Color(0xFF0F0303), Color(0xFF050101)],
    backgroundImage: 'assets/images/themes/ashura1.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.ashura3: AppThemeData(
    id: AppThemeId.ashura3,
    nameKey: 'hussaini',
    primary: Color(0xFF8A6D3B), // dark bronze (white text on it)
    secondary: Color(0xFF5A4A30),
    background: Color(0xFF000000),
    surface: Color(0xFF0B0A09),
    onSurface: Color(0xFFEDE9E1),
    accent: Color(0xFFA8894F),
    isDark: true,
    gradientColors: [Color(0xFF0A0908), Color(0xFF040403), Color(0xFF000000)],
    backgroundImage: 'assets/images/themes/hussaini.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.ramadan: AppThemeData(
    id: AppThemeId.ramadan,
    nameKey: 'ramadan',
    primary: Color(0xFFE3C27E), // lantern gold
    secondary: Color(0xFF1B3A5C), // night blue
    background: Color(0xFF070B16),
    surface: Color(0xFF101A2E),
    onSurface: Color(0xFFEAE3D2),
    accent: Color(0xFFF0C987),
    isDark: true,
    gradientColors: [Color(0xFF0A1020), Color(0xFF070B16), Color(0xFF04060E)],
    backgroundImage: 'assets/images/themes/ramadan.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.blueSky: AppThemeData(
    id: AppThemeId.blueSky,
    nameKey: 'blueSky',
    primary: Color(0xFF00B4D8),
    secondary: Color(0xFF0F3B66),
    background: Color(0xFF030D1A),
    surface: Color(0xFF081E36),
    onSurface: Color(0xFFF0F8FF),
    accent: Color(0xFFFFD166),
    isDark: true,
    gradientColors: [Color(0xFF030D1A), Color(0xFF071B33), Color(0xFF020914)],
    backgroundImage: 'assets/images/themes/blue_sky.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.royalRed: AppThemeData(
    id: AppThemeId.royalRed,
    nameKey: 'muharram',
    primary: Color(0xFFE50914),
    secondary: Color(0xFF5C0B14),
    background: Color(0xFF080203),
    surface: Color(0xFF180709),
    onSurface: Color(0xFFFDE8E9),
    accent: Color(0xFFFF2A3A),
    isDark: true,
    gradientColors: [Color(0xFF0D0305), Color(0xFF080203), Color(0xFF020001)],
    backgroundImage: 'assets/images/themes/royal_red.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.emeraldGold: AppThemeData(
    id: AppThemeId.emeraldGold,
    nameKey: 'emeraldGold',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF064E3B),
    background: Color(0xFF03170E),
    surface: Color(0xFF09291B),
    onSurface: Color(0xFFE6F7ED),
    accent: Color(0xFFD4AF37),
    isDark: true,
    gradientColors: [Color(0xFF03170E), Color(0xFF072417), Color(0xFF010C07)],
    backgroundImage: 'assets/images/themes/emerald_gold.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.lavender: AppThemeData(
    id: AppThemeId.lavender,
    nameKey: 'lavender',
    primary: Color(0xFF8A2BE2),
    secondary: Color(0xFFC084FC),
    background: Color(0xFFF8F5FD),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF26143D),
    accent: Color(0xFFA855F7),
    isDark: false,
    gradientColors: [Color(0xFFF9F6FE), Color(0xFFEDE4FA), Color(0xFFF3EDFD)],
    backgroundImage: 'assets/images/themes/lavender.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.crescentTeal: AppThemeData(
    id: AppThemeId.crescentTeal,
    nameKey: 'crescentTeal',
    primary: Color(0xFF00D2A0),
    secondary: Color(0xFF005F56),
    background: Color(0xFF021A18),
    surface: Color(0xFF052C28),
    onSurface: Color(0xFFE0F7F4),
    accent: Color(0xFFFFD166),
    isDark: true,
    gradientColors: [Color(0xFF021A18), Color(0xFF04221F), Color(0xFF010E0D)],
    backgroundImage: 'assets/images/themes/crescent_teal.jpg',
    backgroundImageOverlay: 0,
  ),
  AppThemeId.royalCrimson: AppThemeData(
    id: AppThemeId.royalCrimson,
    nameKey: 'royalCrimson',
    primary: Color(0xFFFF1E27),
    secondary: Color(0xFF8B1E28),
    background: Color(0xFF070203),
    surface: Color(0xFF160608),
    onSurface: Color(0xFFFDE8E9),
    accent: Color(0xFFFF3344),
    isDark: true,
    gradientColors: [Color(0xFF0E0305), Color(0xFF070203), Color(0xFF020101)],
    backgroundImage: 'assets/images/themes/royal_crimson.jpg',
    backgroundImageOverlay: 0,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Build ThemeData from AppThemeData
// ─────────────────────────────────────────────────────────────────────────────
/// Cache: building a [ThemeData] is expensive and `MaterialApp` used to rebuild
/// it on every single frame.
final Map<AppThemeId, ThemeData> _themeCache = {};

/// Returns the [ThemeData] for [t], building it only once per theme.
ThemeData buildThemeData(AppThemeData t) =>
    _themeCache.putIfAbsent(t.id, () => _createThemeData(t));

ThemeData _createThemeData(AppThemeData t) {
  const fontFamily = 'Inter';

  final colorScheme = ColorScheme(
    brightness: t.isDark ? Brightness.dark : Brightness.light,
    primary: t.primary,
    onPrimary: t.onPrimary,
    secondary: t.secondary,
    onSecondary: t.isDark ? Colors.black : Colors.white,
    error: const Color(0xFFCF6679),
    onError: Colors.white,
    surface: t.surface,
    onSurface: t.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: t.background,
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: t.onSurface,
      ),
      iconTheme: IconThemeData(color: t.onSurface),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: t.surface.withAlpha(230),
      selectedItemColor: t.primary,
      unselectedItemColor: t.onSurface.withAlpha(120),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: t.primary,
      inactiveTrackColor: t.primary.withAlpha(60),
      thumbColor: t.primary,
      overlayColor: t.primary.withAlpha(30),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          color: t.onSurface),
      displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          color: t.onSurface),
      titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: t.onSurface),
      titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: t.onSurface),
      titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: t.onSurface),
      bodyLarge:
          TextStyle(fontFamily: fontFamily, fontSize: 16, color: t.onSurface),
      bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: t.onSurface.withAlpha(200)),
      bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: t.onSurface.withAlpha(160)),
    ),
    iconTheme: IconThemeData(color: t.onSurface),
    dividerTheme:
        DividerThemeData(color: t.onSurface.withAlpha(30), thickness: 0.5),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: t.onSurface.withAlpha(100)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
