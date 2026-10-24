// lib/widgets/meteor_background.dart
// Ambient night-sky backdrop for the 2D screens: twinkling stars plus the odd
// green/yellow meteor streaking across. Painted behind `child`, never catches
// touches, and stays still when the OS asks for reduced motion. Tickers are
// muted automatically when the screen is covered by another route.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_colors.dart';

class MeteorBackground extends StatefulWidget {
  final Widget child;

  const MeteorBackground({super.key, required this.child});

  @override
  State<MeteorBackground> createState() => _MeteorBackgroundState();
}

class _MeteorBackgroundState extends State<MeteorBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _Sky _sky = _Sky();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _sky.step(elapsed);
      _frame.value++;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.of(context).disableAnimations;
    if (_animate && !_ticker.isActive) _ticker.start();
    if (!_animate && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _sky.resize(constraints.biggest);
                  return CustomPaint(
                    painter: _SkyPainter(_sky, _frame, isDark: isDark, twinkle: _animate),
                  );
                },
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Star {
  final double x, y, radius, phase, speed; // x/y are 0..1 of the screen
  const _Star(this.x, this.y, this.radius, this.phase, this.speed);
}

class _Meteor {
  double x, y;
  final double dx, dy, speed, length;
  final Color color;
  _Meteor(this.x, this.y, this.dx, this.dy, this.speed, this.length, this.color);
}

class _Sky {
  final math.Random _rng = math.Random();
  Size size = Size.zero;
  List<_Star> stars = const [];
  final List<_Meteor> meteors = [];
  double seconds = 0;
  double _lastSeconds = 0;
  double _nextMeteorAt = 1.0;

  void resize(Size newSize) {
    if (newSize == size || newSize.isEmpty) return;
    size = newSize;
    final count = math.min(160, (size.width * size.height / 7000).round());
    stars = List.generate(
      count,
      (_) => _Star(
        _rng.nextDouble(),
        _rng.nextDouble(),
        0.3 + _rng.nextDouble() * 1.2,
        _rng.nextDouble() * math.pi * 2,
        0.6 + _rng.nextDouble() * 1.4,
      ),
    );
  }

  void step(Duration elapsed) {
    seconds = elapsed.inMicroseconds / 1e6;
    final dt = (seconds - _lastSeconds).clamp(0.0, 0.1);
    _lastSeconds = seconds;
    if (size.isEmpty) return;

    if (seconds >= _nextMeteorAt) {
      _spawn();
      _nextMeteorAt = seconds + 1.2 + _rng.nextDouble() * 2.6;
    }
    for (final m in meteors) {
      m.x += m.dx * m.speed * dt;
      m.y += m.dy * m.speed * dt;
    }
    meteors.removeWhere((m) =>
        m.y > size.height + m.length || m.x < -m.length || m.x > size.width + m.length);
  }

  void _spawn() {
    // Mostly falling right-to-left, like a shower radiating from the top right.
    final fromRight = _rng.nextDouble() < 0.75;
    final angle = (fromRight ? 145 : 35) * math.pi / 180 + (_rng.nextDouble() - 0.5) * 0.25;
    meteors.add(_Meteor(
      fromRight ? size.width * (0.35 + _rng.nextDouble() * 0.75) : size.width * _rng.nextDouble() * 0.5,
      -20 + _rng.nextDouble() * size.height * 0.25,
      math.cos(angle),
      math.sin(angle),
      420 + _rng.nextDouble() * 420,
      90 + _rng.nextDouble() * 160,
      _rng.nextDouble() < 0.72 ? AppColors.accent : const Color(0xFFFFD740),
    ));
  }
}

class _SkyPainter extends CustomPainter {
  final _Sky sky;
  final bool isDark;
  final bool twinkle;

  _SkyPainter(this.sky, Listenable repaint, {required this.isDark, required this.twinkle})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint();
    final base = isDark ? const Color(0xFFE1F5E9) : const Color(0xFF0D0D0D);
    for (final s in sky.stars) {
      final a = twinkle ? 0.35 + 0.35 * math.sin(sky.seconds * s.speed + s.phase) : 0.5;
      starPaint.color = base.withValues(alpha: isDark ? a : a * 0.3);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.radius, starPaint);
    }

    final strength = isDark ? 0.95 : 0.7;
    for (final m in sky.meteors) {
      final head = Offset(m.x, m.y);
      final tail = Offset(m.x - m.dx * m.length, m.y - m.dy * m.length);
      // Fade out over the lower part of the screen so streaks don't cross content at full strength.
      final fade = (1 - math.max(0, (m.y - size.height * 0.7) / (size.height * 0.5))).clamp(0.0, 1.0);
      final trail = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(head, tail, [
          m.color.withValues(alpha: strength * fade),
          m.color.withValues(alpha: 0),
        ]);
      canvas.drawLine(head, tail, trail);
      canvas.drawCircle(head, 1.6, Paint()..color = Colors.white.withValues(alpha: strength * fade * 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.isDark != isDark || old.twinkle != twinkle;
}
