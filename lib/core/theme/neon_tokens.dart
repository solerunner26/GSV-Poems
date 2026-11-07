import 'package:flutter/material.dart';

/// The local accent motion a theme plays once when a raised surface is pressed.
enum AccentEffect {
  /// A bright line grows along the bottom edge.
  line,

  /// A soft halo blooms around the surface.
  halo,

  /// The surface lifts a little on a warm glow.
  lift,

  /// A line traces from one corner along two edges.
  cornerTrace,

  /// A band of light sweeps across the surface.
  sweep,

  /// An arc draws around the far corner.
  arc,
}

/// Shared visual intensity and timing for glow, backdrop and press motion.
/// One set for the whole app; there are no per-screen variants and no settings.
@immutable
class NeonTokens extends ThemeExtension<NeonTokens> {
  const NeonTokens({
    required this.glowIntensity,
    required this.backdropIntensity,
    required this.backdropCycle,
    required this.accentDuration,
    required this.traceDuration,
  });

  /// 1.0 = the strongest glow of the approved preview.
  final double glowIntensity;

  /// 1.0 = the brightest backdrop of the approved preview.
  final double backdropIntensity;

  /// One slow breath of the backdrop: soft tint → brighter accent → back.
  final Duration backdropCycle;

  /// Length of the local accent motion on press.
  final Duration accentDuration;

  /// Length of the contour trace on a pressed symbol (draw, then fade).
  final Duration traceDuration;

  static const standard = NeonTokens(
    glowIntensity: 1.0,
    backdropIntensity: 1.0,
    backdropCycle: Duration(seconds: 16),
    accentDuration: Duration(milliseconds: 720),
    traceDuration: Duration(milliseconds: 900),
  );

  // Ceilings that 100 % maps to (alpha of the accent at the brightest point).
  static const backdropPeakDark = 0.30;
  static const backdropPeakLight = 0.18;
  static const backdropRestDark = 0.08;
  static const backdropRestLight = 0.05;
  static const glowPeak = 0.55;

  @override
  NeonTokens copyWith() => this;

  @override
  NeonTokens lerp(ThemeExtension<NeonTokens>? other, double t) => this;
}

extension NeonTokensContext on BuildContext {
  NeonTokens get neon => Theme.of(this).extension<NeonTokens>() ?? NeonTokens.standard;

  /// True when Android asks for less motion (Remove animations).
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
