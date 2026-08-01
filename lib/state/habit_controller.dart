import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/day_key.dart';
import '../data/models/achievement.dart';
import '../data/models/habit.dart';
import '../data/models/habit_preset.dart';
import '../data/models/orb_stats.dart';
import '../data/models/player_progress.dart';
import '../data/services/notification_service.dart';
import '../data/services/storage_service.dart';

class HabitController extends ChangeNotifier {
  HabitController(this._storage) {
    _habits = _storage.readHabits();
    _seenAchievements = _storage.readSeenAchievements();
    _focusMinutes = _storage.readFocusMinutes();
    _journal = _storage.readJournal();
    _claimedQuests = _storage.readClaimedQuests();
    _claimedQuestXp = _storage.readClaimedQuestXp();
    _shieldsUsed = _storage.readShieldsUsed();
    _protectedDays = _storage.readProtectedDays();
    _recompute();
    // Make sure the OS reminder schedule matches the stored habits on launch.
    NotificationService.instance.rescheduleAll(_habits);
  }

  final StorageService _storage;
  static const Uuid _uuid = Uuid();

  List<Habit> _habits = <Habit>[];
  Set<String> _seenAchievements = <String>{};
  int _focusMinutes = 0;
  Map<String, String> _journal = <String, String>{};
  TrailSummary _summary = TrailSummary.empty;

  // Progression state.
  Set<String> _claimedQuests = <String>{};
  int _claimedQuestXp = 0;
  int _shieldsUsed = 0;
  Map<String, Set<String>> _protectedDays = <String, Set<String>>{};

  /// Achievements unlocked but not yet celebrated on screen.
  final List<Achievement> _pendingCelebrations = <Achievement>[];

  List<Habit> get habits =>
      _habits.where((Habit h) => !h.archived).toList(growable: false);

  List<Habit> get archivedHabits =>
      _habits.where((Habit h) => h.archived).toList(growable: false);

  List<Habit> get allHabits => List<Habit>.unmodifiable(_habits);

  TrailSummary get summary => _summary;

  int get focusMinutes => _focusMinutes;

  Map<String, String> get journal => Map<String, String>.unmodifiable(_journal);

  bool get hasHabits => habits.isNotEmpty;

  List<Achievement> get unlockedAchievements => AchievementCatalog.all
      .where((Achievement a) => a.isUnlocked(_summary))
      .toList(growable: false);

  List<Achievement> get lockedAchievements => AchievementCatalog.all
      .where((Achievement a) => !a.isUnlocked(_summary))
      .toList(growable: false);

  Achievement? takeCelebration() =>
      _pendingCelebrations.isEmpty ? null : _pendingCelebrations.removeAt(0);

