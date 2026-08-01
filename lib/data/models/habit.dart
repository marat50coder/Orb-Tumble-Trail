import 'package:flutter/foundation.dart';

import '../../core/utils/day_key.dart';

/// The four orb sprites shipped with the app. Every habit adopts one, which
/// drives its colour language everywhere in the product.
enum OrbSkin { green, orange, purple, red }

extension OrbSkinX on OrbSkin {
  String get key => name;

  static OrbSkin fromKey(String? value) => OrbSkin.values.firstWhere(
        (OrbSkin s) => s.name == value,
        orElse: () => OrbSkin.purple,
      );
}

/// How a habit behaves when the user interacts with it.
enum HabitKind {
  /// Tap once to complete (or tap N times when [Habit.dailyTarget] > 1).
  build,

  /// A habit the user is trying to avoid — completing means "stayed clean".
  quit,
}

/// Health of an orb on the trail, derived from recent behaviour.
enum OrbState {
  /// Completed today — glowing and moving.
  rolling,

  /// Scheduled today but not done yet.
  waiting,

  /// Off-schedule today, resting.
  resting,

  /// One or two scheduled misses in a row.
  slipping,

  /// Three or more consecutive scheduled misses — the orb has tumbled.
  shattered,
}

@immutable
class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.skin,
    required this.iconKey,
    required this.createdAt,
    this.description = '',
    this.dailyTarget = 1,
    this.unit = 'time',
    this.kind = HabitKind.build,
    this.scheduledWeekdays = const <int>{1, 2, 3, 4, 5, 6, 7},
    this.reminderMinutes,
    this.archived = false,
    this.progress = const <String, int>{},
  });

  final String id;
  final String title;
  final String description;
  final OrbSkin skin;
  final String iconKey;
  final DateTime createdAt;

  /// How many taps constitute a completed day.
  final int dailyTarget;

  /// Noun rendered next to the counter ("glass", "page", "minute").
  final String unit;

  final HabitKind kind;

  /// ISO weekdays (Mon = 1 … Sun = 7) this habit is expected on.
  final Set<int> scheduledWeekdays;

  /// Minutes since midnight for the daily nudge, or null when muted.
  final int? reminderMinutes;

  final bool archived;

  /// dayKey → number of repetitions logged that day.
  final Map<String, int> progress;

  bool isScheduledOn(DateTime day) => scheduledWeekdays.contains(day.weekday);

  int countOn(DateTime day) => progress[DayKey.of(day)] ?? 0;

  bool isCompleteOn(DateTime day) => countOn(day) >= dailyTarget;

  double ratioOn(DateTime day) =>
      (countOn(day) / dailyTarget).clamp(0.0, 1.0).toDouble();

  /// Every day the habit was fully completed, most recent first.
  List<DateTime> get completedDays {
    final List<DateTime> days = progress.entries
        .where((MapEntry<String, int> e) => e.value >= dailyTarget)
        .map((MapEntry<String, int> e) => DayKey.parse(e.key))
        .toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));
    return days;
  }

  int get totalCompletions => progress.values
      .where((int v) => v >= dailyTarget)
      .length;

  int get totalRepetitions =>
      progress.values.fold<int>(0, (int sum, int v) => sum + v);

  Habit copyWith({
    String? title,
    String? description,
    OrbSkin? skin,
    String? iconKey,
    int? dailyTarget,
    String? unit,
    HabitKind? kind,
    Set<int>? scheduledWeekdays,
    int? reminderMinutes,
    bool clearReminder = false,
    bool? archived,
    Map<String, int>? progress,
  }) {
    return Habit(
      id: id,
      createdAt: createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      skin: skin ?? this.skin,
      iconKey: iconKey ?? this.iconKey,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      unit: unit ?? this.unit,
      kind: kind ?? this.kind,
      scheduledWeekdays: scheduledWeekdays ?? this.scheduledWeekdays,
      reminderMinutes:
          clearReminder ? null : (reminderMinutes ?? this.reminderMinutes),
      archived: archived ?? this.archived,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'skin': skin.name,
        'iconKey': iconKey,
        'createdAt': createdAt.toIso8601String(),
        'dailyTarget': dailyTarget,
        'unit': unit,
        'kind': kind.name,
        'weekdays': scheduledWeekdays.toList()..sort(),
        'reminderMinutes': reminderMinutes,
        'archived': archived,
        'progress': progress,
      };

  static Habit fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      skin: OrbSkinX.fromKey(json['skin'] as String?),
      iconKey: json['iconKey'] as String? ?? 'sparkle',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      dailyTarget: (json['dailyTarget'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'time',
      kind: HabitKind.values.firstWhere(
        (HabitKind k) => k.name == json['kind'],
        orElse: () => HabitKind.build,
      ),
      scheduledWeekdays: <int>{
        ...((json['weekdays'] as List<dynamic>?) ?? <dynamic>[1, 2, 3, 4, 5, 6, 7])
            .map((dynamic e) => (e as num).toInt()),
      },
      reminderMinutes: (json['reminderMinutes'] as num?)?.toInt(),
      archived: json['archived'] as bool? ?? false,
      progress: <String, int>{
        ...((json['progress'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{})
            .map((dynamic k, dynamic v) =>
                MapEntry<String, int>(k as String, (v as num).toInt())),
      },
    );
  }
}
