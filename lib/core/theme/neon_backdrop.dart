import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_themes.dart';
import 'neon_tokens.dart';

export 'neon_tokens.dart' show breath;

/// Accent alpha at the centre of the wash at breath [b] (0 = soft, 1 = brightest),
/// scaled by the shared intensity token. On dark pages a very bright neon
/// ([glow]) is laid on more thinly, so text on the page stays readable.
double backdropAlpha(double b, {required bool dark, double intensity = 1.0, Color? glow}) {
  final rest = dark ? NeonTokens.backdropRestDark : NeonTokens.backdropRestLight;
  final peak = dark ? NeonTokens.backdropPeakDark : NeonTokens.backdropPeakLight;
  final tame = dark && glow != null ? (0.5 / math.max(glow.computeLuminance(), 0.01)).clamp(0.55, 1.0) : 1.0;
  return (rest + (peak - rest) * b) * intensity * tame;
}

/// A broad wash of the theme's neon that builds, drifts across the page and
/// fades, behind all content. Text, controls and layout above it never move.
/// With reduced motion it holds a still, mid-strength wash.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = context.reduceMotion;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _BackdropPainter(context.gc, context.neon, still ? null : NeonClock.instance))),
        ),
        child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.c, this.tokens, this.clock) : super(repaint: clock);
  final GsvColors c;
  final NeonTokens tokens;
  final NeonClock? clock;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = c.bg);
    final clk = clock;
    final b = clk == null ? 0.5 : breath(clk.phase(tokens.backdropCycle));
    final d = clk == null ? 0.15 : clk.phase(tokens.driftCycle);
    final a = backdropAlpha(b, dark: c.isDark, intensity: tokens.backdropIntensity, glow: c.glow);
    final w = size.width, h = size.height;
    final reach = math.max(w, h * 0.55);
    final ang = 2 * math.pi * d;

    void wash(Offset centre, double radius, Color color, double alpha) {
      final r = Rect.fromCircle(center: centre, radius: radius);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.56),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.42, 1],
          ).createShader(r),
      );
    }

    // Main wash: travels diagonally from the upper left towards the middle and back.
    final travel = breath(d);
    wash(Offset(w * (0.05 + 0.5 * travel) + 18 * math.sin(ang * 3), h * (0.04 + 0.30 * travel)), reach, c.glow, a);
    // Deeper counter-wash from the lower right, out of step with the first.
    wash(
      Offset(w * (1.0 - 0.35 * math.sin(ang).abs()), h * (0.95 - 0.25 * travel)),
      reach * 0.9,
      c.accentDeep,
      backdropAlpha(1 - b, dark: c.isDark, intensity: tokens.backdropIntensity, glow: c.glow) * 0.85,
    );
    // A small bright drift that wanders slowly.
    wash(Offset(w * (0.5 + 0.38 * math.cos(ang * 2)), h * (0.5 + 0.32 * math.sin(ang))), reach * 0.38, c.glow, a * 0.55);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.c != c || old.tokens != tokens || old.clock != clock;
}
