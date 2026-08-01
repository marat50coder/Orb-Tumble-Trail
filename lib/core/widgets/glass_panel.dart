import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Frosted surface used for every card, sheet and bar in the app.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.blur = 18,
    this.tint,
    this.strokeColor,
    this.onTap,
    this.gradient,
    this.strong = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? tint;
  final Color? strokeColor;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.circular(radius);
    final Widget decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (tint ??
                (strong ? AppPalette.glassFillStrong : AppPalette.glassFill))
            : null,
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(
          color: strokeColor ??
              (strong
                  ? AppPalette.glassStrokeStrong
                  : AppPalette.glassStroke),
          width: 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    final Widget surface = ClipRRect(
      borderRadius: shape,
      child: blur <= 0
          ? decorated
          : BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: decorated,
            ),
    );

    final Widget body = onTap == null
        ? surface
        : Stack(
            children: <Widget>[
              surface,
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: shape,
                    splashColor: Colors.white.withValues(alpha: 0.06),
                    highlightColor: Colors.white.withValues(alpha: 0.03),
                    onTap: onTap,
                  ),
                ),
              ),
            ],
          );

    if (margin == null) return body;
    return Padding(padding: margin!, child: body);
  }
}
