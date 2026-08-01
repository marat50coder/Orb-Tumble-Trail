import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';

class _Insight {
  const _Insight(this.icon, this.title, this.body, this.tone);
  final IconData icon;
  final String title;
  final String body;
  final Color tone;
}

/// Plain-language reading of the numbers. No charts here on purpose — this
/// screen answers "so what?" while Statistics answers "how much?".
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final TrailSummary summary = habits.summary;
    final List<_Insight> insights = _derive(habits, summary);

    return ScreenShell(
      title: 'Insights',
      subtitle: 'What the last few weeks are telling you',
      seed: 10,
      intensity: 0.7,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: summary.orbs.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: 60),
              child: EmptyState(
                icon: AppIcons.brain,
                title: 'Not enough signal',
                message: 'Log a few days and patterns will start showing up here.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Headline(summary: summary),
                const SectionLabel('Patterns'),
                for (int i = 0; i < insights.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InsightCard(
                      icon: insights[i].icon,
                      title: insights[i].title,
                      body: insights[i].body,
                      tone: insights[i].tone,
                    )
                        .animate()
                        .fadeIn(delay: (60 * i).ms, duration: 320.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                  ),
                const SectionLabel('Needs attention'),
                _AttentionList(summary: summary),
              ],
            ),
    );
  }

  static _Insight _strongest(TrailSummary summary) {
    final OrbStats best = summary.orbs.reduce((OrbStats a, OrbStats b) =>
        a.completionRate >= b.completionRate ? a : b);
    return _Insight(
      AppIcons.crown,
      'Your anchor is "${best.habit.title}"',
      'It holds a ${(best.completionRate * 100).round()}% completion rate and has '
          'rolled ${best.distance.round()} m. Lean on it when other orbs stall.',
      AppPalette.warning,
    );
  }

  static List<_Insight> _derive(HabitController controller, TrailSummary s) {
    final List<_Insight> out = <_Insight>[];
    if (s.orbs.isEmpty) return out;

    out.add(_strongest(s));

    // Weekday pattern.
    final List<double> weekday = _weekdayRatios(controller);
    if (weekday.any((double v) => v > 0)) {
      int bestDay = 0;
      int worstDay = 0;
      for (int i = 1; i < 7; i++) {
        if (weekday[i] > weekday[bestDay]) bestDay = i;
        if (weekday[i] < weekday[worstDay]) worstDay = i;
      }
      const List<String> names = <String>[
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
      ];
      out.add(_Insight(
        AppIcons.calendar,
        '${names[bestDay]} is your strongest day',
        'You close ${(weekday[bestDay] * 100).round()}% of scheduled orbs on '
            '${names[bestDay]}s, against ${(weekday[worstDay] * 100).round()}% on '
            '${names[worstDay]}s. Put the hard habit on the strong day.',
        AppPalette.info,
      ));
    }

    // Momentum reading.
    final int lively =
        s.orbs.where((OrbStats o) => o.momentum >= 0.7).length;
    out.add(_Insight(
      AppIcons.gauge,
      lively >= s.orbs.length / 2
          ? 'The trail is running hot'
          : 'Momentum is thinning out',
      '$lively of ${s.orbs.length} orbs are above 70% momentum. '
          'Average momentum sits at ${(s.averageMomentum * 100).round()}%.',
      lively >= s.orbs.length / 2 ? AppPalette.success : AppPalette.warning,
    ));

    // Streak reading.
    if (s.dayStreak > 0) {
      out.add(_Insight(
        AppIcons.fire,
        '${s.dayStreak} flawless ${s.dayStreak == 1 ? 'day' : 'days'} in a row',
        s.dayStreak >= s.longestDayStreak
            ? 'This is your longest run so far. One more day extends the record.'
            : 'Your record is ${s.longestDayStreak} days — '
                '${s.longestDayStreak - s.dayStreak} to go.',
        AppPalette.danger,
      ));
    } else {
      out.add(_Insight(
        AppIcons.refresh,
        'The streak is at zero',
        'Closing every scheduled orb today restarts it. Your record is '
            '${s.longestDayStreak} ${s.longestDayStreak == 1 ? 'day' : 'days'}.',
        AppPalette.textSecondary,
      ));
    }

    // Load balance.
    final int heaviest = s.orbs
        .map((OrbStats o) => o.habit.scheduledWeekdays.length)
        .fold<int>(0, math.max);
    if (s.orbs.length >= 4 && heaviest == 7) {
      out.add(const _Insight(
        AppIcons.scales,
        'Every orb is daily',
        'Daily targets are the fastest way to shatter an orb. Consider dropping '
            'one or two to weekdays so a busy Saturday costs you nothing.',
        AppPalette.info,
      ));
    }

    // Focus.
    if (controller.focusMinutes > 0) {
      out.add(_Insight(
        AppIcons.timer,
        '${controller.focusMinutes} focused minutes banked',
        'That is roughly ${(controller.focusMinutes / 60).toStringAsFixed(1)} hours '
            'of deliberate work logged through the focus timer.',
        AppPalette.auroraViolet,
      ));
    }

    return out;
  }

  static List<double> _weekdayRatios(HabitController controller) {
    final DateTime today = DayKey.today();
    final List<Habit> habits = controller.habits;
    final List<double> sums = List<double>.filled(7, 0);
    final List<int> counts = List<int>.filled(7, 0);

    for (int i = 0; i < 84; i++) {
      final DateTime day = today.subtract(Duration(days: i));
      final List<Habit> due = habits
          .where((Habit h) =>
              h.isScheduledOn(day) &&
              !DayKey.normalize(h.createdAt).isAfter(day))
          .toList(growable: false);
      if (due.isEmpty) continue;
      final int done = due.where((Habit h) => h.isCompleteOn(day)).length;
      sums[day.weekday - 1] += done / due.length;
      counts[day.weekday - 1]++;
    }
    return <double>[
      for (int i = 0; i < 7; i++) counts[i] == 0 ? 0 : sums[i] / counts[i],
    ];
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.summary});

  final TrailSummary summary;

  @override
  Widget build(BuildContext context) {
    final int score = (summary.averageMomentum * 100).round();
    final String verdict = score >= 80
        ? 'Excellent'
        : score >= 60
            ? 'Solid'
            : score >= 35
                ? 'Uneven'
                : 'Fragile';

    return GlassPanel(
      radius: 28,
      padding: const EdgeInsets.all(22),
      gradient: AppPalette.auroraSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('TRAIL HEALTH', style: AppType.overline()),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('$score', style: AppType.numeric(52)),
              Padding(
                padding: const EdgeInsets.only(bottom: 7, left: 4),
                child: Text('/100', style: AppType.bodyM()),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(verdict, style: AppType.titleM()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AuroraBar(value: score / 100, height: 8),
        ],
      ),
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({required this.summary});

  final TrailSummary summary;

  @override
  Widget build(BuildContext context) {
    final List<OrbStats> weak = summary.orbs
        .where((OrbStats o) =>
            o.state == OrbState.shattered ||
            o.state == OrbState.slipping ||
            o.momentum < 0.4)
        .toList()
      ..sort((OrbStats a, OrbStats b) => a.momentum.compareTo(b.momentum));

    if (weak.isEmpty) {
      return GlassPanel(
        radius: 22,
        child: Row(
          children: <Widget>[
            const Icon(AppIcons.checkCircle,
                size: 22, color: AppPalette.success),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Nothing is slipping. Every orb is holding its line.',
                style: AppType.bodyM(color: AppPalette.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final OrbStats o in weak)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassPanel(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              strokeColor: AppPalette.danger.withValues(alpha: 0.28),
              child: Row(
                children: <Widget>[
                  OrbView(
                    skin: o.habit.skin,
                    state: o.state,
                    size: 38,
                    momentum: o.momentum,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(o.habit.title, style: AppType.titleS()),
                        const SizedBox(height: 3),
                        Text(
                          o.state == OrbState.shattered
                              ? 'Shattered — needs one completion to reform'
                              : '${(o.momentum * 100).round()}% momentum · '
                                  '${o.missStreak} missed',
                          style: AppType.bodyS(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
