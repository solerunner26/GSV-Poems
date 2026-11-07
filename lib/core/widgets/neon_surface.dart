import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_themes.dart';
import '../theme/neon_tokens.dart';

/// Wraps a raised surface: draws its neon edge, and plays the active theme's
/// signature light once each time it is pressed. A [featured] surface also
/// plays it when it appears and again every so often.
///
/// It only listens to the pointer and takes no part in gestures, so the
/// child's own tap action runs exactly as before: never delayed, consumed,
/// doubled or replaced. With reduced motion a still accent outline shows while
/// the finger is down, and nothing plays by itself.
class NeonPressSurface extends StatefulWidget {
  const NeonPressSurface({
    super.key,
    required this.child,
    this.radius = 20,
    this.interactive = true,
    this.featured = false,
    this.focal,
    this.focalRadius,
    this.edge = true,
  });

  final Widget child;
  final double radius;

  /// Plays the light on press.
  final bool interactive;

  /// Plays the light on appearance and periodically.
  final bool featured;

  /// Where the surface's main symbol sits (for halo, rise and arc). Without it
  /// those effects follow the surface's own outline.
  final Offset Function(Size size)? focal;
  final double? focalRadius;

  /// Draws the resting neon edge.
  final bool edge;

  @override
  State<NeonPressSurface> createState() => _NeonPressSurfaceState();
}

class _NeonPressSurfaceState extends State<NeonPressSurface> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Timer? _first, _repeat;
  bool _held = false;

  AnimationController _ctrl() {
    final d = context.gc.effect.drawDuration * 1.5;
    final c = _c ??= AnimationController(vsync: this, duration: d);
    if (c.duration != d) c.duration = d;
    return c;
  }

  void _play() {
    if (!mounted || context.reduceMotion || !TickerMode.valuesOf(context).enabled) return;
    final fresh = _c == null;
    final c = _ctrl();
    // A new controller must reach the painter before it can repaint it.
    if (fresh) setState(() {});
    c.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.featured && _repeat == null && !context.reduceMotion) {
      _first = Timer(const Duration(milliseconds: 450), _play);
      _repeat = Timer.periodic(context.neon.featuredRepeat, (_) => _play());
    }
  }

  @override
  void dispose() {
    _first?.cancel();
    _repeat?.cancel();
    _c?.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    if (context.reduceMotion) {
      setState(() => _held = true);
    } else {
      _play();
    }
  }

  void _up(PointerEvent _) {
    if (_held) setState(() => _held = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gc;
    final anim = _c;
    Widget body = widget.child;
    if (colors.effect == AccentEffect.lift && anim != null && !context.reduceMotion) {
      body = AnimatedBuilder(
        animation: anim,
        child: body,
        builder: (_, child) {
          final p = (anim.value * 1.5).clamp(0.0, 1.0);
          return Transform.translate(offset: Offset(0, -4 * math.sin(math.pi * p)), child: child);
        },
      );
    }
    final painted = CustomPaint(
      foregroundPainter: NeonAuraPainter(
        progress: anim,
        effect: colors.effect,
        colors: colors,
        radius: widget.radius,
        intensity: context.neon.glowIntensity,
        held: _held,
        focal: widget.focal,
        focalRadius: widget.focalRadius,
        edge: widget.edge,
      ),
      child: body,
    );
    if (!widget.interactive) return painted;
    return Listener(behavior: HitTestBehavior.translucent, onPointerDown: _down, onPointerUp: _up, onPointerCancel: _up, child: painted);
  }
}

/// Paints a surface's neon edge and, while [progress] runs, its signature light.
class NeonAuraPainter extends CustomPainter {
  NeonAuraPainter({
    required this.progress,
    required this.effect,
    required this.colors,
    required this.radius,
    required this.intensity,
    required this.held,
    this.focal,
    this.focalRadius,
    this.edge = true,
  }) : super(repaint: progress);

  final Animation<double>? progress;
  final AccentEffect effect;
  final GsvColors colors;
  final double radius, intensity;
  final bool held, edge;
  final Offset Function(Size size)? focal;
  final double? focalRadius;

