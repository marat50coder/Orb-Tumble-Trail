import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../calendar/habit_calendar_screen.dart';
import 'habit_editor_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.watch<HabitController>();
    final Habit? habit = controller.byId(habitId);

    if (habit == null) {
      return const ScreenShell(
        title: 'Orb not found',
        seed: 5,
        child: EmptyState(
          icon: AppIcons.circleDashed,
          title: 'This orb is gone',
          message: 'It was removed from the trail.',
        ),
      );
    }

    final OrbStats stats = controller.statsFor(habit);
    final Color accent = OrbArt.accent(habit.skin);

    return ScreenShell(
      title: habit.title,
      subtitle: '${OrbArt.label(habit.skin)} orb · ${_stateLabel(stats.state)}',
      seed: 5,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      actions: <Widget>[
        GlassIconButton(
          icon: AppIcons.edit,
          onPressed: () => pushScreen(context, HabitEditorScreen(habit: habit)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Hero(stats: stats, accent: accent),
          const SectionLabel('Momentum'),
          _MomentumCard(stats: stats, accent: accent),
          const SectionLabel('The last 30 days'),
          _HeatStrip(stats: stats, accent: accent),
          const SectionLabel('Numbers'),
          _NumbersGrid(stats: stats),
          if (habit.description.isNotEmpty) ...<Widget>[
            const SectionLabel('Why it matters'),
            GlassPanel(
              radius: 22,
              child: Text(
                habit.description,
                style: AppType.bodyM(color: AppPalette.textSecondary),
              ),
            ),
          ],
          const SectionLabel('Actions'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: <Widget>[
                SettingRow(
                  icon: AppIcons.calendar,
                  title: 'Full history',
                  subtitle: 'Fill in days you forgot to log',
                  onTap: () => pushScreen(
                    context,
                    HabitCalendarScreen(habitId: habit.id),
                  ),
                ),
                const Divider(),
                if (stats.missStreak > 0) ...<Widget>[
                  SettingRow(
                    icon: AppIcons.shield,
                    title: controller.shieldsAvailable > 0
                        ? 'Use a streak shield'
                        : 'No shields yet',
                    subtitle: controller.shieldsAvailable > 0
                        ? 'Freeze the last miss \u2022 ${controller.shieldsAvailable} available'
                        : 'Complete more orbs to earn one',
                    tone: AppPalette.info,
                    onTap: controller.shieldsAvailable > 0
                        ? () async {
                            final SettingsController s =
                                context.read<SettingsController>();
                            final bool ok =
                                await controller.useShieldOn(habit.id);
                            if (ok) s.success();
                          }
                        : null,
                  ),
                  const Divider(),
                ],
                SettingRow(
                  icon: habit.archived
                      ? AppIcons.undo
                      : AppIcons.stack,
                  title: habit.archived ? 'Restore orb' : 'Archive orb',
                  subtitle: habit.archived
                      ? 'Bring it back to the trail'
                      : 'Keep the history, hide it from the trail',
                  onTap: () async {
                    context.read<SettingsController>().tap();
                    await controller.setArchived(habit.id, !habit.archived);
                  },
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.trash,
                  title: 'Delete orb',
                  subtitle: 'Removes the habit and its whole history',
                  tone: AppPalette.danger,
                  onTap: () async {
                    final bool ok = await _confirm(context, habit);
                    if (!ok || !context.mounted) return;
                    await controller.remove(habit.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _stateLabel(OrbState state) => switch (state) {
        OrbState.rolling => 'rolling today',
        OrbState.waiting => 'waiting for you',
        OrbState.resting => 'resting',
        OrbState.slipping => 'losing grip',
        OrbState.shattered => 'shattered',
      };

  static Future<bool> _confirm(BuildContext context, Habit habit) async {
    if (!context.read<SettingsController>().value.confirmDeletion) return true;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Shatter this orb?'),
        content: Text(
          '"${habit.title}" and all of its history will be removed permanently.',
          style: AppType.bodyM(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep', style: AppType.label()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: AppType.label(color: AppPalette.danger)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.stats, required this.accent});

  final OrbStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Habit habit = stats.habit;
    final HabitController controller = context.read<HabitController>();
    final SettingsController settings = context.read<SettingsController>();
    final DateTime today = DayKey.today();
    final int count = habit.countOn(today);

    return GlassPanel(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ProgressRing(
                  value: stats.progressToNextCheckpoint,
                  size: 168,
                  stroke: 5,
                  colors: <Color>[accent, AppPalette.auroraMagenta],
                ),
                OrbView(
                  skin: habit.skin,
                  state: stats.state,
                  size: 118,
                  momentum: stats.momentum,
                  spin: stats.state == OrbState.rolling,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accent.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${stats.tier.label} tier \u2022 best streak ${stats.longestStreak}',
              style: AppType.bodyS(color: accent).copyWith(fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${stats.distance.round()} m travelled',
            style: AppType.numeric(20),
          ),
          const SizedBox(height: 5),
          Text(
            'Checkpoint ${stats.checkpointsReached + 1} · '
            '${(250 - stats.distance % 250).round()} m to go',
            style: AppType.bodyS(),
          ),
          const SizedBox(height: 20),
          if (habit.dailyTarget > 1) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: AuroraBar(
                    value: habit.ratioOn(today),
                    height: 8,
                    gradient: LinearGradient(
                      colors: <Color>[accent, AppPalette.auroraMagenta],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$count/${habit.dailyTarget}',
                  style: AppType.numeric(14, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: AuroraButton(
                  label: stats.isCompleteToday
                      ? 'Done for today'
                      : (habit.dailyTarget > 1 ? 'Push forward' : 'Roll it'),
                  icon: stats.isCompleteToday
                      ? AppIcons.check
                      : AppIcons.caretRight,
                  gradient: stats.isCompleteToday
                      ? const LinearGradient(
                          colors: <Color>[AppPalette.success, Color(0xFF2FB37A)],
                        )
                      : LinearGradient(
                          colors: <Color>[accent, AppPalette.auroraMagenta],
                        ),
                  onPressed: stats.isCompleteToday
                      ? null
                      : () {
                          settings.impact();
                          controller.roll(habit.id);
                        },
                ),
              ),
              if (count > 0) ...<Widget>[
                const SizedBox(width: 10),
                GlassIconButton(
                  icon: AppIcons.undo,
                  size: 56,
                  tooltip: 'Undo one',
                  onPressed: () {
                    settings.tap();
                    controller.unroll(habit.id);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard({required this.stats, required this.accent});

  final OrbStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final String verdict = switch (stats.state) {
      OrbState.rolling => 'Rolling strong. Next completion is worth '
          '×${stats.nextMultiplier.toStringAsFixed(2)}.',
      OrbState.waiting => 'Still parked. One tap sets it moving again.',
      OrbState.resting => 'Off-schedule today — nothing to do.',
      OrbState.slipping =>
        'It slipped ${stats.missStreak} scheduled ${stats.missStreak == 1 ? 'day' : 'days'}. '
            'Two more and it shatters.',
      OrbState.shattered =>
        'Shattered after ${stats.missStreak} missed days. One completion reforges it.',
    };

    return GlassPanel(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('${(stats.momentum * 100).round()}%', style: AppType.numeric(30)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('momentum', style: AppType.bodyS()),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '×${stats.nextMultiplier.toStringAsFixed(2)}',
                  style: AppType.numeric(13, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AuroraBar(
            value: stats.momentum,
            height: 8,
            gradient: LinearGradient(
              colors: <Color>[accent, AppPalette.auroraMagenta],
            ),
          ),
          const SizedBox(height: 14),
          Text(verdict, style: AppType.bodyS(color: AppPalette.textSecondary)),
        ],
      ),
    );
  }
}

class _HeatStrip extends StatelessWidget {
  const _HeatStrip({required this.stats, required this.accent});

  final OrbStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final DateTime today = DayKey.today();
    final HabitController controller = context.read<HabitController>();

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              for (int i = 29; i >= 0; i--)
                _HeatCell(
                  day: today.subtract(Duration(days: i)),
                  ratio: stats.habit.ratioOn(today.subtract(Duration(days: i))),
                  scheduled: stats.habit
                      .isScheduledOn(today.subtract(Duration(days: i))),
                  accent: accent,
                  onTap: () {
                    context.read<SettingsController>().tap();
                    controller.toggleDay(
                      stats.habit.id,
                      today.subtract(Duration(days: i)),
                    );
                  },
                ).animate().fadeIn(delay: (6 * (29 - i)).ms, duration: 220.ms),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                DateFormat('d MMM').format(today.subtract(const Duration(days: 29))),
                style: AppType.bodyS().copyWith(fontSize: 10.5),
              ),
              const Spacer(),
              Text('tap a day to correct it',
                  style: AppType.bodyS().copyWith(fontSize: 10.5)),
              const Spacer(),
              Text('today', style: AppType.bodyS().copyWith(fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.day,
    required this.ratio,
    required this.scheduled,
    required this.accent,
    required this.onTap,
  });

  final DateTime day;
  final double ratio;
  final bool scheduled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isToday = DayKey.isSameDay(day, DayKey.today());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: ratio > 0
              ? accent.withValues(alpha: 0.22 + 0.6 * ratio)
              : (scheduled
                  ? AppPalette.glassFillStrong
                  : Colors.white.withValues(alpha: 0.03)),
          border: Border.all(
            color: isToday
                ? Colors.white.withValues(alpha: 0.75)
                : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: AppType.bodyS(
              color: ratio > 0.5 ? Colors.white : AppPalette.textTertiary,
            ).copyWith(fontSize: 9.5),
          ),
        ),
      ),
    );
  }
}

class _NumbersGrid extends StatelessWidget {
  const _NumbersGrid({required this.stats});

  final OrbStats stats;

  @override
  Widget build(BuildContext context) {
    final List<List<dynamic>> cells = <List<dynamic>>[
      <dynamic>['${stats.currentStreak}', 'current streak', AppIcons.fire],
      <dynamic>['${stats.longestStreak}', 'best streak', AppIcons.crown],
      <dynamic>[
        '${(stats.completionRate * 100).round()}%',
        'completion',
        AppIcons.target
      ],
      <dynamic>['${stats.completedDays}', 'days done', AppIcons.checkCircle],
      <dynamic>[
        '${stats.habit.totalRepetitions}',
        'total ${stats.habit.unit}s',
        AppIcons.stack
      ],
      <dynamic>[
        '${stats.checkpointsReached}',
        'checkpoints',
        AppIcons.flag
      ],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: cells.length,
      itemBuilder: (BuildContext context, int i) => GlassPanel(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: StatTile(
          value: cells[i][0] as String,
          caption: cells[i][1] as String,
          icon: cells[i][2] as IconData,
          valueSize: 20,
        ),
      ),
    );
  }
}

/// Small helper reused by the calendar screen.
double heatOpacity(double ratio) => math.max(0.08, ratio);
