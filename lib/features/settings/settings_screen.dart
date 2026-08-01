import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/app_settings.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../appearance/appearance_screen.dart';
import '../data/data_screen.dart';
import '../reminders/reminders_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    final HabitController habits = context.watch<HabitController>();
    final AppSettings s = controller.value;

    return ScreenShell(
      title: 'Settings',
      subtitle: 'Tune how the trail behaves',
      seed: 16,
      intensity: 0.6,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionLabel('Feel', padding: EdgeInsets.only(bottom: 12)),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: <Widget>[
                SettingRow(
                  icon: AppIcons.vibrate,
                  title: 'Haptics',
                  subtitle: 'Vibration when an orb moves',
                  trailing: Switch(
                    value: s.haptics,
                    onChanged: controller.setHaptics,
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.wind,
                  title: 'Reduce motion',
                  subtitle: 'Stop the ambient background animation',
                  trailing: Switch(
                    value: s.reduceMotion,
                    onChanged: controller.setReduceMotion,
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.sparkle,
                  title: 'Floating motes',
                  subtitle: 'Drifting particles over the trail scene',
                  trailing: Switch(
                    value: s.showParticles,
                    onChanged: controller.setShowParticles,
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.collapse,
                  title: 'Compact trail',
                  subtitle: 'A narrower path that fits more orbs on screen',
                  trailing: Switch(
                    value: s.compactTrail,
                    onChanged: controller.setCompactTrail,
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Behaviour'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: <Widget>[
                SettingRow(
                  icon: AppIcons.calendar,
                  title: 'Week starts on Monday',
                  subtitle: s.weekStartsMonday ? 'Monday first' : 'Sunday first',
                  trailing: Switch(
                    value: s.weekStartsMonday,
                    onChanged: controller.setWeekStartsMonday,
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.warning,
                  title: 'Confirm before deleting',
                  subtitle: 'Ask again before an orb is shattered for good',
                  trailing: Switch(
                    value: s.confirmDeletion,
                    onChanged: controller.setConfirmDeletion,
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.bell,
                  title: 'Daily nudges',
                  subtitle:
                      '${habits.habits.where((dynamic h) => h.reminderMinutes != null).length} orbs have a preferred time',
                  onTap: () => pushScreen(context, const RemindersScreen()),
                ),
              ],
            ),
          ),
          const SectionLabel('More'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: <Widget>[
                SettingRow(
                  icon: AppIcons.palette,
                  title: 'Appearance',
                  subtitle: 'Accent colour, environment',
                  onTap: () => pushScreen(context, const AppearanceScreen()),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.database,
                  title: 'Data & storage',
                  subtitle: 'Reset progress or wipe everything',
                  onTap: () => pushScreen(context, const DataScreen()),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.undo,
                  title: 'Restore defaults',
                  subtitle: 'Settings only — your orbs stay untouched',
                  onTap: () async {
                    final bool ok = await _confirm(
                      context,
                      'Restore default settings?',
                      'Accent colour, environment and toggles go back to how '
                          'they shipped. Your habits are not affected.',
                    );
                    if (!ok) return;
                    await controller.resetToDefaults();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GlassPanel(
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                const Icon(AppIcons.wifiOff,
                    size: 20, color: AppPalette.success),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Orb Tumble Trail works fully offline. Nothing you log ever '
                    'leaves this device.',
                    style: AppType.bodyS(color: AppPalette.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(body, style: AppType.bodyM()),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: AppType.label()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Confirm',
            style: AppType.label(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    ),
  );
  return ok ?? false;
}
