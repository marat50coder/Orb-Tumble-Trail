import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../state/settings_controller.dart';
import '../home/home_shell.dart';
import '../onboarding/onboarding_screen.dart';

/// Boot screen. The bar and the percentage are driven by the same value, so
/// they can never disagree, and the sequence is bounded to a few seconds.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const Duration _minimumVisible = Duration(milliseconds: 2600);
  static const Duration _hardCeiling = Duration(milliseconds: 8200);

  late final Ticker _ticker;
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  final Stopwatch _clock = Stopwatch();

  /// What the bar currently shows.
  double _shown = 0;

  /// Where the bar is allowed to travel to right now.
  double _target = 0.05;

  Duration _lastTick = Duration.zero;
  Timer? _ceiling;
  bool _navigated = false;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _clock.start();
    _ticker = createTicker(_onTick)..start();
    _ceiling = Timer(_hardCeiling, () {
      // Whatever happened, the user gets into the app.
      if (mounted) setState(() => _target = 1.0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _ceiling?.cancel();
    _ticker.dispose();
    _dots.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double dt =
        ((elapsed - _lastTick).inMicroseconds / 1000000).clamp(0.0, 0.05);
    _lastTick = elapsed;
    if (_shown >= _target) return;

    // Catch-up easing: the further behind the bar is, the faster it moves.
    final double gap = _target - _shown;
    final double speed = 0.28 + gap * 2.6;
    final double next = math.min(_target, _shown + dt * speed);

    if ((next * 100).floor() != (_shown * 100).floor() || next >= 1.0) {
      setState(() => _shown = next);
    } else {
      _shown = next;
    }

    if (_shown >= 1.0) _finish();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    Future<void> stage(double to, Future<void> Function() work) async {
      try {
        await work();
      } catch (_) {
        // A failed warm-up must never block the launch.
      }
      if (mounted) setState(() => _target = math.max(_target, to));
    }

    await stage(0.18, () async {
      await precacheImage(const AssetImage(AppAssets.splashPortrait), context);
      if (!mounted) return;
      await precacheImage(const AssetImage(AppAssets.splashLandscape), context);
    });

    await stage(0.44, () async {
      for (final String orb in <String>[
        AppAssets.orbGreen,
        AppAssets.orbOrange,
        AppAssets.orbPurple,
        AppAssets.orbRed,
        AppAssets.orbDormant,
        AppAssets.orbBroken,
      ]) {
        if (!mounted) return;
        await precacheImage(AssetImage(orb), context);
      }
    });

    await stage(0.72, () async {
      for (final String bg in <String>[
        AppAssets.bgMorning,
        AppAssets.bgAfternoon,
        AppAssets.bgEvening,
        AppAssets.stoneTexture,
        AppAssets.logoMark,
      ]) {
        if (!mounted) return;
        await precacheImage(AssetImage(bg), context);
      }
    });

    await stage(0.92, () async {
      // Let the first real frames of the app compile before we hand over.
      await Future<void>.delayed(const Duration(milliseconds: 180));
    });

    final Duration remaining = _minimumVisible - _clock.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (mounted) setState(() => _target = 1.0);
  }

  Future<void> _finish() async {
    if (_navigated) return;
    _navigated = true;
    _ceiling?.cancel();
    _ticker.stop();

    // Hold the full bar for a beat so 100% is actually readable.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    if (!mounted) return;

    final bool onboarded =
        context.read<SettingsController>().value.onboardingComplete;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 620),
        pageBuilder: (_, _, _) =>
            onboarded ? const HomeShell() : const OnboardingScreen(),
        transitionsBuilder:
            (_, Animation<double> animation, _, Widget child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int percent =
        _shown >= 1.0 ? 100 : (_shown * 100).clamp(0, 99).floor();

    return Scaffold(
      backgroundColor: AppPalette.voidBlack,
      body: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final bool landscape = orientation == Orientation.landscape;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                landscape
                    ? AppAssets.splashLandscape
                    : AppAssets.splashPortrait,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
              // Keeps the readout legible over the brightest part of the art.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Color(0x22000000),
                      Color(0x99000000),
                    ],
                    stops: <double>[0.45, 0.72, 1.0],
                  ),
                ),
              ),
              SafeArea(
                child: landscape
                    ? _LandscapeReadout(percent: percent, value: _shown, dots: _dots)
                    : _PortraitReadout(percent: percent, value: _shown, dots: _dots),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PortraitReadout extends StatelessWidget {
  const _PortraitReadout({
    required this.percent,
    required this.value,
    required this.dots,
  });

  final int percent;
  final double value;
  final AnimationController dots;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 62),
        child: SizedBox(
          width: math.min(width * 0.74, 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _LoadingWord(controller: dots, fontSize: 13, spacing: 4.2),
              const SizedBox(height: 16),
              _ProgressBar(value: value, height: 7),
              const SizedBox(height: 14),
              _PercentText(percent: percent, fontSize: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandscapeReadout extends StatelessWidget {
  const _LandscapeReadout({
    required this.percent,
    required this.value,
    required this.dots,
  });

  final int percent;
  final double value;
  final AnimationController dots;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: SizedBox(
          width: math.min(width * 0.34, 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _LoadingWord(controller: dots, fontSize: 11, spacing: 3.4),
              const SizedBox(height: 10),
              _ProgressBar(value: value, height: 5),
              const SizedBox(height: 8),
              _PercentText(percent: percent, fontSize: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingWord extends StatelessWidget {
  const _LoadingWord({
    required this.controller,
    required this.fontSize,
    required this.spacing,
  });

  final AnimationController controller;
  final double fontSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final int count = (controller.value * 4).floor() % 4;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              'LOADING',
              style: TextStyle(
                fontFamily: AppType.body,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: spacing,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            SizedBox(
              width: fontSize * 1.5,
              child: Text(
                '.' * count,
                style: TextStyle(
                  fontFamily: AppType.body,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: spacing * 0.5,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PercentText extends StatelessWidget {
  const _PercentText({required this.percent, required this.fontSize});

  final int percent;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$percent%',
      style: AppType.numeric(fontSize, color: Colors.white)
          .copyWith(letterSpacing: 0.4),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.height});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double filled = constraints.maxWidth * clamped;
          return Stack(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 0.6,
                  ),
                ),
              ),
              if (filled > 0)
                Container(
                  width: filled,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height),
                    gradient: const LinearGradient(
                      colors: <Color>[
                        AppPalette.auroraBlue,
                        AppPalette.auroraViolet,
                        AppPalette.auroraMagenta,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppPalette.auroraViolet.withValues(alpha: 0.55),
                        blurRadius: height * 2.6,
                        spreadRadius: 0.2,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
