import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum TrailEnvironment { auto, morning, afternoon, evening }

enum AccentPreset { indigo, azure, violet, magenta, mint }

extension AccentPresetX on AccentPreset {
  Color get color => switch (this) {
        AccentPreset.indigo => AppPalette.auroraIndigo,
        AccentPreset.azure => AppPalette.auroraBlue,
        AccentPreset.violet => AppPalette.auroraViolet,
        AccentPreset.magenta => AppPalette.auroraMagenta,
        AccentPreset.mint => AppPalette.success,
      };

  String get label => switch (this) {
        AccentPreset.indigo => 'Indigo',
        AccentPreset.azure => 'Azure',
        AccentPreset.violet => 'Violet',
        AccentPreset.magenta => 'Magenta',
        AccentPreset.mint => 'Mint',
      };
}

@immutable
class AppSettings {
  const AppSettings({
    this.accent = AccentPreset.violet,
    this.environment = TrailEnvironment.auto,
    this.haptics = true,
    this.reduceMotion = false,
    this.showParticles = true,
    this.weekStartsMonday = true,
    this.confirmDeletion = true,
    this.onboardingComplete = false,
    this.compactTrail = false,
  });

  final AccentPreset accent;
  final TrailEnvironment environment;
  final bool haptics;
  final bool reduceMotion;
  final bool showParticles;
  final bool weekStartsMonday;
  final bool confirmDeletion;
  final bool onboardingComplete;

  /// Renders the trail as a dense column instead of a wide serpentine.
  final bool compactTrail;

  AppSettings copyWith({
    AccentPreset? accent,
    TrailEnvironment? environment,
    bool? haptics,
    bool? reduceMotion,
    bool? showParticles,
    bool? weekStartsMonday,
    bool? confirmDeletion,
    bool? onboardingComplete,
    bool? compactTrail,
  }) {
    return AppSettings(
      accent: accent ?? this.accent,
      environment: environment ?? this.environment,
      haptics: haptics ?? this.haptics,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      showParticles: showParticles ?? this.showParticles,
      weekStartsMonday: weekStartsMonday ?? this.weekStartsMonday,
      confirmDeletion: confirmDeletion ?? this.confirmDeletion,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      compactTrail: compactTrail ?? this.compactTrail,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'accent': accent.name,
        'environment': environment.name,
        'haptics': haptics,
        'reduceMotion': reduceMotion,
        'showParticles': showParticles,
        'weekStartsMonday': weekStartsMonday,
        'confirmDeletion': confirmDeletion,
        'onboardingComplete': onboardingComplete,
        'compactTrail': compactTrail,
      };

  static AppSettings fromJson(Map<String, dynamic> json) => AppSettings(
        accent: AccentPreset.values.firstWhere(
          (AccentPreset a) => a.name == json['accent'],
          orElse: () => AccentPreset.violet,
        ),
        environment: TrailEnvironment.values.firstWhere(
          (TrailEnvironment e) => e.name == json['environment'],
          orElse: () => TrailEnvironment.auto,
        ),
        haptics: json['haptics'] as bool? ?? true,
        reduceMotion: json['reduceMotion'] as bool? ?? false,
        showParticles: json['showParticles'] as bool? ?? true,
        weekStartsMonday: json['weekStartsMonday'] as bool? ?? true,
        confirmDeletion: json['confirmDeletion'] as bool? ?? true,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        compactTrail: json['compactTrail'] as bool? ?? false,
      );
}
