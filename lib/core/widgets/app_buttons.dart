import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

class AuroraButton extends StatelessWidget {
  const AuroraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 56,
    this.gradient,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;
  final Gradient? gradient;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !busy;
    final Color accent = Theme.of(context).colorScheme.primary;

    final Widget content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (busy)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        else if (icon != null) ...<Widget>[
          Icon(icon, size: 19, color: Colors.white),
          const SizedBox(width: 10),
        ],
        if (!busy)
          Text(
            label,
            style: AppType.titleS(color: Colors.white),
          ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        height: height,
        width: expanded ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[accent, AppPalette.auroraMagenta],
                ),
            boxShadow: <BoxShadow>[
              if (enabled)
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(height / 2),
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 26),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.tone = AppPalette.textSecondary,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Color tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: Material(
        color: AppPalette.glassFill,
        borderRadius: BorderRadius.circular(height / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: AppPalette.glassStroke),
            ),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: tone),
                  const SizedBox(width: 9),
                ],
                Text(label, style: AppType.titleS(color: tone)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon button used in headers and toolbars.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.tone = AppPalette.textPrimary,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color tone;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppPalette.glassFill,
        shape: CircleBorder(
          side: BorderSide(color: AppPalette.glassStroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: size * 0.46, color: tone),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
