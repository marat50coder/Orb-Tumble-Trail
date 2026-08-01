import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Builds the serpentine path the orbs travel along. Kept in one place so the
/// painter and the orb placement always agree.
class TrailGeometry {
  const TrailGeometry._();

  static Path build(Size size, {bool compact = false}) {
    final double w = size.width;
    final double h = size.height;
    final double amp = compact ? 0.16 : 0.34;

    final Path path = Path()..moveTo(w * 0.5, h);
    path.cubicTo(
      w * (0.5 - amp), h * 0.88,
      w * (0.5 + amp), h * 0.76,
      w * 0.5, h * 0.64,
    );
    path.cubicTo(
      w * (0.5 - amp * 0.95), h * 0.52,
      w * (0.5 + amp * 0.95), h * 0.40,
      w * 0.5, h * 0.28,
    );
    path.cubicTo(
      w * (0.5 - amp * 0.6), h * 0.20,
      w * (0.5 + amp * 0.6), h * 0.12,
      w * 0.5, h * 0.02,
    );
    return path;
  }

  /// Point + direction at [t] (0 = bottom of the trail, 1 = the horizon).
  static ui.Tangent? tangentAt(Path path, double t) {
    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return null;
    final ui.PathMetric metric = metrics.first;
    return metric.getTangentForOffset(metric.length * t.clamp(0.0, 1.0));
  }
}

class TrailPainter extends CustomPainter {
  TrailPainter({
    required this.accent,
    required this.progress,
    required this.checkpoints,
    required this.compact,
    required this.glowPhase,
  });

  /// How much of the trail is lit up today (0…1).
  final double progress;
  final Color accent;
  final int checkpoints;
  final bool compact;
  final double glowPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = TrailGeometry.build(size, compact: compact);
    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final ui.PathMetric metric = metrics.first;

    // Stone bed.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 26
        ..color = Colors.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 16
        ..color = const Color(0xFF1B2136).withValues(alpha: 0.85),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 13
        ..color = Colors.white.withValues(alpha: 0.05),
    );

    // Travelled section, lit.
    if (progress > 0.001) {
      final Path lit = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
      final double pulse = 0.55 + 0.25 * math.sin(glowPhase * 2 * math.pi);

      canvas.drawPath(
        lit,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 22
          ..color = accent.withValues(alpha: 0.22 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawPath(
        lit,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 9
          ..shader = ui.Gradient.linear(
            Offset(size.width * 0.5, size.height),
            Offset(size.width * 0.5, 0),
            <Color>[accent, AppPalette.auroraMagenta, AppPalette.auroraBlue],
            <double>[0.0, 0.6, 1.0],
          ),
      );
      canvas.drawPath(
        lit,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: 0.55),
      );
    }

    // Checkpoint markers.
    for (int i = 1; i <= math.min(checkpoints, 6); i++) {
      final double t = i / 7;
      final ui.Tangent? tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent == null) continue;
      final Offset p = tangent.position;
      canvas.drawCircle(
        p,
        7,
        Paint()..color = accent.withValues(alpha: 0.20),
      );
      canvas.drawCircle(
        p,
        3.6,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrailPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.checkpoints != checkpoints ||
      old.glowPhase != glowPhase ||
      old.compact != compact;
}

/// Drifting motes of light that make the scene feel alive.
class MotePainter extends CustomPainter {
  MotePainter({required this.t, required this.color, required this.count});

  final double t;
  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rnd = math.Random(7);
    for (int i = 0; i < count; i++) {
      final double baseX = rnd.nextDouble();
      final double baseY = rnd.nextDouble();
      final double speed = 0.25 + rnd.nextDouble() * 0.7;
      final double radius = 0.8 + rnd.nextDouble() * 1.9;

      final double y = (baseY - t * speed) % 1.0;
      final double x = baseX + 0.03 * math.sin((t * speed + baseX) * 2 * math.pi);
      final double alpha =
          (0.12 + 0.4 * math.sin((t * speed + baseY) * 2 * math.pi).abs())
              .clamp(0.0, 0.55);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MotePainter old) => old.t != t;
}
