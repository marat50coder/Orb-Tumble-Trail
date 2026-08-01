import 'dart:math' as math;

import '../../core/constants/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A snapshot of the player's meta-progression. Everything here is *derived*
/// from real habit activity (completions, perfect days) plus a small amount of
/// persisted state (claimed quest XP, spent shields), so progress can never be
/// silently lost or double-counted.
@immutable
class PlayerProgress {
  const PlayerProgress({
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForLevel,
    required this.totalCompletions,
    required this.shieldsEarned,
    required this.shieldsUsed,
  });

  /// Lifetime experience.
  final int totalXp;

  /// Current level (starts at 1).
  final int level;

  /// XP accumulated inside the current level.
  final int xpIntoLevel;

  /// XP needed to clear the current level.
  final int xpForLevel;

  /// Lifetime fully-completed habit-days.
  final int totalCompletions;

  final int shieldsEarned;
  final int shieldsUsed;

  int get shieldsAvailable => math.max(0, shieldsEarned - shieldsUsed);

  /// Completions still needed before the next shield is minted.
  int get completionsToNextShield =>
      completionsPerShield - (totalCompletions % completionsPerShield);

  double get shieldProgress =>
      (totalCompletions % completionsPerShield) / completionsPerShield;

  double get levelProgress =>
      xpForLevel == 0 ? 0 : (xpIntoLevel / xpForLevel).clamp(0.0, 1.0);

  /// The rank title shown next to the level number.
  String get rank {
    if (level >= 40) return 'Nova Warden';
    if (level >= 30) return 'Starbinder';
    if (level >= 22) return 'Trailmaster';
    if (level >= 15) return 'Pathfinder';
    if (level >= 9) return 'Wayfarer';
    if (level >= 4) return 'Roller';
    return 'Spark';
  }

  /// How much XP a single completion / perfect day is worth. Kept here so the
  /// UI can explain the economy to the player.
  static const int xpPerCompletion = 12;
  static const int xpPerPerfectDay = 30;

  /// One protective shield is granted for every [completionsPerShield]
  /// lifetime completions.
  static const int completionsPerShield = 12;

  /// Triangular level curve: level L costs `100 * L` XP to clear.
  static int costForLevel(int level) => 100 * level;

  static PlayerProgress derive({
    required int totalCompletions,
    required int perfectDays,
    required int achievementsUnlocked,
    required int claimedQuestXp,
    required int shieldsUsed,
  }) {
    final int xp = totalCompletions * xpPerCompletion +
        perfectDays * xpPerPerfectDay +
        achievementsUnlocked * 60 +
        claimedQuestXp;

    int level = 1;
    int remaining = xp;
    while (remaining >= costForLevel(level)) {
      remaining -= costForLevel(level);
      level++;
    }

    return PlayerProgress(
      totalXp: xp,
      level: level,
      xpIntoLevel: remaining,
      xpForLevel: costForLevel(level),
      totalCompletions: totalCompletions,
      shieldsEarned: totalCompletions ~/ completionsPerShield,
      shieldsUsed: shieldsUsed,
    );
  }
}

/// What a daily quest measures. Progress for each is computed live from the
/// day's real habit activity in the controller.
enum QuestKind { rolls, completions, perfect, variety, focus }

@immutable
class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.kind,
    required this.target,
    required this.xp,
  });

  final String id;
  final QuestKind kind;
  final int target;
  final int xp;

  String get title => switch (kind) {
        QuestKind.rolls => 'Roll $target ${target == 1 ? 'time' : 'times'}',
        QuestKind.completions =>
          'Complete $target ${target == 1 ? 'orb' : 'orbs'}',
        QuestKind.perfect => 'Reach a flawless day',
        QuestKind.variety => 'Roll $target different colours',
        QuestKind.focus => 'Log $target focus minutes',
      };

  String get subtitle => switch (kind) {
        QuestKind.rolls => 'Every tap on an orb counts',
        QuestKind.completions => 'Close their daily target',
        QuestKind.perfect => 'Finish every orb due today',
        QuestKind.variety => 'Different orb skins',
        QuestKind.focus => 'Use the focus timer',
      };

  IconData get icon => switch (kind) {
        QuestKind.rolls => AppIcons.lightning,
        QuestKind.completions => AppIcons.checkCircle,
        QuestKind.perfect => AppIcons.sparkle,
        QuestKind.variety => AppIcons.palette,
        QuestKind.focus => AppIcons.timer,
      };

  /// Deterministically builds the day's three quests from the date key, so the
  /// same quests reappear across restarts on the same day.
  static List<DailyQuest> forDay(String dayKey, {int scheduledToday = 3}) {
    final math.Random rnd = math.Random(dayKey.hashCode);
    final int rollTarget = 3 + rnd.nextInt(4); // 3..6
    final int completeTarget =
        math.max(1, math.min(scheduledToday, 2 + rnd.nextInt(2))); // 2..3
    final int focusTarget = 10 + rnd.nextInt(3) * 5; // 10/15/20

    return <DailyQuest>[
      DailyQuest(
          id: '$dayKey-rolls', kind: QuestKind.rolls, target: rollTarget, xp: 40),
      DailyQuest(
          id: '$dayKey-complete',
          kind: QuestKind.completions,
          target: completeTarget,
          xp: 50),
      // Alternate the third quest so the set feels fresh day to day.
      if (rnd.nextBool())
        DailyQuest(
            id: '$dayKey-variety', kind: QuestKind.variety, target: 2, xp: 60)
      else
        DailyQuest(
            id: '$dayKey-focus',
            kind: QuestKind.focus,
            target: focusTarget,
            xp: 60),
    ];
  }
}

/// A quest paired with its live progress for rendering.
@immutable
class QuestProgress {
  const QuestProgress({
    required this.quest,
    required this.current,
    required this.claimed,
  });

  final DailyQuest quest;
  final int current;
  final bool claimed;

  bool get complete => current >= quest.target;
  bool get claimable => complete && !claimed;
  double get ratio => (current / quest.target).clamp(0.0, 1.0).toDouble();
}
