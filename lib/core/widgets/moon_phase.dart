import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Moon as it looks tonight: the lit part follows the Moon–Sun
/// [elongation] in degrees (0 = new moon, 180 = full moon). Waxing light
/// sits on the right, waning light on the left, as seen from India.
class MoonPhase extends StatelessWidget {
  const MoonPhase({super.key, required this.elongation, this.size = 60, this.glow, this.semanticLabel});
  final double elongation;
  final double size;
  final Color? glow;
  final String? semanticLabel;

  /// Share of the disc that is lit, 0..1.
  static double litFraction(double elongation) => (1 - math.cos(elongation * math.pi / 180)) / 2;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        image: true,
        child: CustomPaint(size: Size.square(size), painter: _MoonPainter(elongation % 360, glow)),
      );
}

class _MoonPainter extends CustomPainter {
  _MoonPainter(this.e, this.glow);
  final double e;
  final Color? glow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final disc = Rect.fromCircle(center: c, radius: r);
    final lit = MoonPhase.litFraction(e);

    // Soft halo, stronger as the Moon fills.
    final g = glow ?? const Color(0xFFFFF4D6);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = g.withValues(alpha: 0.25 + 0.45 * lit)
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, r * 0.35),
    );
    // Unlit disc (earthshine).
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0E1018).withValues(alpha: 0.35));
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFD6DDEB).withValues(alpha: 0.22));
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    // Lit part: between the bright limb and the terminator ellipse.
    final waxing = e < 180;
    final k = math.cos(e * math.pi / 180);
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final y = -r + 2 * r * i / steps;
      final w = math.sqrt(math.max(0, r * r - y * y));
      final x = waxing ? w : -w;
      i == 0 ? path.moveTo(c.dx + x, c.dy + y) : path.lineTo(c.dx + x, c.dy + y);
    }
    for (var i = steps; i >= 0; i--) {
      final y = -r + 2 * r * i / steps;
      final w = math.sqrt(math.max(0, r * r - y * y));
      final x = waxing ? k * w : -k * w;
      path.lineTo(c.dx + x, c.dy + y);
    }
    path.close();
    canvas.save();
    canvas.clipPath(Path()..addOval(disc));
    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: [Color(0xFFFFFBEF), Color(0xFFF1E6C8), Color(0xFFD9C9A0)],
          stops: [0, 0.6, 1],
        ).createShader(disc),
    );
    // A few soft maria, only where lit.
    canvas.clipPath(path);
    final mare = Paint()..color = const Color(0xFFB9A983).withValues(alpha: 0.35);
    canvas.drawCircle(c + Offset(-r * 0.25, -r * 0.2), r * 0.22, mare);
    canvas.drawCircle(c + Offset(r * 0.22, r * 0.05), r * 0.16, mare);
    canvas.drawCircle(c + Offset(-r * 0.05, r * 0.38), r * 0.12, mare);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.e != e || old.glow != glow;
}
