import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_themes.dart';
import 'neon_tokens.dart';

/// Shared clock so every page's backdrop breathes in step (a page pushed on
/// top continues the same phase instead of starting over).
final Stopwatch _clock = Stopwatch()..start();

/// 0 → 1 → 0 over one cycle, easing in and out (a gradual build and fade).
double breath(double t) => 0.5 - 0.5 * math.cos(2 * math.pi * t);

/// Accent alpha of the backdrop at breath [b] (0 = soft tint, 1 = brightest),
/// scaled by the shared intensity token.
double backdropAlpha(double b, {required bool dark, double intensity = 1.0}) {
  final rest = dark ? NeonTokens.backdropRestDark : NeonTokens.backdropRestLight;
  final peak = dark ? NeonTokens.backdropPeakDark : NeonTokens.backdropPeakLight;
  return (rest + (peak - rest) * b) * intensity;
}

/// A broad, slowly drifting gradient painted behind a page's content. Text,
/// controls and layout above it never move. With reduced motion it holds a
/// still, mid-strength tint.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({super.key, required this.child});
  final Widget child;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Duration? _cycle;

  void _sync(Duration cycle, bool still) {
    if (still) {
      _c.stop();
      _c.value = 0.5;
      _cycle = null;
      return;
    }
    if (_cycle == cycle && _c.isAnimating) return;
    _cycle = cycle;
    _c.duration = cycle;
    _c.value = (_clock.elapsedMicroseconds / cycle.inMicroseconds) % 1.0;
    _c.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(context.neon.backdropCycle, context.reduceMotion);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gc;
    return Stack(fit: StackFit.passthrough, children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(painter: _BackdropPainter(_c, colors, context.neon.backdropIntensity, still: context.reduceMotion)),
        ),
      ),
      widget.child,
    ]);
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.t, this.c, this.intensity, {required this.still}) : super(repaint: t);
  final Animation<double> t;
  final GsvColors c;
  final double intensity;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = c.bg);
    final phase = t.value;
    final b = still ? 0.5 : breath(phase);
    final a = backdropAlpha(b, dark: c.isDark, intensity: intensity);
    final drift = 2 * math.pi * phase;
    // Two broad glows that drift slowly; the deeper shade anchors the opposite corner.
    void glow(Alignment at, double radius, Color color, double alpha) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: at,
            radius: radius,
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    glow(Alignment(-0.7 + 0.35 * math.sin(drift), -0.9 + 0.15 * math.cos(drift)), 1.25, c.glow, a);
    glow(Alignment(0.9 - 0.25 * math.cos(drift), 0.85 - 0.2 * math.sin(drift)), 1.1, c.accentDeep, a * 0.8);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.c != c || old.intensity != intensity || old.still != still;
}
