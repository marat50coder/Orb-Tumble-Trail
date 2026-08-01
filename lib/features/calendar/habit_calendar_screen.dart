import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
import '../../state/settings_controller.dart';

/// Month view for a single orb — the place to repair a forgotten day.
class HabitCalendarScreen extends StatefulWidget {
  const HabitCalendarScreen({super.key, required this.habitId});

  final String habitId;

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  DateTime _focused = DayKey.today();
  DateTime _selected = DayKey.today();

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.watch<HabitController>();
    final SettingsController settings = context.read<SettingsController>();
    final Habit? habit = controller.byId(widget.habitId);

    if (habit == null) {
      return const ScreenShell(
        title: 'History',
        seed: 6,
        child: EmptyState(
          icon: AppIcons.calendar,
          title: 'Nothing to show',
          message: 'This orb no longer exists.',
        ),
      );
    }

    final OrbStats stats = controller.statsFor(habit);
    final Color accent = OrbArt.accent(habit.skin);
    final bool selectedDone = habit.isCompleteOn(_selected);
    final bool future = _selected.isAfter(DayKey.today());

    return ScreenShell(
      title: 'History',
      subtitle: habit.title,
      seed: 6,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            child: TableCalendar<void>(
              firstDay: DayKey.normalize(habit.createdAt)
                  .subtract(const Duration(days: 365)),
              lastDay: DayKey.today().add(const Duration(days: 365)),
              focusedDay: _focused,
              currentDay: DayKey.today(),
              startingDayOfWeek: settings.value.weekStartsMonday
                  ? StartingDayOfWeek.monday
                  : StartingDayOfWeek.sunday,
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppType.titleS(),
                leftChevronIcon: const Icon(AppIcons.caretLeft,
                    size: 17, color: AppPalette.textSecondary),
                rightChevronIcon: const Icon(AppIcons.caretRight,
                    size: 17, color: AppPalette.textSecondary),
                headerPadding: const EdgeInsets.only(bottom: 10),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppType.bodyS().copyWith(fontSize: 11),
                weekendStyle: AppType.bodyS().copyWith(fontSize: 11),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: AppType.bodyM(color: AppPalette.textSecondary),
                weekendTextStyle: AppType.bodyM(color: AppPalette.textSecondary),
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                ),
                todayTextStyle: AppType.bodyM(color: AppPalette.textPrimary),
                selectedDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.35),
                  border: Border.all(color: accent),
                ),
                selectedTextStyle: AppType.bodyM(color: Colors.white),
                disabledTextStyle: AppType.bodyS(),
              ),
              selectedDayPredicate: (DateTime d) => DayKey.isSameDay(d, _selected),
              onDaySelected: (DateTime selected, DateTime focused) {
                settings.tap();
                setState(() {
                  _selected = DayKey.normalize(selected);
                  _focused = focused;
                });
              },
              onPageChanged: (DateTime focused) => _focused = focused,
              calendarBuilders: CalendarBuilders<void>(
                defaultBuilder: (BuildContext context, DateTime day, _) =>
                    _DayCell(habit: habit, day: day, accent: accent),
                outsideBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SectionLabel('Selected day'),
          GlassPanel(
            radius: 24,
            child: Row(
              children: <Widget>[
                OrbView(
                  skin: habit.skin,
                  size: 46,
                  state: selectedDone ? OrbState.rolling : OrbState.waiting,
                  animated: selectedDone,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        DateFormat('EEEE, d MMMM').format(_selected),
                        style: AppType.titleS(),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        future
                            ? 'Still ahead of you'
                            : (habit.isScheduledOn(_selected)
                                ? (selectedDone
                                    ? 'Completed · ${habit.countOn(_selected)} ${habit.unit}s'
                                    : 'Scheduled but not logged')
                                : 'Not scheduled'),
                        style: AppType.bodyS(),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: selectedDone,
                  onChanged: future
                      ? null
                      : (bool v) {
                          settings.impact();
                          controller.setDayComplete(habit.id, _selected, v);
                        },
                ),
              ],
            ),
          ),
          const SectionLabel('This month'),
          _MonthSummary(habit: habit, month: _focused, stats: stats),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.habit, required this.day, required this.accent});

  final Habit habit;
  final DateTime day;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double ratio = habit.ratioOn(day);
    final bool scheduled = habit.isScheduledOn(day);
    final bool past = day.isBefore(DayKey.today());
    final bool missed = past && scheduled && ratio < 1;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ratio > 0
            ? accent.withValues(alpha: 0.2 + 0.55 * ratio)
            : (missed
                ? AppPalette.danger.withValues(alpha: 0.12)
                : Colors.transparent),
        border: missed
            ? Border.all(color: AppPalette.danger.withValues(alpha: 0.35))
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: AppType.bodyM(
            color: ratio > 0.5
                ? Colors.white
                : (scheduled ? AppPalette.textSecondary : AppPalette.textTertiary),
          ),
        ),
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.habit,
    required this.month,
    required this.stats,
  });

  final Habit habit;
  final DateTime month;
  final OrbStats stats;

  @override
  Widget build(BuildContext context) {
    final DateTime first = DateTime(month.year, month.month, 1);
    final DateTime last = DateTime(month.year, month.month + 1, 0);
    final DateTime today = DayKey.today();

    int scheduled = 0;
    int done = 0;
    for (DateTime d = first;
        !d.isAfter(last);
        d = d.add(const Duration(days: 1))) {
      if (d.isAfter(today)) break;
      if (!habit.isScheduledOn(d)) continue;
      scheduled++;
      if (habit.isCompleteOn(d)) done++;
    }

    return GlassPanel(
      radius: 24,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              StatTile(
                value: '$done',
                caption: 'completed',
                icon: AppIcons.checkCircle,
                valueSize: 20,
              ),
              StatTile(
                value: '${scheduled - done}',
                caption: 'missed',
                icon: AppIcons.closeCircle,
                tone: AppPalette.danger,
                valueSize: 20,
              ),
              StatTile(
                value: scheduled == 0
                    ? '—'
                    : '${((done / scheduled) * 100).round()}%',
                caption: 'rate',
                icon: AppIcons.target,
                valueSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AuroraBar(value: scheduled == 0 ? 0 : done / scheduled, height: 7),
        ],
      ),
    );
  }
}
