import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import 'glass_panel.dart';

/// Compact metric block: value on top, caption underneath.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.caption,
    this.icon,
    this.tone,
    this.valueSize = 24,
  });

  final String value;
  final String caption;
  final IconData? icon;
  final Color? tone;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final Color color = tone ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
        ],
        Text(value, style: AppType.numeric(valueSize)),
        const SizedBox(height: 5),
        Text(caption, style: AppType.bodyS()),
      ],
    );
  }
}

/// Horizontal bar with a soft gradient fill.
class AuroraBar extends StatelessWidget {
  const AuroraBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.background,
    this.radius,
  });

  final double value;
  final double height;
  final Gradient? gradient;
  final Color? background;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? height / 2;
    final Color accent = Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Container(
        height: height,
        color: background ?? AppPalette.glassFillStrong,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                gradient: gradient ??
                    LinearGradient(
                      colors: <Color>[accent, AppPalette.auroraMagenta],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ring progress indicator with an optional centre widget.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 96,
    this.stroke = 8,
    this.colors,
    this.center,
    this.track,
  });

  final double value;
  final double size;
  final double stroke;
  final List<Color>? colors;
  final Widget? center;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0.0, 1.0),
          stroke: stroke,
          colors: colors ?? <Color>[AppPalette.auroraBlue, accent, AppPalette.auroraMagenta],
          track: track ?? AppPalette.glassFillStrong,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.colors,
    required this.track,
  });

  final double value;
  final double stroke;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final double radius = (math.min(size.width, size.height) - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (value <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: <Color>[...colors, colors.first],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.stroke != stroke;
}

/// Tiny 30-point activity graph used on habit cards.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 34,
    this.barWidth = 3,
    this.gap = 2,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double barWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int maxBars =
              math.max(1, (constraints.maxWidth / (barWidth + gap)).floor());
          final List<double> shown = values.length <= maxBars
              ? values
              : values.sublist(values.length - maxBars);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (final double v in shown)
                Container(
                  width: barWidth,
                  height: math.max(3, height * (0.18 + 0.82 * v)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barWidth),
                    color: v <= 0
                        ? AppPalette.glassFillStrong
                        : color.withValues(alpha: 0.35 + 0.65 * v),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Full-bleed placeholder for screens without data yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.circleDashed,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppPalette.auroraSoft,
                border: Border.all(color: AppPalette.glassStroke),
              ),
              child: Icon(icon, size: 36, color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 22),
            Text(title, style: AppType.titleM(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppType.bodyM(), textAlign: TextAlign.center),
            if (action != null) ...<Widget>[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Row inside a settings-style list.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tone,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color color = tone ?? AppPalette.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 10 : 13, horizontal: 4),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppPalette.glassFill,
                  border: Border.all(color: AppPalette.glassStroke),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(title, style: AppType.titleS(color: color)),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppType.bodyS()),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 12),
                trailing!,
              ] else if (onTap != null)
                const Icon(
                  AppIcons.caretRight,
                  size: 16,
                  color: AppPalette.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped chip used for filters and tags.
class AuroraChip extends StatelessWidget {
  const AuroraChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : AppPalette.glassFill,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.75)
                  : AppPalette.glassStroke,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? accent : AppPalette.textSecondary,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: AppType.label(
                  color: selected ? AppPalette.textPrimary : AppPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card that highlights a single insight sentence.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final Color accent = tone ?? Theme.of(context).colorScheme.primary;
    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppType.titleS()),
                const SizedBox(height: 4),
                Text(body, style: AppType.bodyS(color: AppPalette.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
