import 'dart:async';
import 'dart:io';

import 'config/orb_trail_config.dart';
import 'core/trail_models.dart';
import 'infra/cold_tap_reader.dart';
import 'infra/drift_agent.dart';
import 'infra/orbit_attribution.dart';
import 'infra/pulse_hub.dart';
import 'infra/relay_exchange.dart';
import 'infra/signal_probe.dart';
import 'infra/trail_store.dart';

class TrailRouter {
  TrailRouter({
    required this.store,
    required this.probe,
    required this.attribution,
    required this.exchange,
    required this.pulse,
    required this.agent,
    required this.runtimeEnabled,
  });

  final TrailStore store;
  final SignalProbe probe;
  final OrbitAttribution attribution;
  final RelayExchange exchange;
  final PulseHub pulse;
  final DriftAgent agent;
  final bool runtimeEnabled;

  bool get enabled => runtimeEnabled && OrbTrailConfig.grayCredentialsReady;

  Future<TrailDestination>? _decideFuture;

  /// De-duplicates only *concurrent* calls (the boot screen may build twice at
  /// startup). The cache clears once the pipeline finishes, so a later Retry
  /// from the offline screen re-runs the whole pipeline instead of replaying
  /// a cached OfflineTrail forever.
  Future<TrailDestination> decide({
    required void Function(double value) onProgress,
  }) =>
      _decideFuture ??=
          _decide(onProgress: onProgress).whenComplete(() => _decideFuture = null);

  Future<TrailDestination> _decide({
    required void Function(double value) onProgress,
  }) async {
    if (!enabled) {
      assert(() {
        // ignore: avoid_print
        print(
          '[OTT.TRAIL] gate disabled '
          'runtime=$runtimeEnabled creds=${OrbTrailConfig.grayCredentialsReady}',
        );
        return true;
      }());
      onProgress(1);
      return const NativeTrail();
    }

    assert(() {
      // ignore: avoid_print
      print('[OTT.TRAIL] decide start route=${store.route}');
      return true;
    }());

    pulse.onTokenChanged = _refreshForToken;
    final coldRoute = await ColdTapReader.consume();
    if (coldRoute != null) {
      await store.saveRoute(TrailRoute.portal);
      await store.consumePushUrl();
      unawaited(_backgroundDispatch());
      onProgress(1);
      return PortalTrail(coldRoute, coldLaunch: true);
    }

    onProgress(0.12);
    return switch (store.route) {
      TrailRoute.undecided => _firstDecision(onProgress),
      TrailRoute.portal => _returningPortal(onProgress),
      TrailRoute.native => _returningNative(onProgress),
    };
  }

  Future<TrailDestination> _firstDecision(
    void Function(double) progress,
  ) async {
    if (!await probe.hasInterface()) {
      return const OfflineTrail(returnToNative: false);
    }
    progress(0.28);
    try {
      await pulse.boot();
    } catch (_) {}
    if (!await probe.canReachNetwork()) {
      return const OfflineTrail(returnToNative: false);
    }
    progress(0.48);
    await attribution.awaitSignals();
    progress(0.72);
    final reply = await _requestConfig();
    progress(1);
    assert(() {
      // ignore: avoid_print
      print('[OTT.TRAIL] first: config hasDest=${reply.hasDestination}');
      return true;
    }());
    if (reply.hasDestination) {
      await store.saveRoute(TrailRoute.portal);
      return PortalTrail(reply.url!);
    }
    await store.saveRoute(TrailRoute.native);
    return const NativeTrail();
  }

  Future<TrailDestination> _returningPortal(
    void Function(double) progress,
  ) async {
    if (!await probe.hasInterface()) {
      return const OfflineTrail(returnToNative: false);
    }
    final pending = await store.consumePushUrl();
    if (pending != null && pending.isNotEmpty) {
      progress(1);
      return PortalTrail(pending);
    }
    final cached = await store.savedUrl();
    if (cached != null && !store.cachedUrlExpired) {
      progress(1);
      return PortalTrail(cached);
    }

    await Future.wait<void>(<Future<void>>[
      pulse.boot(),
      attribution.start(),
    ]);
    if (!await probe.canReachNetwork()) {
      return const OfflineTrail(returnToNative: false);
    }
    progress(0.62);
    await attribution.awaitSignals(installTimeout: const Duration(seconds: 5));
    final reply = await _requestConfig();
    progress(1);
    if (reply.hasDestination) return PortalTrail(reply.url!);
    if (cached != null) return PortalTrail(cached);
    return const OfflineTrail(returnToNative: false);
  }

  Future<TrailDestination> _returningNative(
    void Function(double) progress,
  ) async {
    if (!await probe.hasInterface()) {
      progress(1);
      return const NativeTrail();
    }
    await Future.wait<void>(<Future<void>>[
      pulse.boot(),
      attribution.start(),
    ]);
    if (!await probe.canReachNetwork()) {
      progress(1);
      return const NativeTrail();
    }
    progress(0.55);
    await attribution.awaitSignals();
    final reply = await _requestConfig();
    progress(1);
    if (!reply.hasDestination) return const NativeTrail();
    await store.saveRoute(TrailRoute.portal);
    return PortalTrail(reply.url!);
  }

  Future<RelayReply> _requestConfig({String? token}) async {
    final body = await attribution.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: token ?? pulse.token,
    );
    return exchange.request(body);
  }

  Future<void> _backgroundDispatch() async {
    try {
      await Future.wait<void>(<Future<void>>[
        pulse.boot(),
        attribution.awaitSignals(),
      ]);
      await _requestConfig();
    } catch (_) {}
  }

  Future<void> _refreshForToken(String token) async {
    try {
      await _requestConfig(token: token);
    } catch (_) {}
  }
}