  Color get _glow => colors.glow;

  /// Opacity of the light over the whole play: builds, peaks, settles, fades.
  static double energize(double t) {
    const keys = [(0.0, 0.0), (0.2, 0.35), (0.65, 1.0), (0.82, 0.6), (1.0, 0.0)];
    for (var i = 1; i < keys.length; i++) {
      if (t <= keys[i].$1) {
        final (t0, v0) = keys[i - 1];
        final (t1, v1) = keys[i];
        return v0 + (v1 - v0) * Curves.easeInOut.transform((t - t0) / (t1 - t0));
      }
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect.deflate(0.75), Radius.circular(radius));
    if (edge) _paintEdge(canvas, rect, rr);
    if (held) {
      // Reduced motion: a still accent outline while pressed.
      canvas.drawRRect(rr, _stroke(2.5)..color = _glow.withValues(alpha: 0.9 * intensity));
      canvas.drawRRect(rr, _stroke(6, blur: 5)..color = _glow.withValues(alpha: 0.5 * intensity));
      return;
    }
    final t = progress?.value ?? 0;
    if (t <= 0 || t >= 1) return;
    final e = energize(t) * intensity;
    final p = t * 1.5; // in units of the draw duration
    final drawn = const Cubic(0.2, 0.7, 0.3, 1).transform((p / 0.7).clamp(0.0, 1.0));
    final grow = Curves.easeOut.transform(p.clamp(0.0, 1.0));
    final w = size.width, h = size.height;
    final fc = focal?.call(size);
    final fr = focalRadius ?? (fc == null ? 0.0 : math.min(size.shortestSide * 0.36, 60.0));

    switch (effect) {
      case AccentEffect.line:
        final y = h - 14.0;
        _aura(
          canvas,
          Path()
            ..moveTo(radius, y)
            ..lineTo(w - radius, y),
          e,
          0,
          drawn,
        );
      case AccentEffect.halo:
        if (fc != null) {
          final r = fr * (0.94 + 0.30 * grow);
          _aura(canvas, Path()..addOval(Rect.fromCircle(center: fc, radius: r)), e, 0, 1, closed: true);
        } else {
          _aura(canvas, Path()..addRRect(rr.inflate(12 * grow - 4)), e, 0, 1, closed: true);
        }
      case AccentEffect.lift:
        final cx = fc?.dx ?? w / 2;
        final base = fc == null ? h - 10 : fc.dy + fr * 0.9;
        final half = fc == null ? w * 0.32 : fr * 0.75;
        final rise = 8 - 21 * grow;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, base + rise), width: half * 2, height: 7),
          Paint()
            ..color = _glow.withValues(alpha: e)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, base + rise), width: half * 2, height: 26),
          Paint()
            ..color = _glow.withValues(alpha: e * 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
        );
        _aura(
          canvas,
          Path()
            ..moveTo(cx - half * 1.1, base + 6)
            ..lineTo(cx + half * 1.1, base + 6),
          e,
          0,
          drawn,
        );
      case AccentEffect.cornerTrace:
        final r = math.min(radius, size.shortestSide / 2);
        final reach = math.min(w, h) * 0.42;
        _aura(
          canvas,
          Path()
            ..moveTo(1, r + reach)
            ..lineTo(1, r)
            ..arcToPoint(Offset(r, 1), radius: Radius.circular(r))
            ..lineTo(r + reach, 1),
          e,
          0,
          drawn,
        );
        _aura(
          canvas,
          Path()
            ..moveTo(w - r - reach, h - 1)
            ..lineTo(w - r, h - 1)
            ..arcToPoint(Offset(w - 1, h - r), radius: Radius.circular(r), clockwise: false)
            ..lineTo(w - 1, h - r - reach),
          e,
          0,
          drawn,
        );
      case AccentEffect.sweep:
        final r = math.min(radius, size.shortestSide / 2);
        final foot = Path()
          ..moveTo(1, h - r - 6)
          ..quadraticBezierTo(1, h - 1, r + 1, h - 1)
          ..lineTo(w - r - 1, h - 1)
          ..quadraticBezierTo(w - 1, h - 1, w - 1, h - r - 6);
        final s = -0.22 + 1.22 * Curves.easeInOut.transform(p.clamp(0.0, 1.0));
        _aura(canvas, foot, e, s, s + 0.22);
      case AccentEffect.arc:
        const start = 148 * math.pi / 180, sweep = 244 * math.pi / 180;
        final Path arc;
        if (fc != null) {
          arc = Path()..addArc(Rect.fromCircle(center: fc, radius: fr * 1.08), start, sweep);
        } else {
          final r = math.min(h * 0.42, 44.0);
          arc = Path()..addArc(Rect.fromCircle(center: Offset(w - r * 0.75, r * 0.75), radius: r), start, sweep);
        }
        _aura(canvas, arc, e, 0, drawn);
    }
  }

  void _paintEdge(Canvas canvas, Rect rect, RRect rr) {
    final a = (colors.isDark ? 0.55 : 0.42) * intensity;
    canvas.drawRRect(
      rr,
      _stroke(1.2)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _glow.withValues(alpha: a),
            _glow.withValues(alpha: a * 0.15),
            colors.accentDeep.withValues(alpha: a * 0.7),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  Paint _stroke(double width, {double blur = 0}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;

  /// Draws the part of [path] between [from] and [to] (fractions of its
  /// length) as neon: two blooms, then a core whose tip burns white.
  void _aura(Canvas canvas, Path path, double alpha, double from, double to, {bool closed = false}) {
    if (alpha <= 0.002) return;
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    if (total == 0) return;
    final a = from.clamp(0.0, 1.0) * total, b = to.clamp(0.0, 1.0) * total;
    if (b <= a) return;
    final part = Path();
    Offset? start, tip;
    var offset = 0.0;
    for (final m in metrics) {
      final s = (a - offset).clamp(0.0, m.length), e = (b - offset).clamp(0.0, m.length);
      if (e > s) {
        part.addPath(m.extractPath(s, e), Offset.zero);
        start ??= m.getTangentForOffset(s)?.position;
        tip = m.getTangentForOffset(e)?.position;
      }
      offset += m.length;
    }
    if (start == null || tip == null) return;
    canvas.drawPath(part, _stroke(9, blur: 14)..color = _glow.withValues(alpha: alpha * 0.85));
    canvas.drawPath(part, _stroke(6, blur: 5)..color = _glow.withValues(alpha: alpha));
    final core = _stroke(3.2)..color = _glow.withValues(alpha: alpha);
    if (!closed && (tip - start).distance > 4) {
      core.shader = ui.Gradient.linear(
        start,
        tip,
        [
          _glow.withValues(alpha: 0.12 * alpha),
          _glow.withValues(alpha: 0.68 * alpha),
          _glow.withValues(alpha: alpha),
          Colors.white.withValues(alpha: alpha),
          _glow.withValues(alpha: alpha),
        ],
        const [0, 0.45, 0.78, 0.92, 1],
      );
    }
    canvas.drawPath(part, core);
  }

  @override
  bool shouldRepaint(NeonAuraPainter old) =>
      old.effect != effect ||
      old.colors != colors ||
      old.held != held ||
      old.radius != radius ||
      old.progress != progress ||
      old.focal != focal ||
      old.edge != edge;
}

/// The steady neon glow under a raised surface, scaled by the shared intensity token.
List<BoxShadow> neonGlow(GsvColors c, double intensity, {double strength = 1}) => [
  BoxShadow(
    color: c.glow.withValues(alpha: (c.isDark ? 0.34 : 0.22) * intensity * strength),
    blurRadius: 24 * strength,
    blurStyle: BlurStyle.outer,
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: c.isDark ? 0.30 : 0.07),
    blurRadius: 10,
    offset: const Offset(0, 4),
    blurStyle: BlurStyle.outer,
  ),
];