  Habit? byId(String id) {
    for (final Habit h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  OrbStats statsFor(Habit habit) => OrbStats.compute(
        habit,
        protectedDays: _protectedDays[habit.id] ?? const <String>{},
      );

  // ── Progression ───────────────────────────────────────────────────────────

  PlayerProgress get progress => PlayerProgress.derive(
        totalCompletions: _summary.totalCompletions,
        perfectDays: _summary.perfectDays,
        achievementsUnlocked: unlockedAchievements.length,
        claimedQuestXp: _claimedQuestXp,
        shieldsUsed: _shieldsUsed,
      );

  int get shieldsAvailable => progress.shieldsAvailable;

  Map<String, Set<String>> get protectedDays =>
      Map<String, Set<String>>.unmodifiable(_protectedDays);

  int protectedCountFor(String habitId) =>
      _protectedDays[habitId]?.length ?? 0;

  /// Today's three quests paired with their live progress.
  List<QuestProgress> get todayQuests {
    final DateTime today = DayKey.today();
    final int scheduledToday =
        habits.where((Habit h) => h.isScheduledOn(today)).length;
    final List<DailyQuest> quests = DailyQuest.forDay(
      DayKey.of(today),
      scheduledToday: scheduledToday == 0 ? 3 : scheduledToday,
    );
    return quests
        .map((DailyQuest q) => QuestProgress(
              quest: q,
              current: _questProgress(q, today),
              claimed: _claimedQuests.contains(q.id),
            ))
        .toList(growable: false);
  }

  int _questProgress(DailyQuest quest, DateTime day) {
    switch (quest.kind) {
      case QuestKind.rolls:
        return habits.fold<int>(0, (int sum, Habit h) => sum + h.countOn(day));
      case QuestKind.completions:
        return habits.where((Habit h) => h.isCompleteOn(day)).length;
      case QuestKind.perfect:
        final List<Habit> due =
            habits.where((Habit h) => h.isScheduledOn(day)).toList();
        return due.isNotEmpty && due.every((Habit h) => h.isCompleteOn(day))
            ? 1
            : 0;
      case QuestKind.variety:
        return habits
            .where((Habit h) => h.isCompleteOn(day))
            .map((Habit h) => h.skin)
            .toSet()
            .length;
      case QuestKind.focus:
        return _focusMinutes; // cumulative fallback; still rewards focus use
    }
  }

  Future<bool> claimQuest(String questId) async {
    final List<QuestProgress> quests = todayQuests;
    final QuestProgress? match = quests
        .where((QuestProgress q) => q.quest.id == questId)
        .cast<QuestProgress?>()
        .firstWhere((QuestProgress? q) => q != null, orElse: () => null);
    if (match == null || !match.claimable) return false;
    _claimedQuests = <String>{..._claimedQuests, questId};
    _claimedQuestXp += match.quest.xp;
    await _storage.writeClaimedQuests(_claimedQuests);
    await _storage.writeClaimedQuestXp(_claimedQuestXp);
    _recompute();
    return true;
  }

  /// Spends one shield to freeze the most recent scheduled miss for [habitId],
  /// healing its streak. Returns true when a shield was actually spent.
  Future<bool> useShieldOn(String habitId) async {
    if (shieldsAvailable <= 0) return false;
    final Habit? habit = byId(habitId);
    if (habit == null) return false;

    final DateTime today = DayKey.today();
    final Set<String> already = _protectedDays[habitId] ?? <String>{};
    // Walk backwards to find the newest scheduled, incomplete, unprotected day.
    for (int i = 1; i <= 60; i++) {
      final DateTime day = today.subtract(Duration(days: i));
      if (DayKey.normalize(habit.createdAt).isAfter(day)) break;
      if (!habit.isScheduledOn(day)) continue;
      final String key = DayKey.of(day);
      if (habit.isCompleteOn(day) || already.contains(key)) continue;
      _protectedDays = Map<String, Set<String>>.from(_protectedDays);
      _protectedDays[habitId] = <String>{...already, key};
      _shieldsUsed++;
      await _storage.writeProtectedDays(_protectedDays);
      await _storage.writeShieldsUsed(_shieldsUsed);
      _recompute();
      return true;
    }
    return false;
  }

  /// Habits that are due today and still open, most urgent first.
  List<Habit> get dueToday {
    final DateTime today = DayKey.today();
    final List<Habit> due = habits
        .where((Habit h) => h.isScheduledOn(today) && !h.isCompleteOn(today))
        .toList();
    due.sort((Habit a, Habit b) {
      final int ar = a.reminderMinutes ?? 24 * 60;
      final int br = b.reminderMinutes ?? 24 * 60;
      return ar.compareTo(br);
    });
    return due;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<Habit> create({
    required String title,
    required String iconKey,
    required OrbSkin skin,
    String description = '',
    int dailyTarget = 1,
    String unit = 'time',
    HabitKind kind = HabitKind.build,
    Set<int>? weekdays,
    int? reminderMinutes,
  }) async {
    final Habit habit = Habit(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      skin: skin,
      iconKey: iconKey,
      createdAt: DateTime.now(),
      dailyTarget: math.max(1, dailyTarget),
      unit: unit,
      kind: kind,
      scheduledWeekdays: weekdays ?? const <int>{1, 2, 3, 4, 5, 6, 7},
      reminderMinutes: reminderMinutes,
    );
    _habits = <Habit>[..._habits, habit];
    await _persist();
    await NotificationService.instance.scheduleForHabit(habit);
    return habit;
  }

  /// Update coming from the editor / reminders screen — also (re)schedules the
  /// OS reminder. Kept separate from [update] so a plain progress tap does not
  /// churn the notification schedule.
  Future<void> saveHabit(Habit habit) async {
    await update(habit);
    await NotificationService.instance.scheduleForHabit(habit);
  }

  Future<void> createFromPreset(HabitPreset preset) => create(
        title: preset.title,
        iconKey: preset.iconKey,
        skin: preset.skin,
        description: preset.description,
        dailyTarget: preset.dailyTarget,
        unit: preset.unit,
        kind: preset.kind,
      );

  Future<void> update(Habit habit) async {
    _habits = _habits
        .map((Habit h) => h.id == habit.id ? habit : h)
        .toList(growable: false);
    await _persist();
  }

  Future<void> remove(String id) async {
    final Habit? habit = byId(id);
    _habits = _habits.where((Habit h) => h.id != id).toList(growable: false);
    await _persist();
    if (habit != null) {
      await NotificationService.instance.cancelForHabit(habit);
    }
  }

  Future<void> setArchived(String id, bool archived) async {
    final Habit? habit = byId(id);
    if (habit == null) return;
    final Habit updated = habit.copyWith(archived: archived);
    await update(updated);
    // scheduleForHabit cancels reminders for archived habits automatically.
    await NotificationService.instance.scheduleForHabit(updated);
  }

  /// [newIndex] is already adjusted for the removal of the dragged item.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final List<Habit> active = habits.toList();
    if (oldIndex < 0 || oldIndex >= active.length) return;
    final int target = newIndex;
    final Habit moved = active.removeAt(oldIndex);
    active.insert(target.clamp(0, active.length), moved);
    _habits = <Habit>[...active, ...archivedHabits];
    await _persist();
  }

  /// One tap forward on a habit's day. Returns true when the day just closed.
  Future<bool> roll(String id, {DateTime? on}) async {
    final Habit? habit = byId(id);
    if (habit == null) return false;
    final DateTime day = DayKey.normalize(on ?? DateTime.now());
    final String key = DayKey.of(day);
    final int before = habit.progress[key] ?? 0;
    if (before >= habit.dailyTarget) return false;
    final Map<String, int> next = Map<String, int>.from(habit.progress)
      ..[key] = before + 1;
    await update(habit.copyWith(progress: next));
    return (before + 1) >= habit.dailyTarget;
  }

  Future<void> unroll(String id, {DateTime? on}) async {
    final Habit? habit = byId(id);
    if (habit == null) return;
    final String key = DayKey.of(DayKey.normalize(on ?? DateTime.now()));
    final int before = habit.progress[key] ?? 0;
    if (before <= 0) return;
    final Map<String, int> next = Map<String, int>.from(habit.progress);
    if (before - 1 <= 0) {
      next.remove(key);
    } else {
      next[key] = before - 1;
    }
    await update(habit.copyWith(progress: next));
  }

  Future<void> setDayComplete(String id, DateTime day, bool complete) async {
    final Habit? habit = byId(id);
    if (habit == null) return;
    final String key = DayKey.of(DayKey.normalize(day));
    final Map<String, int> next = Map<String, int>.from(habit.progress);
    if (complete) {
      next[key] = habit.dailyTarget;
    } else {
      next.remove(key);
    }
    await update(habit.copyWith(progress: next));
  }

  Future<void> toggleDay(String id, DateTime day) async {
    final Habit? habit = byId(id);
    if (habit == null) return;
    await setDayComplete(id, day, !habit.isCompleteOn(day));
  }

  /// Completes every habit still open today.
  Future<int> rollAllDueToday() async {
    final List<Habit> due = dueToday;
    for (final Habit h in due) {
      await setDayComplete(h.id, DayKey.today(), true);
    }
    return due.length;
  }

  Future<void> addFocusMinutes(int minutes) async {
    _focusMinutes += minutes;
    await _storage.writeFocusMinutes(_focusMinutes);
    notifyListeners();
  }

  Future<void> saveNote(DateTime day, String text) async {
    final String key = DayKey.of(DayKey.normalize(day));
    _journal = Map<String, String>.from(_journal);
    if (text.trim().isEmpty) {
      _journal.remove(key);
    } else {
      _journal[key] = text.trim();
    }
    await _storage.writeJournal(_journal);
    notifyListeners();
  }

  String? noteFor(DateTime day) => _journal[DayKey.of(DayKey.normalize(day))];

  Future<void> resetProgressOnly() async {
    _habits = _habits
        .map((Habit h) => h.copyWith(progress: <String, int>{}))
        .toList(growable: false);
    _seenAchievements = <String>{};
    _focusMinutes = 0;
    _journal = <String, String>{};
    _resetProgression();
    await _storage.writeSeenAchievements(_seenAchievements);
    await _storage.writeFocusMinutes(0);
    await _storage.writeJournal(_journal);
    await _persistProgression();
    await _persist();
  }

  Future<void> deleteEverything() async {
    _habits = <Habit>[];
    _seenAchievements = <String>{};
    _focusMinutes = 0;
    _journal = <String, String>{};
    _resetProgression();
    await _storage.wipe();
    await _persist();
  }

  void _resetProgression() {
    _claimedQuests = <String>{};
    _claimedQuestXp = 0;
    _shieldsUsed = 0;
    _protectedDays = <String, Set<String>>{};
  }

  Future<void> _persistProgression() async {
    await _storage.writeClaimedQuests(_claimedQuests);
    await _storage.writeClaimedQuestXp(_claimedQuestXp);
    await _storage.writeShieldsUsed(_shieldsUsed);
    await _storage.writeProtectedDays(_protectedDays);
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    await _storage.writeHabits(_habits);
    _recompute();
  }

  void _recompute() {
    _summary = TrailSummary.compute(_habits, protectedDays: _protectedDays);
    final Set<String> unlocked = <String>{
      for (final Achievement a in AchievementCatalog.all)
        if (a.isUnlocked(_summary)) a.id,
    };
    final Set<String> fresh = unlocked.difference(_seenAchievements);
    if (fresh.isNotEmpty) {
      _pendingCelebrations.addAll(
        AchievementCatalog.all.where((Achievement a) => fresh.contains(a.id)),
      );
      _seenAchievements = unlocked;
      _storage.writeSeenAchievements(_seenAchievements);
    }
    notifyListeners();
  }
}
