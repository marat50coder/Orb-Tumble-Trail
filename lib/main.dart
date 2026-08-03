import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'data/services/storage_service.dart';
import 'trailway/config/orb_trail_config.dart';
import 'trailway/infra/drift_agent.dart';
import 'trailway/infra/orbit_attribution.dart';
import 'trailway/infra/pulse_hub.dart';
import 'trailway/infra/relay_exchange.dart';
import 'trailway/infra/signal_probe.dart';
import 'trailway/infra/trail_store.dart';
import 'trailway/trail_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The loading screen supports both orientations; the game locks to portrait
  // once the trail is on screen.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );

  // ── White part (the game) ─────────────────────────────────────────────
  final StorageService storage = await StorageService.open();
  // Local habit reminders work fully offline; init before any habit
  // controller reschedules against it.
  await NotificationService.instance.init();

  // ── Gray flow (trailway) ──────────────────────────────────────────────
  final TrailStore store = TrailStore();
  final DriftAgent agent = DriftAgent();
  await Future.wait<void>(<Future<void>>[
    store.initialize(),
    agent.prepare(),
  ]);

  assert(() {
    debugPrint(
      '[OTT.BOOT] gate=${OrbTrailConfig.grayCredentialsReady} '
      'endpoint=${OrbTrailConfig.endpoint} '
      'afKeyLen=${OrbTrailConfig.appsFlyerKey.length} '
      'fbNumber=${OrbTrailConfig.firebaseProjectNumber} '
      'store=${OrbTrailConfig.storeToken}',
    );
    return true;
  }());

  var pushServicesReady = false;
  if (OrbTrailConfig.grayCredentialsReady) {
    try {
      await Firebase.initializeApp();
      pushServicesReady = true;
      assert(() {
        debugPrint('[OTT.BOOT] Firebase.initializeApp OK');
        return true;
      }());
    } catch (error) {
      assert(() {
        debugPrint('[OTT.BOOT] Firebase.initializeApp failed: $error');
        return true;
      }());
    }
    if (pushServicesReady) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (error) {
        // App Check must never block FCM / gray routing.
        assert(() {
          debugPrint('[OTT.BOOT] AppCheck skipped: $error');
          return true;
        }());
      }
    }
  }

  final SignalProbe probe = SignalProbe();
  // Attribution + config POST must run even if Firebase failed to init; only
  // push/FCM needs pushServicesReady.
  final PulseHub pulse = PulseHub(store, enabled: pushServicesReady);
  final OrbitAttribution attribution = OrbitAttribution(agent);
  final TrailRouter router = TrailRouter(
    store: store,
    probe: probe,
    attribution: attribution,
    exchange: RelayExchange(agent, store),
    pulse: pulse,
    agent: agent,
    runtimeEnabled: OrbTrailConfig.grayCredentialsReady,
  );

  assert(() {
    debugPrint(
      '[OTT.BOOT] runApp routerEnabled=${router.enabled} '
      'pushServicesReady=$pushServicesReady',
    );
    return true;
  }());

  runApp(OrbTumbleTrailApp(storage: storage, router: router));
}
