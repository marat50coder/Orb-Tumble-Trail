import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';

/// Preferred times for each orb. Times drive the ordering of the Today list —
/// the app never sends anything and never touches the network.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.watch<HabitController>();
    final List<Habit> habits = controller.habits.toList()
      ..sort((Habit a, Habit b) =>
          (a.reminderMinutes ?? 1441).compareTo(b.reminderMinutes ?? 1441));

    return ScreenShell(
      title: 'Daily rhythm',
      subtitle: 'When each orb wants your attention',
      seed: 18,
      intensity: 0.6,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: habits.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: 60),
              child: EmptyState(
                icon: AppIcons.alarm,
                title: 'No orbs to schedule',
                message: 'Forge an orb first and its preferred time appears here.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GlassPanel(
                  radius: 22,
                  child: Row(
                    children: <Widget>[
                      const Icon(AppIcons.info,
                          size: 20, color: AppPalette.info),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'A time sorts the orb higher in Today. Orbs without a '
                          'time sit at the bottom of the list.',
                          style: AppType.bodyS(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Timeline'),
                for (final Habit h in habits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReminderRow(habit: h),
                  ),
              ],
            ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.habit});

  final Habit habit;

  String get _time {
    final int? m = habit.reminderMinutes;
    if (m == null) return '—';
    return '${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.read<HabitController>();
    final SettingsController settings = context.read<SettingsController>();
    final Color accent = OrbArt.accent(habit.skin);
    final bool set = habit.reminderMinutes != null;

    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: () async {
        settings.tap();
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: set
              ? TimeOfDay(
                  hour: habit.reminderMinutes! ~/ 60,
                  minute: habit.reminderMinutes! % 60,
                )
              : const TimeOfDay(hour: 8, minute: 0),
        );
        if (picked == null) return;
        await controller.saveHabit(
          habit.copyWith(reminderMinutes: picked.hour * 60 + picked.minute),
        );
      },
      child: Row(
        children: <Widget>[
          OrbView(skin: habit.skin, size: 40, momentum: 0.8),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.titleS(),
                ),
                const SizedBox(height: 3),
                Text(
                  set ? 'Sorted first around $_time' : 'Any time of day',
                  style: AppType.bodyS(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: set ? accent.withValues(alpha: 0.16) : AppPalette.glassFill,
              border: Border.all(
                color: set
                    ? accent.withValues(alpha: 0.45)
                    : AppPalette.glassStroke,
              ),
            ),
            child: Text(
              _time,
              style: AppType.numeric(
                14,
                color: set ? accent : AppPalette.textTertiary,
              ),
            ),
          ),
          if (set)
            IconButton(
              icon: const Icon(AppIcons.close,
                  size: 15, color: AppPalette.textTertiary),
              onPressed: () {
                settings.tap();
                controller.saveHabit(habit.copyWith(clearReminder: true));
              },
            ),
        ],
      ),
    );
  }
}
