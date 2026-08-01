import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'data/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The loading screen supports both orientations; the app itself locks to
  // portrait once the trail is on screen.
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

  final StorageService storage = await StorageService.open();

  // Local reminders work fully offline; init here so the schedule is ready
  // before any habit controller reschedules against it.
  await NotificationService.instance.init();

  runApp(OrbTumbleTrailApp(storage: storage));
}
