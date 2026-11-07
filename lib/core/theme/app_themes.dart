import 'package:flutter/material.dart';

/// One colour set. Every screen reads colours from here, never hard-coded.
@immutable
class GsvColors extends ThemeExtension<GsvColors> {
  const GsvColors({
    required this.id,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.primaryDeep,
    required this.onPrimary,
    required this.accent,
    required this.accentText,
    required this.tint,
    required this.heroA,
    required this.heroB,
    required this.heroC,
    required this.alertBg,
    required this.alertBorder,
    required this.isDark,
  });

  final String id;
  final Color bg, surface, ink, mute, primary, primaryDeep, onPrimary, accent, accentText, tint;
  final Color heroA, heroB, heroC, alertBg, alertBorder;
  final bool isDark;

  static const good = Color(0xFF2F5A3C), neutral = Color(0xFF283A70), bad = Color(0xFF9B2C2C);

  LinearGradient get buttonGradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primary, primaryDeep]);

  @override
  GsvColors copyWith() => this;

  @override
  GsvColors lerp(ThemeExtension<GsvColors>? other, double t) => t < 0.5 || other is! GsvColors ? this : other;
}

const _mor = GsvColors(
  id: 'mor', bg: Color(0xFFF4F7F6), surface: Color(0xFFFFFFFF), ink: Color(0xFF10302E), mute: Color(0xFF4F6664),
  primary: Color(0xFF0E5E5A), primaryDeep: Color(0xFF0B4C49), onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFFE8833A), accentText: Color(0xFFB4561A), tint: Color(0xFFE3EEEC),
  heroA: Color(0xFF2D6CB5), heroB: Color(0xFF0E5E5A), heroC: Color(0xFF0A403E),
  alertBg: Color(0xFFFFF0E3), alertBorder: Color(0xFFF2A65E), isDark: false,
);
const _light = GsvColors(
  id: 'light', bg: Color(0xFFF5F5F7), surface: Color(0xFFFFFFFF), ink: Color(0xFF1C1C1E), mute: Color(0xFF5C5C60),
  primary: Color(0xFF2D6CB5), primaryDeep: Color(0xFF1F5290), onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFF8E8E93), accentText: Color(0xFF5C5C60), tint: Color(0xFFE8ECF3),
  heroA: Color(0xFF4F8AD0), heroB: Color(0xFF2D6CB5), heroC: Color(0xFF1B4A80),
  alertBg: Color(0xFFEEF3FB), alertBorder: Color(0xFF9DB9E0), isDark: false,
);
const _night = GsvColors(
  id: 'night', bg: Color(0xFF0E1416), surface: Color(0xFF172124), ink: Color(0xFFE8F0EF), mute: Color(0xFFA7B8B6),
  primary: Color(0xFF5FD0C5), primaryDeep: Color(0xFF3AA79D), onPrimary: Color(0xFF06201E),
  accent: Color(0xFFF2A65E), accentText: Color(0xFFF2A65E), tint: Color(0xFF1F2D31),
  heroA: Color(0xFF1C3D5C), heroB: Color(0xFF12403D), heroC: Color(0xFF0A2423),
  alertBg: Color(0xFF2A2117), alertBorder: Color(0xFF8A5A2B), isDark: true,
);
const _kamal = GsvColors(
  id: 'kamal', bg: Color(0xFFF7F2F8), surface: Color(0xFFFFFFFF), ink: Color(0xFF2A1630), mute: Color(0xFF66506B),
  primary: Color(0xFFA0285F), primaryDeep: Color(0xFF7C1D49), onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFF2F7D5B), accentText: Color(0xFF256649), tint: Color(0xFFF1E4EF),
  heroA: Color(0xFF6B4FA0), heroB: Color(0xFFA0285F), heroC: Color(0xFF6E1A42),
  alertBg: Color(0xFFFBEAF1), alertBorder: Color(0xFFE39BBE), isDark: false,
);
const _neel = GsvColors(
  id: 'neel', bg: Color(0xFF0F1B3D), surface: Color(0xFF172654), ink: Color(0xFFEEF2FF), mute: Color(0xFFB9C3E6),
  primary: Color(0xFFF5B83D), primaryDeep: Color(0xFFD9981F), onPrimary: Color(0xFF1B1F3B),
  accent: Color(0xFF7FB2FF), accentText: Color(0xFF9EC4FF), tint: Color(0xFF1F2F63),
  heroA: Color(0xFF2E3A87), heroB: Color(0xFF1D2A66), heroC: Color(0xFF111A40),
  alertBg: Color(0xFF2A2A45), alertBorder: Color(0xFF8C7A3A), isDark: true,
);
const _van = GsvColors(
  id: 'van', bg: Color(0xFFEEF5EF), surface: Color(0xFFFFFFFF), ink: Color(0xFF15281B), mute: Color(0xFF4E6354),
  primary: Color(0xFF2F7D4F), primaryDeep: Color(0xFF22613C), onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFFC27C0E), accentText: Color(0xFF94600B), tint: Color(0xFFDDEBDF),
  heroA: Color(0xFF4C9A6A), heroB: Color(0xFF2F7D4F), heroC: Color(0xFF1C4F31),
  alertBg: Color(0xFFFFF4DE), alertBorder: Color(0xFFE2B866), isDark: false,
);

const allThemes = [_mor, _light, _night, _kamal, _neel, _van];

GsvColors themeById(String? id) => allThemes.firstWhere((t) => t.id == id, orElse: () => _mor);

const uiFont = 'HindVadodara';
const uiFallback = ['Hind', 'NotoSerifGujarati', 'TiroDevanagariHindi'];

/// Poem font for a language code.
String poemFont(String lang) => lang == 'hi' ? 'TiroDevanagariHindi' : 'NotoSerifGujarati';

ThemeData buildTheme(GsvColors c) {
  final scheme = ColorScheme(
    brightness: c.isDark ? Brightness.dark : Brightness.light,
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.accent,
    onSecondary: c.isDark ? c.bg : Colors.white,
    error: GsvColors.bad,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.ink,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: uiFont, fontFamilyFallback: uiFallback);
  TextStyle s(double size, FontWeight w, [Color? col]) =>
      TextStyle(fontSize: size, fontWeight: w, color: col ?? c.ink, fontFamily: uiFont, fontFamilyFallback: uiFallback, height: 1.35);
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    textTheme: base.textTheme.copyWith(
      headlineMedium: s(28, FontWeight.w700),
      titleLarge: s(20, FontWeight.w700),
      titleMedium: s(17, FontWeight.w600),
      bodyLarge: s(17, FontWeight.w400),
      bodyMedium: s(15, FontWeight.w400),
      bodySmall: s(14, FontWeight.w400, c.mute),
      labelLarge: s(17, FontWeight.w700),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.isDark ? c.surface : c.ink,
      contentTextStyle: s(16, FontWeight.w500, c.isDark ? c.ink : Colors.white),
      actionTextColor: c.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary.withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary.withValues(alpha: 0.2), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary, width: 2)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface, showDragHandle: true),
  );
}

extension GsvContext on BuildContext {
  GsvColors get gc => Theme.of(this).extension<GsvColors>()!;
}
