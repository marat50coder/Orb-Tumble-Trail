import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../habits/habit_detail_screen.dart';
import '../insights/insights_screen.dart';

enum StatRange { week, month, quarter }

extension on StatRange {
  int get days => switch (this) {
        StatRange.week => 7,
        StatRange.month => 30,
        StatRange.quarter => 90,
      };

  String get label => switch (this) {
        StatRange.week => '7 days',
        StatRange.month => '30 days',
        StatRange.quarter => '90 days',
      };
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatRange _range = StatRange.month;

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final SettingsController settings = context.watch<SettingsController>();
    final TrailSummary summary = habits.summary;
    final Color accent = Theme.of(context).colorScheme.primary;

    if (summary.orbs.isEmpty) {
      return Scaffold(
        backgroundColor: AppPalette.canvas,
        body: AuroraBackdrop(
          accent: accent,
          animated: !settings.value.reduceMotion,
          seed: 9,
          child: const SafeArea(
            child: EmptyState(
              icon: AppIcons.chartBar,
              title: 'No data yet',
              message:
                  'Charts appear once your orbs start rolling. Log a habit and\n'
                  'come back tomorrow.',
            ),
          ),
        ),
      );
    }

    final List<double> series = _dailyRatios(habits, _range.days);
    final List<double> weekday = _weekdayRatios(habits);

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      extendBody: true,
      body: AuroraBackdrop(
        accent: accent,
        animated: !settings.value.reduceMotion,
        seed: 9,
        intensity: 0.75,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Statistics', style: AppType.displayM()),
                        const SizedBox(height: 3),
                        Text('How the trail has been going', style: AppType.bodyS()),
                      ],
                    ),
                  ),
                  GlassIconButtonWrapper(
                    onTap: () => pushScreen(context, const InsightsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  for (final StatRange r in StatRange.values) ...<Widget>[
                    AuroraChip(
                      label: r.label,
                      selected: r == _range,
                      onTap: () => setState(() => _range = r),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SectionLabel('Consistency'),
              GlassPanel(
                radius: 26,
                padding: const EdgeInsets.fromLTRB(10, 22, 18, 12),
                child: SizedBox(
                  height: 190,
                  child: _TrendChart(values: series, accent: accent),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MetricCard(
                      value: '${(_average(series) * 100).round()}%',
                      label: 'average',
                      icon: AppIcons.gauge,
                      tone: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      value: '${summary.perfectDays}',
                      label: 'flawless days',
                      icon: AppIcons.sparkle,
                      tone: AppPalette.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      value: '${summary.longestDayStreak}',
                      label: 'best streak',
                      icon: AppIcons.fire,
                      tone: AppPalette.danger,
                    ),
                  ),
                ],
              ),
              const SectionLabel('Best days of the week'),
              GlassPanel(
                radius: 26,
                padding: const EdgeInsets.fromLTRB(8, 22, 16, 8),
                child: SizedBox(
                  height: 170,
                  child: _WeekdayChart(values: weekday, accent: accent),
                ),
              ),
              const SectionLabel('Orb leaderboard'),
              _Leaderboard(orbs: summary.orbs),
              const SectionLabel('Distance covered'),
              _DistanceCard(summary: summary),
            ],
          ),
        ),
      ),
    );
  }

  static double _average(List<double> v) =>
      v.isEmpty ? 0 : v.reduce((double a, double b) => a + b) / v.length;

  static List<double> _dailyRatios(HabitController controller, int days) {
    final DateTime today = DayKey.today();
    final List<Habit> habits = controller.habits;
    return <double>[
      for (int i = days - 1; i >= 0; i--)
        () {
          final DateTime day = today.subtract(Duration(days: i));
          final List<Habit> due = habits
              .where((Habit h) =>
                  h.isScheduledOn(day) &&
                  !DayKey.normalize(h.createdAt).isAfter(day))
              .toList(growable: false);
          if (due.isEmpty) return 0.0;
          final int done = due.where((Habit h) => h.isCompleteOn(day)).length;
          return done / due.length;
        }(),
    ];
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

/// Small trailing action on the stats header.
class GlassIconButtonWrapper extends StatelessWidget {
  const GlassIconButtonWrapper({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(AppIcons.brain, size: 15, color: accent),
              const SizedBox(width: 7),
              Text('Insights', style: AppType.label(color: accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.values, required this.accent});

  final List<double> values;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final int n = values.length;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        minX: 0,
        maxX: (n - 1).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (double v) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 0.5,
              getTitlesWidget: (double v, TitleMeta meta) => Text(
                '${(v * 100).round()}%',
                style: AppType.bodyS().copyWith(fontSize: 9.5),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: math.max(1, (n / 5).floorToDouble()),
              getTitlesWidget: (double v, TitleMeta meta) {
                final int back = n - 1 - v.round();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    back == 0 ? 'now' : '-$back',
                    style: AppType.bodyS().copyWith(fontSize: 9.5),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot spot) => AppPalette.canvasOverlay,
            getTooltipItems: (List<LineBarSpot> spots) => spots
                .map((LineBarSpot s) => LineTooltipItem(
                      '${(s.y * 100).round()}%',
                      AppType.bodyS(color: AppPalette.textPrimary),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: <FlSpot>[
              for (int i = 0; i < n; i++) FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            gradient: LinearGradient(
              colors: <Color>[AppPalette.auroraBlue, accent, AppPalette.auroraMagenta],
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  accent.withValues(alpha: 0.32),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart({required this.values, required this.accent});

  final List<double> values;
  final Color accent;

  static const List<String> _labels = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final double best = values.isEmpty
        ? 0
        : values.reduce((double a, double b) => math.max(a, b));

    return BarChart(
      BarChartData(
        maxY: 1,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (double v) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 0.5,
              getTitlesWidget: (double v, TitleMeta meta) => Text(
                '${(v * 100).round()}%',
                style: AppType.bodyS().copyWith(fontSize: 9.5),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (double v, TitleMeta meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _labels[v.toInt().clamp(0, 6)],
                  style: AppType.bodyS().copyWith(fontSize: 9.5),
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData g) => AppPalette.canvasOverlay,
            getTooltipItem: (BarChartGroupData g, int gi, BarChartRodData rod,
                    int ri) =>
                BarTooltipItem(
              '${(rod.toY * 100).round()}%',
              AppType.bodyS(color: AppPalette.textPrimary),
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (int i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: values[i],
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: values[i] >= best && best > 0
                        ? <Color>[accent, AppPalette.auroraMagenta]
                        : <Color>[
                            accent.withValues(alpha: 0.45),
                            accent.withValues(alpha: 0.18),
                          ],
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 1,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: StatTile(value: value, caption: label, icon: icon, tone: tone, valueSize: 20),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.orbs});

  final List<OrbStats> orbs;

  @override
  Widget build(BuildContext context) {
    final List<OrbStats> sorted = orbs.toList()
      ..sort((OrbStats a, OrbStats b) =>
          b.completionRate.compareTo(a.completionRate));

    return Column(
      children: <Widget>[
        for (int i = 0; i < sorted.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassPanel(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              onTap: () => pushScreen(
                context,
                HabitDetailScreen(habitId: sorted[i].habit.id),
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: AppType.numeric(
                        14,
                        color: i == 0
                            ? AppPalette.warning
                            : AppPalette.textTertiary,
                      ),
                    ),
                  ),
                  OrbView(
                    skin: sorted[i].habit.skin,
                    state: sorted[i].state,
                    size: 36,
                    momentum: sorted[i].momentum,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          sorted[i].habit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.titleS(),
                        ),
                        const SizedBox(height: 7),
                        AuroraBar(
                          value: sorted[i].completionRate,
                          height: 5,
                          gradient: LinearGradient(
                            colors: <Color>[
                              OrbArt.accent(sorted[i].habit.skin),
                              AppPalette.auroraMagenta,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(sorted[i].completionRate * 100).round()}%',
                    style: AppType.numeric(15),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (50 * i).ms, duration: 300.ms).slideX(
                  begin: 0.05,
                  curve: Curves.easeOutCubic,
                ),
          ),
      ],
    );
  }
}

class _DistanceCard extends StatelessWidget {
  const _DistanceCard({required this.summary});

  final TrailSummary summary;

  @override
  Widget build(BuildContext context) {
    final double km = summary.totalDistance / 1000;
    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  km >= 1
                      ? '${km.toStringAsFixed(2)} km'
                      : '${summary.totalDistance.round()} m',
                  style: AppType.numeric(30),
                ),
                const SizedBox(height: 6),
                Text('total distance rolled', style: AppType.bodyS()),
                const SizedBox(height: 14),
                Text(
                  '${summary.totalCompletions} completions · '
                  '${summary.orbs.fold<int>(0, (int s, OrbStats o) => s + o.checkpointsReached)} checkpoints',
                  style: AppType.bodyS(color: AppPalette.textSecondary),
                ),
              ],
            ),
          ),
          ProgressRing(
            value: (summary.totalDistance % 1000) / 1000,
            size: 76,
            stroke: 6,
            center: const Icon(
              AppIcons.path,
              size: 26,
              color: AppPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
