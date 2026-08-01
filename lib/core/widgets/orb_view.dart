import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_palette.dart';
import '../../data/models/habit.dart';

class OrbArt {
  const OrbArt._();

  static String sprite(OrbSkin skin) => switch (skin) {
        OrbSkin.green => AppAssets.orbGreen,
        OrbSkin.orange => AppAssets.orbOrange,
        OrbSkin.purple => AppAssets.orbPurple,
        OrbSkin.red => AppAssets.orbRed,
      };

  static Color accent(OrbSkin skin) =>
      AppPalette.orbAccents[skin.name] ?? AppPalette.auroraViolet;

  static String label(OrbSkin skin) => switch (skin) {
        OrbSkin.green => 'Verdant',
        OrbSkin.orange => 'Ember',
        OrbSkin.purple => 'Nebula',
        OrbSkin.red => 'Crimson',
      };

  static String assetFor(OrbSkin skin, OrbState state) => switch (state) {
        OrbState.shattered => AppAssets.orbBroken,
        OrbState.resting => AppAssets.orbDormant,
        _ => sprite(skin),
      };
}

/// Renders a habit's orb at any size, reflecting its live state.
class OrbView extends StatefulWidget {
  const OrbView({
    super.key,
    required this.skin,
    this.state = OrbState.rolling,
    this.size = 64,
    this.momentum = 1,
    this.animated = true,
    this.showGlow = true,
    this.spin = false,
  });

  final OrbSkin skin;
  final OrbState state;
  final double size;

  /// 0…1 — scales the halo so lively orbs read brighter at a glance.
  final double momentum;
  final bool animated;
  final bool showGlow;

  /// Rotates the sprite, used while an orb is travelling.
  final bool spin;

  @override
  State<OrbView> createState() => _OrbViewState();
}

class _OrbViewState extends State<OrbView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant OrbView oldWidget) {
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

  double get _opacity => switch (widget.state) {
        OrbState.rolling => 1.0,
        OrbState.waiting => 0.62,
        OrbState.slipping => 0.5,
        OrbState.resting => 0.72,
        OrbState.shattered => 0.9,
      };

  double get _saturation => switch (widget.state) {
        OrbState.rolling => 1.0,
        OrbState.waiting => 0.45,
        OrbState.slipping => 0.2,
        OrbState.resting => 0.0,
        OrbState.shattered => 0.0,
      };

  @override
  Widget build(BuildContext context) {
    final Color accent = OrbArt.accent(widget.skin);
    final String asset = OrbArt.assetFor(widget.skin, widget.state);
    final bool lively = widget.state == OrbState.rolling;

    Widget sprite = Image.asset(
      asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (_saturation < 1) {
      sprite = ColorFiltered(
        colorFilter: ColorFilter.matrix(_saturationMatrix(_saturation)),
        child: sprite,
      );
    }

    sprite = Opacity(opacity: _opacity, child: sprite);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double breathe = lively ? 1 + 0.035 * _wave(t) : 1.0;
        final double haloAlpha = widget.showGlow
            ? (lively ? 0.22 + 0.16 * _wave(t) : 0.08) *
                (0.45 + 0.55 * widget.momentum.clamp(0.0, 1.0))
            : 0.0;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              if (widget.showGlow)
                Container(
                  width: widget.size * 1.25,
                  height: widget.size * 1.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: (widget.state == OrbState.shattered
                                ? AppPalette.danger
                                : accent)
                            .withValues(alpha: haloAlpha),
                        blurRadius: widget.size * 0.55,
                        spreadRadius: widget.size * 0.04,
                      ),
                    ],
                  ),
                ),
              Transform.scale(
                scale: breathe,
                child: widget.spin
                    ? Transform.rotate(angle: t * 6.28318, child: child)
                    : child,
              ),
            ],
          ),
        );
      },
      child: sprite,
    );
  }

  static double _wave(double t) {
    // Smooth 0→1→0 over the cycle.
    return 0.5 - 0.5 * (1 - 2 * (t < 0.5 ? t * 2 : (1 - t) * 2)).abs();
  }

  static List<double> _saturationMatrix(double s) {
    const double lr = 0.2126;
    const double lg = 0.7152;
    const double lb = 0.0722;
    final double sr = (1 - s) * lr;
    final double sg = (1 - s) * lg;
    final double sb = (1 - s) * lb;
    return <double>[
      sr + s, sg, sb, 0, 0, //
      sr, sg + s, sb, 0, 0, //
      sr, sg, sb + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
