import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_themes.dart';
import '../theme/neon_tokens.dart';

/// Wraps any raised surface and plays the active theme's accent motion once
/// each time it is pressed. It only listens to the pointer (it takes no part in
/// gestures), so the child's own tap action runs exactly as before: never
/// delayed, consumed, doubled or replaced. With reduced motion, a still accent
/// outline shows while the finger is down instead.
class NeonPressSurface extends StatefulWidget {
  const NeonPressSurface({super.key, required this.child, this.radius = 20});
  final Widget child;
  final double radius;

  @override
  State<NeonPressSurface> createState() => _NeonPressSurfaceState();
}

class _NeonPressSurfaceState extends State<NeonPressSurface> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  bool _held = false;

  AnimationController _ctrl(Duration d) => _c ??= AnimationController(vsync: this, duration: d);

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    if (context.reduceMotion) {
      setState(() => _held = true);
    } else {
      _ctrl(context.neon.accentDuration).forward(from: 0);
    }
  }

  void _up(PointerEvent _) {
    if (_held) setState(() => _held = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gc;
    final glow = context.neon.glowIntensity;
    final anim = _c;
    Widget body = widget.child;
    if (colors.effect == AccentEffect.lift && anim != null && !context.reduceMotion) {
      body = AnimatedBuilder(
        animation: anim,
        child: body,
        builder: (_, child) {
          final k = math.sin(math.pi * anim.value);
          return Transform.translate(offset: Offset(0, -3 * k), child: child);
        },
      );
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: CustomPaint(
        foregroundPainter: _AccentPainter(
          progress: anim,
          effect: colors.effect,
          color: colors.glow,
          deep: colors.accentDeep,
          radius: widget.radius,
          intensity: glow,
          held: _held,
        ),
        child: body,
      ),
    );
  }
}

class _AccentPainter extends CustomPainter {
  _AccentPainter({
    required this.progress,
    required this.effect,
    required this.color,
    required this.deep,
    required this.radius,
    required this.intensity,
    required this.held,
  }) : super(repaint: progress);

  final Animation<double>? progress;
  final AccentEffect effect;
  final Color color, deep;
  final double radius, intensity;
  final bool held;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius));
    if (held) {
      // Reduced motion: a still accent outline while pressed.
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.8 * intensity),
      );
      return;
    }
    final t = progress?.value ?? 0;
    if (t <= 0 || t >= 1) return;
    // Build quickly, hold, then fade.
    final grow = Curves.easeOutCubic.transform((t / 0.55).clamp(0.0, 1.0));
    final fade = t < 0.55 ? 1.0 : 1 - Curves.easeIn.transform((t - 0.55) / 0.45);
    final a = NeonTokens.glowPeak * intensity * fade;
    Paint line(double w, {double blur = 0}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;
    void glowLine(Path p) {
      canvas.drawPath(p, line(6, blur: 5)..color = color.withValues(alpha: a));
      canvas.drawPath(p, line(2)..color = color.withValues(alpha: math.min(1, a * 1.8)));
    }

    switch (effect) {
      case AccentEffect.line:
        final y = size.height - 2;
        glowLine(
          Path()
            ..moveTo(radius, y)
            ..lineTo(radius + (size.width - 2 * radius) * grow, y),
        );
      case AccentEffect.halo:
        final spread = 2 + 8 * grow;
        canvas.drawRRect(rr.inflate(spread / 2), line(spread, blur: 8)..color = color.withValues(alpha: a * 0.9));
        canvas.drawRRect(rr, line(1.5)..color = color.withValues(alpha: a));
      case AccentEffect.lift:
        canvas.drawRRect(
          rr.shift(const Offset(0, 4)),
          Paint()
            ..color = color.withValues(alpha: a * 0.7 * math.sin(math.pi * t))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      case AccentEffect.cornerTrace:
        final r = math.min(radius, size.shortestSide / 2);
        final path = Path()
          ..moveTo(1, size.height * (1 - 0.6 * grow))
          ..lineTo(1, r)
          ..arcToPoint(Offset(r, 1), radius: Radius.circular(r - 1))
          ..lineTo(r + (size.width * 0.6) * grow, 1);
        glowLine(path);
      case AccentEffect.sweep:
        final x = -size.width * 0.4 + size.width * 1.8 * grow;
        canvas.save();
        canvas.clipRRect(rr);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: a * 0.6),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
              transform: _Shift(x - size.width / 2),
            ).createShader(Rect.fromLTWH(0, 0, size.width * 0.5, size.height)),
        );
        canvas.restore();
      case AccentEffect.arc:
        final r = math.min(size.shortestSide * 0.55, 40.0);
        final c = Offset(size.width - r * 0.6, r * 0.6);
        glowLine(Path()..addArc(Rect.fromCircle(center: c, radius: r), math.pi * 0.5, math.pi * 1.4 * grow));
    }
  }

  @override
  bool shouldRepaint(_AccentPainter old) =>
      old.effect != effect || old.color != color || old.held != held || old.radius != radius || old.progress != progress;
}

class _Shift extends GradientTransform {
  const _Shift(this.dx);
  final double dx;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(dx, 0, 0);
}

/// The steady neon glow under a raised surface, scaled by the shared intensity token.
List<BoxShadow> neonGlow(GsvColors c, double intensity, {double strength = 1}) => [
  BoxShadow(
    color: c.glow.withValues(alpha: (c.isDark ? 0.22 : 0.14) * intensity * strength),
    blurRadius: 22 * strength,
    spreadRadius: -2,
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.08),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
];
