import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/habit_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import 'habit_detail_screen.dart';
import 'habit_editor_screen.dart';

/// Management view — reorder, archive and edit every orb in one place.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.watch<HabitController>();
    final List<Habit> active = controller.habits;
    final List<Habit> archived = controller.archivedHabits;

    return ScreenShell(
      title: 'Your orbs',
      subtitle: '${active.length} active · ${archived.length} archived',
      seed: 3,
      scrollable: false,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      actions: <Widget>[
        GlassIconButton(
          icon: AppIcons.plus,
          onPressed: () => pushScreen(context, const HabitEditorScreen()),
        ),
      ],
      child: active.isEmpty && archived.isEmpty
          ? EmptyState(
              icon: AppIcons.sphere,
              title: 'No orbs yet',
              message: 'Forge one and it will appear on your trail instantly.',
              action: AuroraButton(
                label: 'Forge an orb',
                icon: AppIcons.plus,
                expanded: false,
                onPressed: () => pushScreen(context, const HabitEditorScreen()),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: <Widget>[
                      AuroraChip(
                        label: 'Active',
                        selected: !_showArchived,
                        icon: AppIcons.circlesThree,
                        onTap: () => setState(() => _showArchived = false),
                      ),
                      const SizedBox(width: 8),
                      AuroraChip(
                        label: 'Archived',
                        selected: _showArchived,
                        icon: AppIcons.stack,
                        onTap: () => setState(() => _showArchived = true),
                      ),
                      const Spacer(),
                      if (!_showArchived && active.length > 1)
                        Text('hold to reorder', style: AppType.bodyS()),
                    ],
                  ),
                ),
                Expanded(
                  child: _showArchived
                      ? _ArchivedList(items: archived)
                      : _ActiveList(items: active),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

class _ActiveList extends StatelessWidget {
  const _ActiveList({required this.items});

  final List<Habit> items;

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.read<HabitController>();
    if (items.isEmpty) {
      return const EmptyState(
        icon: AppIcons.circleDashed,
        title: 'Nothing active',
        message: 'Every orb is archived. Restore one to bring it back.',
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      buildDefaultDragHandles: true,
      proxyDecorator: (Widget child, int index, Animation<double> animation) =>
          Material(color: Colors.transparent, child: child),
      itemCount: items.length,
      onReorderItem: controller.reorder,
      itemBuilder: (BuildContext context, int i) => Padding(
        key: ValueKey<String>(items[i].id),
        padding: const EdgeInsets.only(bottom: 10),
        child: _HabitRow(habit: items[i]),
      ),
    );
  }
}

class _ArchivedList extends StatelessWidget {
  const _ArchivedList({required this.items});

  final List<Habit> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: AppIcons.stack,
        title: 'Archive is empty',
        message: 'Orbs you retire will rest here without losing their history.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int i) =>
          _HabitRow(habit: items[i], archived: true),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, this.archived = false});

  final Habit habit;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final HabitController controller = context.read<HabitController>();
    final SettingsController settings = context.read<SettingsController>();
    final OrbStats stats = controller.statsFor(habit);
    final Color accent = OrbArt.accent(habit.skin);

    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      onTap: () => pushScreen(context, HabitDetailScreen(habitId: habit.id)),
      child: Row(
        children: <Widget>[
          Opacity(
            opacity: archived ? 0.45 : 1,
            child: OrbView(
              skin: habit.skin,
              state: archived ? OrbState.resting : stats.state,
              size: 44,
              momentum: stats.momentum,
              animated: !archived,
            ),
          ),
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
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Icon(
                      HabitIcons.resolveBold(habit.iconKey),
                      size: 12,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${stats.distance.round()} m  ·  ${(stats.completionRate * 100).round()}%'
                      '  ·  ${_scheduleLabel(habit)}',
                      style: AppType.bodyS().copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              AppIcons.more,
              size: 20,
              color: AppPalette.textTertiary,
            ),
            color: AppPalette.canvasOverlay,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppPalette.glassStroke),
            ),
            onSelected: (String action) async {
              settings.tap();
              switch (action) {
                case 'edit':
                  await pushScreen(context, HabitEditorScreen(habit: habit));
                case 'archive':
                  await controller.setArchived(habit.id, !archived);
                case 'delete':
                  if (!context.mounted) return;
                  final bool ok = await _confirmDelete(context, habit);
                  if (ok) await controller.remove(habit.id);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              _menuItem('edit', AppIcons.edit, 'Edit'),
              _menuItem(
                'archive',
                archived
                    ? AppIcons.undo
                    : AppIcons.stack,
                archived ? 'Restore' : 'Archive',
              ),
              _menuItem(
                'delete',
                AppIcons.trash,
                'Delete',
                tone: AppPalette.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color tone = AppPalette.textPrimary,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: tone),
          const SizedBox(width: 12),
          Text(label, style: AppType.bodyM(color: tone)),
        ],
      ),
    );
  }

  static String _scheduleLabel(Habit habit) {
    final int n = habit.scheduledWeekdays.length;
    if (n == 7) return 'daily';
    if (n == 5 &&
        habit.scheduledWeekdays.containsAll(<int>{1, 2, 3, 4, 5})) {
      return 'weekdays';
    }
    if (n == 2 && habit.scheduledWeekdays.containsAll(<int>{6, 7})) {
      return 'weekends';
    }
    return '$n×/week';
  }
}

Future<bool> _confirmDelete(BuildContext context, Habit habit) async {
  final bool needsConfirm =
      context.read<SettingsController>().value.confirmDeletion;
  if (!needsConfirm) return true;

  final bool? result = await showDialog<bool>(
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
  return result ?? false;
}
