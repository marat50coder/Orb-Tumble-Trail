import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/utils/day_key.dart';
import 'habit.dart';

/// Evolution stages an orb passes through as its best streak grows.
enum OrbTier { spark, ember, blaze, star, nova }

extension OrbTierX on OrbTier {
  String get label => switch (this) {
        OrbTier.spark => 'Spark',
        OrbTier.ember => 'Ember',
        OrbTier.blaze => 'Blaze',
        OrbTier.star => 'Star',
        OrbTier.nova => 'Nova',
      };

  /// Best-streak thresholds where each tier begins.
  static const List<int> thresholds = <int>[0, 3, 7, 14, 30];

  static OrbTier fromStreak(int longestStreak) {
    if (longestStreak >= 30) return OrbTier.nova;
    if (longestStreak >= 14) return OrbTier.star;
    if (longestStreak >= 7) return OrbTier.blaze;
    if (longestStreak >= 3) return OrbTier.ember;
    return OrbTier.spark;
  }

  static double progress(int longestStreak) {
    final OrbTier t = fromStreak(longestStreak);
    if (t == OrbTier.nova) return 1;
    final int lo = thresholds[t.index];
    final int hi = thresholds[t.index + 1];
    return ((longestStreak - lo) / (hi - lo)).clamp(0.0, 1.0).toDouble();
  }
}

/// Derived, never-persisted state of a single orb on the trail.
///
/// This is the "physics" of the product: completing a scheduled day pushes the
/// orb forward, and every multiplier is earned through consistency. Missing a
/// scheduled day makes the orb tumble backwards, and three misses in a row
/// shatter it until the user rolls it again.
@immutable
class OrbStats {
  const OrbStats({
    required this.habit,
    required this.distance,
    required this.currentStreak,
    required this.longestStreak,
    required this.missStreak,
    required this.completionRate,
    required this.scheduledDays,
    required this.completedDays,
    required this.momentum,
    required this.state,
    required this.last30,
  });

  final Habit habit;

  /// Metres travelled along the trail.
  final double distance;

  final int currentStreak;
  final int longestStreak;

  /// Consecutive scheduled days missed, counting back from yesterday.
  final int missStreak;

  /// 0…1 across the habit's whole lifetime.
  final double completionRate;

  final int scheduledDays;
  final int completedDays;

  /// 0…1 rolling energy over the last 14 scheduled days — drives glow and speed.
  final double momentum;

  final OrbState state;

  /// Completion ratio for each of the last 30 days, oldest first.
  final List<double> last30;

  /// Reward multiplier the next completion will be worth.
  double get nextMultiplier => 1.0 + math.min(currentStreak, 12) * 0.08;

  /// The orb evolves as its best streak grows — a visible sign of mastery.
  OrbTier get tier => OrbTierX.fromStreak(longestStreak);

  /// Progress (0…1) from the current tier toward the next one.
  double get tierProgress => OrbTierX.progress(longestStreak);

  /// Checkpoints are planted every 250 m along the trail.
  int get checkpointsReached => distance ~/ 250;

  double get progressToNextCheckpoint => (distance % 250) / 250;

  bool get isCompleteToday => habit.isCompleteOn(DayKey.today());

  bool get isScheduledToday => habit.isScheduledOn(DayKey.today());

  static const double _stepMetres = 10;
  static const double _tumbleMetres = 6;

  static OrbStats compute(
    Habit habit, {
    Set<String> protectedDays = const <String>{},
  }) {
    final DateTime today = DayKey.today();
    final DateTime start = DayKey.normalize(habit.createdAt);
    final int span = math.max(0, DayKey.daysBetween(start, today));

    double distance = 0;
    int streak = 0;
    int longest = 0;
    int scheduled = 0;
    int completed = 0;
    int missStreak = 0;

    for (int i = 0; i <= span; i++) {
      final DateTime day = start.add(Duration(days: i));
      final bool isToday = DayKey.isSameDay(day, today);
      if (!habit.isScheduledOn(day)) {
        continue;
      }
      // A shield absorbs this miss: the day is frozen, so it neither breaks the
      // streak nor counts against the completion rate.
      if (protectedDays.contains(DayKey.of(day)) && !habit.isCompleteOn(day)) {
        continue;
      }
      scheduled++;
      if (habit.isCompleteOn(day)) {
        completed++;
        distance += _stepMetres * (1.0 + math.min(streak, 12) * 0.08);
        streak++;
        longest = math.max(longest, streak);
        missStreak = 0;
      } else if (!isToday) {
        // Today is still in play, so only past days can tumble the orb.
        streak = 0;
        missStreak++;
        distance = math.max(0, distance - _tumbleMetres);
      }
    }

    // Partial credit for a day that is underway.
    if (habit.isScheduledOn(today) && !habit.isCompleteOn(today)) {
      distance += _stepMetres * habit.ratioOn(today) * 0.5;
    }

    final List<double> last30 = <double>[
      for (int i = 29; i >= 0; i--)
        habit.ratioOn(today.subtract(Duration(days: i))),
    ];

    final double momentum = _momentum(habit, today);

    return OrbStats(
      habit: habit,
      distance: distance,
      currentStreak: streak,
      longestStreak: longest,
      missStreak: missStreak,
      completionRate: scheduled == 0 ? 0 : completed / scheduled,
      scheduledDays: scheduled,
      completedDays: completed,
      momentum: momentum,
      state: _state(habit, today, missStreak),
      last30: last30,
    );
  }

