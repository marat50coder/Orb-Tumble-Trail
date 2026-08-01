import 'package:flutter_test/flutter_test.dart';
import 'package:trailgame/core/utils/day_key.dart';
import 'package:trailgame/data/models/habit.dart';
import 'package:trailgame/data/models/orb_stats.dart';

void main() {
  final DateTime today = DayKey.today();
  String key(int daysAgo) =>
      DayKey.of(today.subtract(Duration(days: daysAgo)));

  Habit habit({
    required String id,
    int dailyTarget = 1,
    required Map<String, int> progress,
    int createdDaysAgo = 30,
  }) {
    return Habit(
      id: id,
      title: id,
      skin: OrbSkin.purple,
      iconKey: 'star',
      createdAt: today.subtract(Duration(days: createdDaysAgo)),
      dailyTarget: dailyTarget,
      progress: progress,
    );
  }

  test('a habit completed every day builds a streak and rolls', () {
    final OrbStats stats = OrbStats.compute(
      habit(
        id: 'read',
        progress: <String, int>{for (int i = 0; i < 5; i++) key(i): 1},
      ),
    );

    expect(stats.currentStreak, 5);
    expect(stats.state, OrbState.rolling);
    expect(stats.distance, greaterThan(0));
  });

  test('three consecutive scheduled misses shatter the orb', () {
    final OrbStats stats = OrbStats.compute(
      habit(id: 'run', progress: <String, int>{key(4): 1}),
    );

    expect(stats.missStreak, greaterThanOrEqualTo(3));
    expect(stats.state, OrbState.shattered);
  });

  test('multi-target habits only close the day at their target', () {
    final Habit water =
        habit(id: 'water', dailyTarget: 8, progress: <String, int>{key(0): 5});

    expect(water.isCompleteOn(today), isFalse);
    expect(water.ratioOn(today), closeTo(0.625, 0.001));
    expect(water.countOn(today), 5);
  });

  test('a habit resting today is not counted as a miss', () {
    final Habit weekly = Habit(
      id: 'weekly',
      title: 'Deep clean',
      skin: OrbSkin.green,
      iconKey: 'star',
      createdAt: today.subtract(const Duration(days: 2)),
      scheduledWeekdays: <int>{(today.weekday % 7) + 1},
    );

    expect(weekly.isScheduledOn(today), isFalse);
    expect(OrbStats.compute(weekly).state, OrbState.resting);
  });
}
