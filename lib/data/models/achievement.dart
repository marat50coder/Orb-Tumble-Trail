import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'orb_stats.dart';

enum AchievementTier { bronze, silver, gold, mythic }

extension AchievementTierX on AchievementTier {
  String get label => switch (this) {
        AchievementTier.bronze => 'Bronze',
        AchievementTier.silver => 'Silver',
        AchievementTier.gold => 'Gold',
        AchievementTier.mythic => 'Mythic',
      };
}

typedef AchievementMeasure = num Function(TrailSummary summary);

@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.tier,
    required this.goal,
    required this.measure,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final AchievementTier tier;
  final num goal;
  final AchievementMeasure measure;

  num valueFor(TrailSummary summary) => measure(summary);

  double progressFor(TrailSummary summary) =>
      (measure(summary) / goal).clamp(0.0, 1.0).toDouble();

  bool isUnlocked(TrailSummary summary) => measure(summary) >= goal;
}

class AchievementCatalog {
  const AchievementCatalog._();

  static final List<Achievement> all = <Achievement>[
    Achievement(
      id: 'first_roll',
      title: 'First Roll',
      description: 'Complete a habit for the very first time.',
      iconKey: 'sparkle',
      tier: AchievementTier.bronze,
      goal: 1,
      measure: (TrailSummary s) => s.totalCompletions,
    ),
    Achievement(
      id: 'ten_rolls',
      title: 'Getting Rolling',
      description: 'Log 10 completions across all orbs.',
      iconKey: 'circlesThree',
      tier: AchievementTier.bronze,
      goal: 10,
      measure: (TrailSummary s) => s.totalCompletions,
    ),
    Achievement(
      id: 'hundred_rolls',
      title: 'Centurion',
      description: 'Log 100 completions across all orbs.',
      iconKey: 'medal',
      tier: AchievementTier.gold,
      goal: 100,
      measure: (TrailSummary s) => s.totalCompletions,
    ),
    Achievement(
      id: 'five_hundred_rolls',
      title: 'Unstoppable',
      description: 'Log 500 completions across all orbs.',
      iconKey: 'crown',
      tier: AchievementTier.mythic,
      goal: 500,
      measure: (TrailSummary s) => s.totalCompletions,
    ),
    Achievement(
      id: 'perfect_day',
      title: 'Flawless Day',
      description: 'Finish every scheduled habit in a single day.',
      iconKey: 'checkCircle',
      tier: AchievementTier.bronze,
      goal: 1,
      measure: (TrailSummary s) => s.perfectDays,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Seven Skies',
      description: 'Reach 7 flawless days.',
      iconKey: 'sun',
      tier: AchievementTier.silver,
      goal: 7,
      measure: (TrailSummary s) => s.perfectDays,
    ),
    Achievement(
      id: 'perfect_month',
      title: 'Lunar Cycle',
      description: 'Reach 30 flawless days.',
      iconKey: 'moonStars',
      tier: AchievementTier.gold,
      goal: 30,
      measure: (TrailSummary s) => s.perfectDays,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Warm Start',
      description: 'Hold a 3 day flawless streak.',
      iconKey: 'fire',
      tier: AchievementTier.bronze,
      goal: 3,
      measure: (TrailSummary s) => s.longestDayStreak,
    ),
    Achievement(
      id: 'streak_14',
      title: 'Fortnight Flame',
      description: 'Hold a 14 day flawless streak.',
      iconKey: 'lightning',
      tier: AchievementTier.silver,
      goal: 14,
      measure: (TrailSummary s) => s.longestDayStreak,
    ),
    Achievement(
      id: 'streak_60',
      title: 'Eternal Ember',
      description: 'Hold a 60 day flawless streak.',
      iconKey: 'rocket',
      tier: AchievementTier.mythic,
      goal: 60,
      measure: (TrailSummary s) => s.longestDayStreak,
    ),
    Achievement(
      id: 'distance_500',
      title: 'Trailhead',
      description: 'Roll 500 m of combined trail.',
      iconKey: 'path',
      tier: AchievementTier.bronze,
      goal: 500,
      measure: (TrailSummary s) => s.totalDistance,
    ),
    Achievement(
      id: 'distance_5000',
      title: 'Ridge Runner',
      description: 'Roll 5 km of combined trail.',
      iconKey: 'mountains',
      tier: AchievementTier.gold,
      goal: 5000,
      measure: (TrailSummary s) => s.totalDistance,
    ),
    Achievement(
      id: 'five_orbs',
      title: 'Constellation',
      description: 'Keep 5 orbs alive at the same time.',
      iconKey: 'planet',
      tier: AchievementTier.silver,
      goal: 5,
      measure: (TrailSummary s) => s.orbs.length,
    ),
    Achievement(
      id: 'momentum_master',
      title: 'Momentum Master',
      description: 'Reach 90% average momentum across every orb.',
      iconKey: 'gauge',
      tier: AchievementTier.gold,
      goal: 90,
      measure: (TrailSummary s) => (s.averageMomentum * 100).round(),
    ),
    Achievement(
      id: 'single_streak_30',
      title: 'Diamond Orb',
      description: 'Push one orb to a 30 day streak.',
      iconKey: 'sphere',
      tier: AchievementTier.gold,
      goal: 30,
      measure: (TrailSummary s) => s.orbs.isEmpty
          ? 0
          : s.orbs
              .map((OrbStats o) => o.longestStreak)
              .reduce((int a, int b) => math.max(a, b)),
    ),
    Achievement(
      id: 'checkpoint_10',
      title: 'Waypoint Keeper',
      description: 'Pass 10 checkpoints across the trail.',
      iconKey: 'flagBanner',
      tier: AchievementTier.silver,
      goal: 10,
      measure: (TrailSummary s) => s.orbs
          .fold<int>(0, (int sum, OrbStats o) => sum + o.checkpointsReached),
    ),
  ];
}
