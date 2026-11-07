import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The signature light motion each theme plays on its featured surface and
/// once on every press of a raised surface.
enum AccentEffect {
  /// A bright line draws in along the surface.
  line,

  /// A halo blooms around the focal symbol and settles.
  halo,

  /// Warm light rises from beneath the focal symbol; the surface lifts.
  lift,

  /// Two opposite corners draw in together.
  cornerTrace,

  /// A highlight travels along the foot of the surface.
  sweep,

  /// An arc draws around the focal symbol and fades to the resting glow.
  arc;

  /// How long the light takes to draw (the glow lingers 50 % longer).
  Duration get drawDuration => switch (this) {
    line => const Duration(milliseconds: 620),
    halo => const Duration(milliseconds: 940),
    lift => const Duration(milliseconds: 820),
    cornerTrace => const Duration(milliseconds: 680),
    sweep => const Duration(milliseconds: 760),
    arc => const Duration(milliseconds: 900),
  };
}

/// Shared visual intensity and timing for glow, backdrop and motion.
/// One set for the whole app; there are no per-screen variants and no settings.
@immutable
class NeonTokens extends ThemeExtension<NeonTokens> {
  const NeonTokens({
    required this.glowIntensity,
    required this.backdropIntensity,
    required this.backdropCycle,
    required this.driftCycle,
    required this.iconPulse,
    required this.traceDuration,
    required this.featuredRepeat,
  });

  /// 1.0 = full glow.
  final double glowIntensity;

  /// 1.0 = full background wash.
  final double backdropIntensity;

  /// One breath of the background wash: soft → bright → soft.
  final Duration backdropCycle;

  /// One loop of the wash drifting across the screen.
  final Duration driftCycle;

  /// One breath of the glow around symbols.
  final Duration iconPulse;

  /// The contour trace on a pressed symbol (draw, then fade).
  final Duration traceDuration;

  /// The featured surface replays its signature light this often.
  final Duration featuredRepeat;

  static const standard = NeonTokens(
    glowIntensity: 1.0,
    backdropIntensity: 1.0,
    backdropCycle: Duration(milliseconds: 7000),
    driftCycle: Duration(seconds: 19),
    iconPulse: Duration(milliseconds: 3300),
    traceDuration: Duration(milliseconds: 850),
    featuredRepeat: Duration(seconds: 11),
  );

  // Alpha of the background wash at its centre (100 % intensity).
  static const backdropPeakDark = 0.50;
  static const backdropPeakLight = 0.30;
  static const backdropRestDark = 0.14;
  static const backdropRestLight = 0.09;

  /// Cards let this much of the wash shine through.
  static const cardOpacityDark = 0.80;
  static const cardOpacityLight = 0.84;

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

/// 0 → 1 → 0 over one cycle, easing in and out.
double breath(double t) => 0.5 - 0.5 * math.cos(2 * math.pi * t);

/// One app-wide clock for ambient motion, so every glow breathes in step and
/// a newly opened page continues the same phase. It ticks only while
/// something is listening, at about 30 frames a second.
class NeonClock extends ChangeNotifier implements ValueListenable<double> {
  NeonClock._();
  static final NeonClock instance = NeonClock._();

  final Stopwatch _watch = Stopwatch()..start();
  Ticker? _ticker;
  Duration _last = Duration.zero;

  /// Seconds since the app started.
  @override
  double get value => _watch.elapsedMicroseconds / 1e6;

  /// Position 0..1 inside a repeating [cycle].
  double phase(Duration cycle) => (value * 1e6 / cycle.inMicroseconds) % 1.0;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _ticker ??= Ticker(_tick, debugLabel: 'NeonClock')..start();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _ticker?.dispose();
      _ticker = null;
      _last = Duration.zero;
    }
  }

  void _tick(Duration elapsed) {
    if (elapsed - _last < const Duration(milliseconds: 32)) return;
    _last = elapsed;
    notifyListeners();
  }
}