  static double _momentum(Habit habit, DateTime today) {
    double weighted = 0;
    double total = 0;
    for (int i = 0; i < 14; i++) {
      final DateTime day = today.subtract(Duration(days: i));
      if (!habit.isScheduledOn(day)) continue;
      final double w = 1.0 - (i / 20);
      total += w;
      weighted += w * habit.ratioOn(day);
    }
    if (total == 0) return 0;
    return (weighted / total).clamp(0.0, 1.0);
  }

  static OrbState _state(Habit habit, DateTime today, int missStreak) {
    if (habit.isCompleteOn(today)) return OrbState.rolling;
    if (missStreak >= 3) return OrbState.shattered;
    if (missStreak >= 1) return OrbState.slipping;
    if (habit.isScheduledOn(today)) return OrbState.waiting;
    return OrbState.resting;
  }
}

/// Aggregate of the whole trail — every orb combined.
@immutable
class TrailSummary {
  const TrailSummary({
    required this.orbs,
    required this.totalDistance,
    required this.todayCompleted,
    required this.todayScheduled,
    required this.perfectDays,
    required this.dayStreak,
    required this.longestDayStreak,
    required this.totalCompletions,
    required this.averageMomentum,
  });

  final List<OrbStats> orbs;
  final double totalDistance;
  final int todayCompleted;
  final int todayScheduled;

  /// Days where every scheduled habit was completed.
  final int perfectDays;
  final int dayStreak;
  final int longestDayStreak;
  final int totalCompletions;
  final double averageMomentum;

  double get todayRatio =>
      todayScheduled == 0 ? 0 : todayCompleted / todayScheduled;

  bool get isPerfectToday => todayScheduled > 0 && todayCompleted == todayScheduled;

  static const TrailSummary empty = TrailSummary(
    orbs: <OrbStats>[],
    totalDistance: 0,
    todayCompleted: 0,
    todayScheduled: 0,
    perfectDays: 0,
    dayStreak: 0,
    longestDayStreak: 0,
    totalCompletions: 0,
    averageMomentum: 0,
  );

  static TrailSummary compute(
    List<Habit> habits, {
    Map<String, Set<String>> protectedDays = const <String, Set<String>>{},
  }) {
    final List<Habit> active =
        habits.where((Habit h) => !h.archived).toList(growable: false);
    if (active.isEmpty) return empty;

    final List<OrbStats> orbs = active
        .map((Habit h) => OrbStats.compute(
              h,
              protectedDays: protectedDays[h.id] ?? const <String>{},
            ))
        .toList(growable: false);
    final DateTime today = DayKey.today();

    int todayScheduled = 0;
    int todayCompleted = 0;
    for (final Habit h in active) {
      if (h.isScheduledOn(today)) {
        todayScheduled++;
        if (h.isCompleteOn(today)) todayCompleted++;
      }
    }

    final DateTime earliest = active
        .map((Habit h) => DayKey.normalize(h.createdAt))
        .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
    final int span = math.max(0, DayKey.daysBetween(earliest, today));

    int perfect = 0;
    int streak = 0;
    int longest = 0;
    int running = 0;
    for (int i = 0; i <= span; i++) {
      final DateTime day = earliest.add(Duration(days: i));
      final List<Habit> due = active
          .where((Habit h) =>
              h.isScheduledOn(day) &&
              !DayKey.normalize(h.createdAt).isAfter(day))
          .toList(growable: false);
      if (due.isEmpty) continue;
      final bool allDone = due.every((Habit h) => h.isCompleteOn(day));
      if (allDone) {
        perfect++;
        running++;
        longest = math.max(longest, running);
      } else if (!DayKey.isSameDay(day, today)) {
        running = 0;
      }
    }
    streak = running;

    return TrailSummary(
      orbs: orbs,
      totalDistance:
          orbs.fold<double>(0, (double s, OrbStats o) => s + o.distance),
      todayCompleted: todayCompleted,
      todayScheduled: todayScheduled,
      perfectDays: perfect,
      dayStreak: streak,
      longestDayStreak: longest,
      totalCompletions:
          active.fold<int>(0, (int s, Habit h) => s + h.totalCompletions),
      averageMomentum:
          orbs.fold<double>(0, (double s, OrbStats o) => s + o.momentum) /
              orbs.length,
    );
  }
}
