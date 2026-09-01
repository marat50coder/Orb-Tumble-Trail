import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../features/splash/loading_screen.dart';
import '../core/trail_models.dart';
import '../trail_router.dart';
import 'no_signal_screen.dart';
import 'portal_view.dart';
import 'push_prompt_screen.dart';

/// App entry + gray/native routing point. Shows the game's splash art while
/// [TrailRouter.decide] runs the attribution → config pipeline, then routes:
/// organic / gate-disabled → the native game (its own [LoadingScreen]),
/// non-organic → the WebView portal, offline → the no-signal screen.
///
/// When [router] is null (gate fully disabled at build time) it routes
/// straight to the native game.
class GrayBootScreen extends StatefulWidget {
  const GrayBootScreen({super.key, this.router});

  final TrailRouter? router;

  @override
  State<GrayBootScreen> createState() => _GrayBootScreenState();
}

class _GrayBootScreenState extends State<GrayBootScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  bool _navigating = false;
  TrailDestination? _destination;
  late final DateTime _startTime;
  late final Ticker _ticker;
  Timer? _hardDeadline;

  /// What the bar currently shows (0..1).
  double _shown = 0;

  /// Where the bar is allowed to travel to right now.
  double _target = 0.04;

  Duration _lastTick = Duration.zero;

  static const Duration _minSplash = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _ticker = createTicker(_onTick)..start();
    // Splash supports both orientations; each destination re-asserts its own.
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Give the full trail router pipeline time to finish before the fallback
    // to the native game kicks in. Worst-case internal timeouts sum to ~26s
    // (probe 3s + attribution 8s + config 15s), but in practice AppsFlyer
    // conversion arrives in 1–3s. A 20s ceiling still bounds a truly hung
    // network while letting a slow-but-legitimate non-organic decision land.
    _hardDeadline = Timer(const Duration(seconds: 20), () {
      if (mounted && !_navigating) {
        assert(() {
          // ignore: avoid_print
          print(
            '[OTT.BOOT] hard-deadline hit; router.decide did not finish → native',
          );
          return true;
        }());
        _liftTarget(1);
        _destination ??= const NativeTrail();
        _maybeNavigate();
      }
    });
  }

  @override
  void dispose() {
    _hardDeadline?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double dt =
        ((elapsed - _lastTick).inMicroseconds / 1000000).clamp(0.0, 0.05);
    _lastTick = elapsed;

    // Slow time-based floor so the bar never sits still while the router waits.
    final double elapsedSec =
        DateTime.now().difference(_startTime).inMilliseconds / 1000;
    final double timeFloor = (elapsedSec / 18).clamp(0.0, 0.92);
    if (timeFloor > _target) _target = timeFloor;

    if (_shown >= _target) return;

    final double gap = _target - _shown;
    final double speed = 0.32 + gap * 2.4;
    final double next = math.min(_target, _shown + dt * speed);

    if ((next * 100).floor() != (_shown * 100).floor() || next >= 1.0) {
      setState(() => _shown = next);
    } else {
      _shown = next;
    }
  }

  void _liftTarget(double value) {
    final double next = value.clamp(0.0, 1.0);
    if (next <= _target) return;
    if (mounted) {
      setState(() => _target = next);
    } else {
      _target = next;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final router = widget.router;
    if (router == null) {
      _destination = const NativeTrail();
      _liftTarget(1);
      _maybeNavigate();
      return;
    }
    try {
      _destination = await router.decide(onProgress: _liftTarget);
    } catch (error) {
      assert(() {
        // ignore: avoid_print
        print('[OTT.BOOT] router.decide threw: $error → native');
        return true;
      }());
      _destination = const NativeTrail();
    }
    _liftTarget(1);
    assert(() {
      // ignore: avoid_print
      print('[OTT.BOOT] destination=${_destination.runtimeType}');
      return true;
    }());
    _maybeNavigate();
  }

  Future<void> _maybeNavigate() async {
    if (_navigating || _destination == null) return;
    final elapsed = DateTime.now().difference(_startTime);
    if (elapsed < _minSplash) {
      await Future<void>.delayed(_minSplash - elapsed);
    }
    // Hold until the bar actually reaches 100 so the user sees the fill finish.
    final DateTime barDeadline = DateTime.now().add(const Duration(seconds: 2));
    while (mounted && _shown < 0.995 && DateTime.now().isBefore(barDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    if (!mounted || _navigating) return;
    _navigating = true;
    _hardDeadline?.cancel();
    _ticker.stop();
    await _open(_destination!);
  }

  Future<void> _open(TrailDestination destination) async {
    final router = widget.router;

    // Organic / gate disabled → hand over to the native game's own splash,
    // which precaches assets and continues to onboarding / home.
    if (destination is NativeTrail || router == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoadingScreen()),
      );
      return;
    }

    if (destination is OfflineTrail) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => NoSignalScreen(
            probe: router.probe,
            retryBuilder: (_) => GrayBootScreen(router: router),
          ),
        ),
      );
      return;
    }

    if (destination is PortalTrail) {
      Widget portalBuilder(BuildContext _) => PortalView(
            url: destination.url,
            coldLaunch: destination.coldLaunch,
            store: router.store,
            probe: router.probe,
            pulse: router.pulse,
            agent: router.agent,
          );

      final bool offerInvite = router.store.shouldShowPushInvite &&
          await router.pulse.canOfferPermission();
      if (!mounted) return;
      if (offerInvite) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PushPromptScreen(
              store: router.store,
              pulse: router.pulse,
              nextBuilder: portalBuilder,
            ),
          ),
        );
      } else {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute<void>(builder: portalBuilder));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final asset = isLandscape ? 'assets/Frame 37.webp' : 'assets/Frame 36.webp';

    return Scaffold(
      backgroundColor: const Color(0xFF05060B),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xFF05060B)),
          ),
          Align(
            alignment: const Alignment(0, 0.86),
            child: SafeArea(
              child: _BootMeter(value: _shown),
            ),
          ),
        ],
      ),
    );
  }
}

class _BootMeter extends StatelessWidget {
  const _BootMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double width = MediaQuery.sizeOf(context).width;
    final double barWidth = landscape
        ? math.min(width * 0.34, 260)
        : math.min(width * 0.74, 320);
    final int percent = value >= 1.0 ? 100 : (value * 100).clamp(0, 99).floor();
    final double height = landscape ? 5.0 : 7.0;

    return Padding(
      padding: EdgeInsets.only(bottom: landscape ? 18 : 8),
      child: SizedBox(
        width: barWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'LOADING',
              style: TextStyle(
                fontFamily: AppType.body,
                fontSize: landscape ? 11 : 13,
                fontWeight: FontWeight.w500,
                letterSpacing: landscape ? 3.4 : 4.2,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            SizedBox(height: landscape ? 10 : 16),
            SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double filled =
                      constraints.maxWidth * value.clamp(0.0, 1.0);
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
                                color: AppPalette.auroraViolet
                                    .withValues(alpha: 0.55),
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
            ),
            SizedBox(height: landscape ? 8 : 14),
            Text(
              '$percent%',
              style: AppType.numeric(landscape ? 15 : 22, color: Colors.white)
                  .copyWith(letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
