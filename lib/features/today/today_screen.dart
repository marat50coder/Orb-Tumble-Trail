import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/habit_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../focus/focus_screen.dart';
import '../habits/habit_detail_screen.dart';
import '../habits/habit_editor_screen.dart';
import '../journal/journal_screen.dart';

/// A calm, linear agenda for the current day. Deliberately list-first so it
/// reads completely differently from the trail scene.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final SettingsController settings = context.watch<SettingsController>();
    final TrailSummary summary = habits.summary;
    final DateTime today = DayKey.today();

    final List<OrbStats> scheduled = summary.orbs
        .where((OrbStats o) => o.isScheduledToday)
        .toList(growable: false);
    final List<OrbStats> open = scheduled
        .where((OrbStats o) => !o.isCompleteToday)
        .toList(growable: false);
    final List<OrbStats> done = scheduled
        .where((OrbStats o) => o.isCompleteToday)
        .toList(growable: false);
    final List<OrbStats> resting = summary.orbs
        .where((OrbStats o) => !o.isScheduledToday)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      extendBody: true,
      body: AuroraBackdrop(
        accent: Theme.of(context).colorScheme.primary,
        animated: !settings.value.reduceMotion,
        seed: 2,
        intensity: 0.8,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _TodayHero(summary: summary),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _QuickActions(
                    onFocus: () => pushScreen(context, const FocusScreen()),
                    onJournal: () => pushScreen(context, const JournalScreen()),
                    onAll: open.isEmpty
                        ? null
                        : () async {
                            settings.success();
                            final int n = await habits.rollAllDueToday();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$n ${n == 1 ? 'orb' : 'orbs'} pushed to the ridge.',
                                    style: AppType.bodyM(
                                        color: AppPalette.textPrimary),
                                  ),
                                ),
                              );
                          },
                  ),
                ),
              ),
              if (scheduled.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: AppIcons.moonStars,
                    title: 'Nothing scheduled',
                    message:
                        'No orbs are due today. Enjoy the rest, or add something new.',
                    action: GhostButton(
                      label: 'New orb',
                      icon: AppIcons.plus,
                      onPressed: () =>
                          pushScreen(context, const HabitEditorScreen()),
                    ),
                  ),
                ),
              if (open.isNotEmpty) ...<Widget>[
                _label('Due now  ·  ${open.length}'),
                _list(context, open, today, false),
              ],
              if (done.isNotEmpty) ...<Widget>[
                _label('Rolled  ·  ${done.length}'),
                _list(context, done, today, true),
              ],
              if (resting.isNotEmpty) ...<Widget>[
                _label('Resting  ·  ${resting.length}'),
                _list(context, resting, today, false, muted: true),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionLabel(text),
        ),
      );

  Widget _list(
    BuildContext context,
    List<OrbStats> items,
    DateTime today,
    bool completed, {
    bool muted = false,
  }) {
    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _AgendaRow(
          stats: items[i],
          muted: muted,
          today: today,
        ).animate().fadeIn(delay: (35 * i).ms, duration: 300.ms).slideX(
              begin: 0.06,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.summary});

  final TrailSummary summary;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return GlassPanel(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: <Widget>[
          ProgressRing(
            value: summary.todayRatio,
            size: 92,
            stroke: 7,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${(summary.todayRatio * 100).round()}',
                  style: AppType.numeric(26),
                ),
                Text('percent', style: AppType.bodyS().copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateFormat('EEEE').format(DateTime.now()),
                  style: AppType.titleM(),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d MMMM yyyy').format(DateTime.now()),
                  style: AppType.bodyS(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    _MiniStat(
                      value: '${summary.todayCompleted}/${summary.todayScheduled}',
                      label: 'today',
                      tone: accent,
                    ),
                    const SizedBox(width: 18),
                    _MiniStat(
                      value: '${summary.dayStreak}',
                      label: 'day streak',
                      tone: AppPalette.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label, required this.tone});

  final String value;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value, style: AppType.numeric(16, color: tone)),
        const SizedBox(height: 2),
        Text(label, style: AppType.bodyS().copyWith(fontSize: 10.5)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onFocus,
    required this.onJournal,
    required this.onAll,
  });

  final VoidCallback onFocus;
  final VoidCallback onJournal;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionTile(
            icon: AppIcons.timer,
            label: 'Focus',
            onTap: onFocus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: AppIcons.editNote,
            label: 'Journal',
            onTap: onJournal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: AppIcons.checkCircle,
            label: 'Roll all',
            onTap: onAll,
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GlassPanel(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        tint: highlight && enabled ? accent.withValues(alpha: 0.14) : null,
        strokeColor:
            highlight && enabled ? accent.withValues(alpha: 0.5) : null,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 24,
                color: highlight && enabled ? accent : AppPalette.textSecondary,
              ),
              const SizedBox(height: 9),
              Text(label, style: AppType.bodyS().copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.stats,
    required this.today,
    this.muted = false,
  });

  final OrbStats stats;
  final DateTime today;
  final bool muted;

  String get _timeLabel {
    final int? m = stats.habit.reminderMinutes;
    if (m == null) return 'Any time';
    final int h = m ~/ 60;
    final int min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Habit habit = stats.habit;
    final HabitController controller = context.read<HabitController>();
    final SettingsController settings = context.read<SettingsController>();
    final Color accent = OrbArt.accent(habit.skin);
    final bool done = stats.isCompleteToday;
    final int count = habit.countOn(today);

    return Opacity(
      opacity: muted ? 0.55 : 1,
      child: GlassPanel(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        strong: done,
        strokeColor: done ? accent.withValues(alpha: 0.45) : null,
        onTap: () => pushScreen(context, HabitDetailScreen(habitId: habit.id)),
        child: Row(
          children: <Widget>[
            OrbView(
              skin: habit.skin,
              state: stats.state,
              size: 44,
              momentum: stats.momentum,
              animated: !muted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          habit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.titleS(),
                        ),
                      ),
                      if (habit.kind == HabitKind.quit) ...<Widget>[
                        const SizedBox(width: 8),
                        const Icon(
                          AppIcons.block,
                          size: 13,
                          color: AppPalette.danger,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Icon(
                        HabitIcons.resolveBold(habit.iconKey),
                        size: 12,
                        color: AppPalette.textTertiary,
                      ),
                      const SizedBox(width: 5),
                      Text(_timeLabel, style: AppType.bodyS().copyWith(fontSize: 11)),
                      const SizedBox(width: 10),
                      Container(width: 3, height: 3, decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppPalette.textTertiary)),
                      const SizedBox(width: 10),
                      Text(
                        habit.dailyTarget > 1
                            ? '$count / ${habit.dailyTarget} ${habit.unit}s'
                            : '${stats.currentStreak} day streak',
                        style: AppType.bodyS().copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  if (habit.dailyTarget > 1) ...<Widget>[
                    const SizedBox(height: 9),
                    AuroraBar(
                      value: stats.habit.ratioOn(today),
                      height: 4,
                      gradient: LinearGradient(
                        colors: <Color>[accent, AppPalette.auroraMagenta],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _RollButton(
              done: done,
              accent: accent,
              onTap: () async {
                if (done) {
                  settings.tap();
                  await controller.setDayComplete(habit.id, today, false);
                } else {
                  settings.impact();
                  await controller.roll(habit.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RollButton extends StatelessWidget {
  const _RollButton({
    required this.done,
    required this.accent,
    required this.onTap,
  });

  final bool done;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? accent : Colors.transparent,
          border: Border.all(
            color: done ? accent : AppPalette.glassStrokeStrong,
            width: 1.6,
          ),
          boxShadow: <BoxShadow>[
            if (done)
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Icon(
          done ? AppIcons.check : AppIcons.caretRight,
          size: 18,
          color: done ? Colors.white : AppPalette.textSecondary,
        ),
      ),
    );
  }
}
