import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/constants/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_settings.dart';
import 'data/services/storage_service.dart';
import 'features/splash/loading_screen.dart';
import 'state/habit_controller.dart';
import 'state/profile_controller.dart';
import 'state/settings_controller.dart';

class OrbTumbleTrailApp extends StatelessWidget {
  const OrbTumbleTrailApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(storage),
        ),
        ChangeNotifierProvider<HabitController>(
          create: (_) => HabitController(storage),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (_) => ProfileController(storage),
        ),
      ],
      child: Builder(
        builder: (BuildContext context) {
          final AccentPreset accent =
              context.select<SettingsController, AccentPreset>(
            (SettingsController c) => c.value.accent,
          );
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(accent: accent.color),
            themeMode: ThemeMode.dark,
            builder: (BuildContext context, Widget? child) {
              // Keep typography stable regardless of the device font scale.
              final MediaQueryData mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(
                    mq.textScaler.scale(1).clamp(0.9, 1.15),
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const LoadingScreen(),
          );
        },
      ),
    );
  }
}
