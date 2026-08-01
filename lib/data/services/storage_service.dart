import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';

/// Everything the app knows lives on the device — there is no backend and no
/// network dependency for any feature except the two web pages.
class StorageService {
  StorageService(this._prefs);

  static const String _kHabits = 'otf.habits.v1';
  static const String _kSettings = 'otf.settings.v1';
  static const String _kProfile = 'otf.profile.v1';
  static const String _kSeenAchievements = 'otf.achievements.seen.v1';
  static const String _kFocusMinutes = 'otf.focus.minutes.v1';
  static const String _kNotes = 'otf.journal.v1';
  static const String _kClaimedQuests = 'otf.quests.claimed.v1';
  static const String _kClaimedQuestXp = 'otf.quests.xp.v1';
  static const String _kShieldsUsed = 'otf.shields.used.v1';
  static const String _kProtectedDays = 'otf.shields.protected.v1';

  final SharedPreferences _prefs;

  static Future<StorageService> open() async =>
      StorageService(await SharedPreferences.getInstance());

  // ── Habits ────────────────────────────────────────────────────────────────
  List<Habit> readHabits() {
    final String? raw = _prefs.getString(_kHabits);
    if (raw == null || raw.isEmpty) return <Habit>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((dynamic e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Habit>[];
    }
  }

  Future<void> writeHabits(List<Habit> habits) => _prefs.setString(
        _kHabits,
        jsonEncode(habits.map((Habit h) => h.toJson()).toList()),
      );

  // ── Settings ──────────────────────────────────────────────────────────────
  AppSettings readSettings() {
    final String? raw = _prefs.getString(_kSettings);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> writeSettings(AppSettings settings) =>
      _prefs.setString(_kSettings, jsonEncode(settings.toJson()));

  // ── Profile ───────────────────────────────────────────────────────────────
  UserProfile readProfile() {
    final String? raw = _prefs.getString(_kProfile);
    if (raw == null || raw.isEmpty) {
      return UserProfile(joinedAt: DateTime.now());
    }
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile(joinedAt: DateTime.now());
    }
  }

  Future<void> writeProfile(UserProfile profile) =>
      _prefs.setString(_kProfile, jsonEncode(profile.toJson()));

  // ── Achievements already celebrated ───────────────────────────────────────
  Set<String> readSeenAchievements() =>
      _prefs.getStringList(_kSeenAchievements)?.toSet() ?? <String>{};

  Future<void> writeSeenAchievements(Set<String> ids) =>
      _prefs.setStringList(_kSeenAchievements, ids.toList());

  // ── Focus sessions ────────────────────────────────────────────────────────
  int readFocusMinutes() => _prefs.getInt(_kFocusMinutes) ?? 0;

  Future<void> writeFocusMinutes(int minutes) =>
      _prefs.setInt(_kFocusMinutes, minutes);

  // ── Journal ───────────────────────────────────────────────────────────────
  Map<String, String> readJournal() {
    final String? raw = _prefs.getString(_kNotes);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((String k, dynamic v) => MapEntry<String, String>(k, v as String));
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> writeJournal(Map<String, String> notes) =>
      _prefs.setString(_kNotes, jsonEncode(notes));

  // ── Progression: quests, XP, shields ──────────────────────────────────────
  Set<String> readClaimedQuests() =>
      _prefs.getStringList(_kClaimedQuests)?.toSet() ?? <String>{};

  Future<void> writeClaimedQuests(Set<String> ids) =>
      _prefs.setStringList(_kClaimedQuests, ids.toList());

  int readClaimedQuestXp() => _prefs.getInt(_kClaimedQuestXp) ?? 0;

  Future<void> writeClaimedQuestXp(int xp) =>
      _prefs.setInt(_kClaimedQuestXp, xp);

  int readShieldsUsed() => _prefs.getInt(_kShieldsUsed) ?? 0;

  Future<void> writeShieldsUsed(int count) =>
      _prefs.setInt(_kShieldsUsed, count);

  /// habitId → set of protected dayKeys (misses absorbed by a shield).
  Map<String, Set<String>> readProtectedDays() {
    final String? raw = _prefs.getString(_kProtectedDays);
    if (raw == null || raw.isEmpty) return <String, Set<String>>{};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (String k, dynamic v) => MapEntry<String, Set<String>>(
          k,
          <String>{...(v as List<dynamic>).map((dynamic e) => e as String)},
        ),
      );
    } catch (_) {
      return <String, Set<String>>{};
    }
  }

  Future<void> writeProtectedDays(Map<String, Set<String>> days) =>
      _prefs.setString(
        _kProtectedDays,
        jsonEncode(days.map((String k, Set<String> v) =>
            MapEntry<String, List<String>>(k, v.toList()))),
      );

  Future<void> wipe() async {
    await _prefs.remove(_kHabits);
    await _prefs.remove(_kSeenAchievements);
    await _prefs.remove(_kFocusMinutes);
    await _prefs.remove(_kNotes);
    await _prefs.remove(_kClaimedQuests);
    await _prefs.remove(_kClaimedQuestXp);
    await _prefs.remove(_kShieldsUsed);
    await _prefs.remove(_kProtectedDays);
  }

  Future<void> wipeEverything() async {
    await wipe();
    await _prefs.remove(_kSettings);
    await _prefs.remove(_kProfile);
  }
}
