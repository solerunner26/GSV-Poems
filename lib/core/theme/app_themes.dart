import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'neon_backdrop.dart';
import 'neon_tokens.dart';

/// One colour set. Every screen reads colours from here, never hard-coded.
///
/// Each theme is built from a base colour and ONE accent hue; the deeper shade
/// and the lighter highlight are derived from that hue.
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
    this.glow = const Color(0x00000000),
    this.accentDeep = const Color(0x00000000),
    this.accentLight = const Color(0x00000000),
    this.effect = AccentEffect.line,
  });

  /// Saved preference value. Kept stable across releases so a saved choice resolves.
  final String id;
  final Color bg, surface, ink, mute, primary, primaryDeep, onPrimary, accent, accentText, tint;
  final Color heroA, heroB, heroC, alertBg, alertBorder;
  final bool isDark;

  /// The theme's single accent hue, its deeper shade and its lighter highlight.
  final Color glow, accentDeep, accentLight;

  /// The local accent motion played once per press on raised surfaces.
  final AccentEffect effect;

  static const good = Color(0xFF2F8A55), neutral = Color(0xFF3A5BB0), bad = Color(0xFFC0392B);

  LinearGradient get buttonGradient => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primary, primaryDeep]);

  @override
  GsvColors copyWith() => this;

  @override
  GsvColors lerp(ThemeExtension<GsvColors>? other, double t) => t < 0.5 || other is! GsvColors ? this : other;
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
const _white = Color(0xFFFFFFFF), _black = Color(0xFF000000);

/// Builds a full theme from a base colour and one accent hue.
GsvColors _palette(String id, Color base, Color accent, AccentEffect effect, {required bool dark}) {
  final deep = _mix(accent, _black, dark ? 0.32 : 0.28);
  final light = _mix(accent, _white, 0.45);
  if (dark) {
    final ink = _mix(_white, accent, 0.06);
    return GsvColors(
      id: id,
      bg: base,
      surface: _mix(base, _white, 0.07),
      ink: ink,
      mute: _mix(ink, base, 0.30),
      primary: accent,
      primaryDeep: deep,
      onPrimary: _mix(base, _black, 0.35),
      accent: light,
      accentText: accent,
      tint: _mix(base, accent, 0.12),
      heroA: _mix(accent, base, 0.62),
      heroB: _mix(accent, base, 0.78),
      heroC: _mix(base, _black, 0.30),
      alertBg: _mix(base, accent, 0.14),
      alertBorder: _mix(base, accent, 0.55),
      isDark: true,
      glow: accent,
      accentDeep: deep,
      accentLight: light,
      effect: effect,
    );
  }
  const ink = Color(0xFF181B28);
  return GsvColors(
    id: id,
    bg: base,
    surface: _mix(base, _white, 0.72),
    ink: ink,
    mute: _mix(ink, base, 0.36),
    primary: accent,
    primaryDeep: deep,
    onPrimary: _white,
    accent: accent,
    accentText: _mix(accent, _black, 0.12),
    tint: _mix(base, accent, 0.08),
    heroA: accent,
    heroB: _mix(accent, _black, 0.12),
    heroC: _mix(accent, _black, 0.38),
    alertBg: _mix(base, accent, 0.08),
    alertBorder: _mix(base, accent, 0.45),
    isDark: false,
    glow: accent,
    accentDeep: deep,
    accentLight: light,
    effect: effect,
  );
}

// The six themes. Saved ids from earlier versions map onto them, so a choice
// made before this update still resolves.
final _firstLight = _palette('mor', const Color(0xFFF7F2E9), const Color(0xFF285CFF), AccentEffect.line, dark: false);
final _blueHour = _palette('night', const Color(0xFF0C1424), const Color(0xFF57E8FF), AccentEffect.halo, dark: true);
final _copperLantern = _palette('light', const Color(0xFF211812), const Color(0xFFFFB34D), AccentEffect.lift, dark: true);
final _violetSignal = _palette('neel', const Color(0xFF171223), const Color(0xFFB28AFF), AccentEffect.cornerTrace, dark: true);
final _rainGarden = _palette('van', const Color(0xFF101D18), const Color(0xFFB9F65C), AccentEffect.sweep, dark: true);
final _afterglow = _palette('kamal', const Color(0xFF23151D), const Color(0xFFFF7797), AccentEffect.arc, dark: true);

/// In the order the theme selector shows them.
final allThemes = [_firstLight, _blueHour, _copperLantern, _violetSignal, _rainGarden, _afterglow];

GsvColors themeById(String? id) => allThemes.firstWhere((t) => t.id == id, orElse: () => _firstLight);

const uiFont = 'HindVadodara';
const uiFallback = ['Hind', 'NotoSerifGujarati', 'TiroDevanagariHindi'];

/// Poem font for a language code.
String poemFont(String lang) => lang == 'hi' ? 'TiroDevanagariHindi' : 'NotoSerifGujarati';

/// Every page gets the animated backdrop behind its content.
class _BackdropPageTransitions extends PageTransitionsBuilder {
  const _BackdropPageTransitions();
  static const _slide = CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
    final page = AmbientBackdrop(child: child);
    if (MediaQuery.disableAnimationsOf(context)) return FadeTransition(opacity: animation, child: page);
    return _slide.buildTransitions(route, context, animation, secondary, page);
  }
}

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
  const transitions = _BackdropPageTransitions();
  return base.copyWith(
    // Pages are transparent: the animated backdrop shows through.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: c.bg,
    extensions: [c, NeonTokens.standard],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.iOS: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.linux: transitions,
        TargetPlatform.macOS: transitions,
        TargetPlatform.fuchsia: transitions,
      },
    ),
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
      actionTextColor: c.isDark ? c.primary : c.accentLight,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.primary.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.primary, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface, showDragHandle: true),
    cardTheme: CardThemeData(color: c.surface),
  );
}

extension GsvContext on BuildContext {
  GsvColors get gc => Theme.of(this).extension<GsvColors>()!;
}
