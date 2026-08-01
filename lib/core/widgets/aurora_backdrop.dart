import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Slow-drifting light blooms behind every screen. It is the single element
/// that makes the whole product feel like one continuous space.
class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop({
    super.key,
    required this.child,
    this.accent = AppPalette.auroraViolet,
    this.animated = true,
    this.intensity = 1.0,
    this.seed = 0,
  });

  final Widget child;
  final Color accent;
  final bool animated;
  final double intensity;

  /// Shifts the bloom layout so sibling screens do not look identical.
  final int seed;

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AuroraBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppPalette.canvasGradient),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) => CustomPaint(
                painter: _AuroraPainter(
                  t: _controller.value,
                  accent: widget.accent,
                  intensity: widget.intensity,
                  seed: widget.seed,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.t,
    required this.accent,
    required this.intensity,
    required this.seed,
  });

  final double t;
  final Color accent;
  final double intensity;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = seed * 0.7;
    _bloom(
      canvas,
      size,
      Offset(
        size.width * (0.22 + 0.12 * math.sin(t * 2 * math.pi + phase)),
        size.height * (0.18 + 0.06 * math.cos(t * 2 * math.pi + phase)),
      ),
      size.width * 0.85,
      accent.withValues(alpha: 0.30 * intensity),
    );
    _bloom(
      canvas,
      size,
      Offset(
        size.width * (0.86 + 0.10 * math.cos(t * 2 * math.pi * 0.8 + phase)),
        size.height * (0.34 + 0.08 * math.sin(t * 2 * math.pi * 0.8 + phase)),
      ),
      size.width * 0.72,
      AppPalette.auroraBlue.withValues(alpha: 0.22 * intensity),
    );
    _bloom(
      canvas,
      size,
      Offset(
        size.width * (0.52 + 0.14 * math.sin(t * 2 * math.pi * 0.6 + 2 + phase)),
        size.height * (0.82 + 0.05 * math.cos(t * 2 * math.pi * 0.6 + phase)),
      ),
      size.width * 0.95,
      AppPalette.auroraMagenta.withValues(alpha: 0.16 * intensity),
    );
  }

  void _bloom(Canvas canvas, Size size, Offset center, double radius, Color color) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
        stops: const <double>[0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.accent != accent || old.intensity != intensity;
}
