import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';

/// Storage transparency and the destructive actions, kept well away from
/// anything you might tap by accident.
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.watch<HabitController>();
    final TrailSummary summary = controller.summary;
    final int logged = controller.allHabits
        .fold<int>(0, (int s, Habit h) => s + h.progress.length);

    return ScreenShell(
      title: 'Data & storage',
      subtitle: 'Everything lives on this device',
      seed: 19,
      intensity: 0.55,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.all(20),
            gradient: AppPalette.auroraSoft,
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.success.withValues(alpha: 0.16),
                    border: Border.all(
                      color: AppPalette.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(AppIcons.hardDrive,
                      size: 24, color: AppPalette.success),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Local only', style: AppType.titleM()),
                      const SizedBox(height: 4),
                      Text(
                        'No account, no server, no analytics of your habits. '
                        'Uninstalling the app removes everything.',
                        style: AppType.bodyS(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('What is stored'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                _Row(label: 'Orbs', value: '${controller.allHabits.length}'),
                const Divider(height: 22),
                _Row(label: 'Logged days', value: '$logged'),
                const Divider(height: 22),
                _Row(label: 'Journal entries', value: '${controller.journal.length}'),
                const Divider(height: 22),
                _Row(label: 'Focus minutes', value: '${controller.focusMinutes}'),
                const Divider(height: 22),
                _Row(
                  label: 'Total distance',
                  value: '${summary.totalDistance.round()} m',
                ),
              ],
            ),
          ),
          const SectionLabel('Export'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SettingRow(
              icon: AppIcons.copy,
              title: 'Copy data as JSON',
              subtitle: 'Puts a full backup on your clipboard',
              onTap: () async {
                final String json = jsonEncode(<String, dynamic>{
                  'exportedAt': DateTime.now().toIso8601String(),
                  'habits': controller.allHabits
                      .map((Habit h) => h.toJson())
                      .toList(),
                  'journal': controller.journal,
                  'focusMinutes': controller.focusMinutes,
                });
                await Clipboard.setData(ClipboardData(text: json));
                if (!context.mounted) return;
                context.read<SettingsController>().success();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'Backup copied to clipboard.',
                        style: AppType.bodyM(color: AppPalette.textPrimary),
                      ),
                    ),
                  );
              },
            ),
          ),
          const SectionLabel('Danger zone'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            strokeColor: AppPalette.danger.withValues(alpha: 0.3),
            child: Column(
              children: <Widget>[
                SettingRow(
                  icon: AppIcons.undo,
                  title: 'Reset progress',
                  subtitle: 'Keeps your orbs, erases every logged day',
                  tone: AppPalette.warning,
                  onTap: () async {
                    final bool ok = await _confirm(
                      context,
                      'Reset all progress?',
                      'Your orbs stay, but every completion, streak, journal '
                          'entry and focus minute is erased. This cannot be undone.',
                    );
                    if (!ok || !context.mounted) return;
                    await controller.resetProgressOnly();
                    if (!context.mounted) return;
                    _toast(context, 'Progress reset.');
                  },
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.trash,
                  title: 'Delete everything',
                  subtitle: 'Removes all orbs and all history',
                  tone: AppPalette.danger,
                  onTap: () async {
                    final bool ok = await _confirm(
                      context,
                      'Delete everything?',
                      'Every orb, every logged day and every journal entry will '
                          'be gone. This cannot be undone.',
                    );
                    if (!ok || !context.mounted) return;
                    await controller.deleteEverything();
                    if (!context.mounted) return;
                    _toast(context, 'All data deleted.');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppType.bodyM(color: AppPalette.textPrimary),
          ),
        ),
      );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: AppType.bodyM()),
        Text(value, style: AppType.numeric(15)),
      ],
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
          child: Text('Delete', style: AppType.label(color: AppPalette.danger)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
