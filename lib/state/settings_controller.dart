import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/models/app_settings.dart';
import '../data/services/storage_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._storage) : _settings = _storage.readSettings();

  final StorageService _storage;
  AppSettings _settings;

  AppSettings get value => _settings;

  Future<void> _save(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _storage.writeSettings(next);
  }

  Future<void> setAccent(AccentPreset accent) =>
      _save(_settings.copyWith(accent: accent));

  Future<void> setEnvironment(TrailEnvironment env) =>
      _save(_settings.copyWith(environment: env));

  Future<void> setHaptics(bool value) =>
      _save(_settings.copyWith(haptics: value));

  Future<void> setReduceMotion(bool value) =>
      _save(_settings.copyWith(reduceMotion: value));

  Future<void> setShowParticles(bool value) =>
      _save(_settings.copyWith(showParticles: value));

  Future<void> setWeekStartsMonday(bool value) =>
      _save(_settings.copyWith(weekStartsMonday: value));

  Future<void> setConfirmDeletion(bool value) =>
      _save(_settings.copyWith(confirmDeletion: value));

  Future<void> setCompactTrail(bool value) =>
      _save(_settings.copyWith(compactTrail: value));

  Future<void> completeOnboarding() =>
      _save(_settings.copyWith(onboardingComplete: true));

  Future<void> resetToDefaults() => _save(
        const AppSettings().copyWith(
          onboardingComplete: _settings.onboardingComplete,
        ),
      );

  void tap() {
    if (_settings.haptics) HapticFeedback.selectionClick();
  }

  void impact() {
    if (_settings.haptics) HapticFeedback.mediumImpact();
  }

  void success() {
    if (_settings.haptics) HapticFeedback.heavyImpact();
  }
}
