import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _GrayBootScreenState extends State<GrayBootScreen> {
  bool _started = false;
  bool _navigating = false;
  TrailDestination? _destination;
  late final DateTime _startTime;
  Timer? _hardDeadline;

  static const Duration _minSplash = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
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
        _destination ??= const NativeTrail();
        _maybeNavigate();
      }
    });
  }

  @override
  void dispose() {
    _hardDeadline?.cancel();
    super.dispose();
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
      _maybeNavigate();
      return;
    }
    try {
      _destination = await router.decide(onProgress: (_) {});
    } catch (error) {
      assert(() {
        // ignore: avoid_print
        print('[OTT.BOOT] router.decide threw: $error → native');
        return true;
      }());
      _destination = const NativeTrail();
    }
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
    if (!mounted || _navigating) return;
    _navigating = true;
    _hardDeadline?.cancel();
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
          const Align(
            alignment: Alignment(0, 0.86),
            child: SafeArea(child: _BootPulse()),
          ),
        ],
      ),
    );
  }
}

/// Indeterminate "Loading" pill — no 0-100 bar, so handing over to the game's
/// own progress bar (native path) doesn't look like a reset.
class _BootPulse extends StatefulWidget {
  const _BootPulse();

  @override
  State<_BootPulse> createState() => _BootPulseState();
}

class _BootPulseState extends State<_BootPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final phase = (_ctrl.value * 3).floor() % 3;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Loading',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: i <= phase ? 1.0 : 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
