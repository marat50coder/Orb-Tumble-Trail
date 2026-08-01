import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/habit_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_preset.dart';
import '../../data/services/notification_service.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';

class HabitEditorScreen extends StatefulWidget {
  const HabitEditorScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends State<HabitEditorScreen> {
  late final TextEditingController _title =
      TextEditingController(text: widget.habit?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.habit?.description ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.habit?.unit ?? 'time');

  late OrbSkin _skin = widget.habit?.skin ?? OrbSkin.purple;
  late String _iconKey = widget.habit?.iconKey ?? 'sparkle';
  late int _target = widget.habit?.dailyTarget ?? 1;
  late HabitKind _kind = widget.habit?.kind ?? HabitKind.build;
  late Set<int> _weekdays =
      <int>{...(widget.habit?.scheduledWeekdays ?? const <int>{1, 2, 3, 4, 5, 6, 7})};
  late TimeOfDay? _reminder = widget.habit?.reminderMinutes == null
      ? null
      : TimeOfDay(
          hour: widget.habit!.reminderMinutes! ~/ 60,
          minute: widget.habit!.reminderMinutes! % 60,
        );

  bool get _isEdit => widget.habit != null;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _unit.dispose();
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty && _weekdays.isNotEmpty;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);

    final HabitController controller = context.read<HabitController>();
    final int? minutes =
        _reminder == null ? null : _reminder!.hour * 60 + _reminder!.minute;

    if (minutes != null) {
      await NotificationService.instance.requestPermissions();
    }

    if (_isEdit) {
      await controller.saveHabit(
        widget.habit!.copyWith(
          title: _title.text,
          description: _description.text,
          skin: _skin,
          iconKey: _iconKey,
          dailyTarget: _target,
          unit: _unit.text.trim().isEmpty ? 'time' : _unit.text.trim(),
          kind: _kind,
          scheduledWeekdays: _weekdays,
          reminderMinutes: minutes,
          clearReminder: minutes == null,
        ),
      );
    } else {
      await controller.create(
        title: _title.text,
        description: _description.text,
        skin: _skin,
        iconKey: _iconKey,
        dailyTarget: _target,
        unit: _unit.text.trim().isEmpty ? 'time' : _unit.text.trim(),
        kind: _kind,
        weekdays: _weekdays,
        reminderMinutes: minutes,
      );
    }

    if (!mounted) return;
    context.read<SettingsController>().success();
    Navigator.of(context).pop();
  }

  void _applyPreset(HabitPreset preset) {
    setState(() {
      _title.text = preset.title;
      _description.text = preset.description;
      _iconKey = preset.iconKey;
      _skin = preset.skin;
      _target = preset.dailyTarget;
      _unit.text = preset.unit;
      _kind = preset.kind;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: _isEdit ? 'Shape the orb' : 'Forge an orb',
      subtitle: _isEdit ? widget.habit!.title : 'A new habit joins the trail',
      seed: 4,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      floating: AuroraButton(
        label: _isEdit ? 'Save changes' : 'Add to trail',
        icon: AppIcons.check,
        busy: _saving,
        onPressed: _valid ? _save : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Preview(
            skin: _skin,
            iconKey: _iconKey,
            title: _title.text.trim().isEmpty ? 'New orb' : _title.text.trim(),
            target: _target,
            unit: _unit.text,
          ),
          if (!_isEdit) ...<Widget>[
            const SectionLabel('Start from a template'),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: HabitPresets.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int i) {
                  final HabitPreset p = HabitPresets.all[i];
                  return AuroraChip(
                    label: p.title,
                    icon: HabitIcons.resolveBold(p.iconKey),
                    color: OrbArt.accent(p.skin),
                    selected: _title.text == p.title,
                    onTap: () => _applyPreset(p),
                  );
                },
              ),
            ),
          ],
          const SectionLabel('Identity'),
          GlassPanel(
            radius: 24,
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppType.titleS(),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Drink water',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLines: 2,
                  minLines: 1,
                  style: AppType.bodyM(color: AppPalette.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Why it matters (optional)',
                    hintText: 'Keeps every other orb rolling faster',
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Orb skin'),
          Row(
            children: <Widget>[
              for (final OrbSkin skin in OrbSkin.values) ...<Widget>[
                Expanded(
                  child: _SkinTile(
                    skin: skin,
                    selected: skin == _skin,
                    onTap: () => setState(() => _skin = skin),
                  ),
                ),
                if (skin != OrbSkin.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SectionLabel('Glyph'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final String key in HabitIcons.keys)
                  _IconChoice(
                    iconKey: key,
                    selected: key == _iconKey,
                    accent: OrbArt.accent(_skin),
                    onTap: () => setState(() => _iconKey = key),
                  ),
              ],
            ),
          ),
          const SectionLabel('Rhythm'),
          GlassPanel(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _KindSwitch(
                  kind: _kind,
                  onChanged: (HabitKind k) => setState(() => _kind = k),
                ),
                const SizedBox(height: 18),
                _TargetStepper(
                  value: _target,
                  unit: _unit,
                  onChanged: (int v) => setState(() => _target = v),
                  onUnitChanged: () => setState(() {}),
                ),
                const SizedBox(height: 18),
                _WeekdayPicker(
                  selected: _weekdays,
                  onChanged: (Set<int> days) => setState(() => _weekdays = days),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                SettingRow(
                  icon: AppIcons.alarm,
                  title: 'Daily nudge',
                  subtitle: _reminder == null
                      ? 'No preferred time'
                      : 'Sorted first around ${_reminder!.format(context)}',
                  trailing: _reminder == null
                      ? null
                      : GlassIconButton(
                          icon: AppIcons.close,
                          size: 34,
                          onPressed: () => setState(() => _reminder = null),
                        ),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _reminder ?? const TimeOfDay(hour: 8, minute: 0),
                      builder: (BuildContext context, Widget? child) =>
                          Theme(data: Theme.of(context), child: child!),
                    );
                    if (picked != null) setState(() => _reminder = picked);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.skin,
    required this.iconKey,
    required this.title,
    required this.target,
    required this.unit,
  });

  final OrbSkin skin;
  final String iconKey;
  final String title;
  final int target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final Color accent = OrbArt.accent(skin);
    return GlassPanel(
      radius: 28,
      padding: const EdgeInsets.symmetric(vertical: 26),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      child: Column(
        children: <Widget>[
          OrbView(skin: skin, size: 104, momentum: 1, spin: true)
              .animate(key: ValueKey<OrbSkin>(skin))
              .fadeIn(duration: 320.ms)
              .scaleXY(begin: 0.85, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(HabitIcons.resolve(iconKey), size: 18, color: accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: AppType.titleM(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            target > 1 ? '$target $unit${target > 1 ? 's' : ''} a day' : 'Once a day',
            style: AppType.bodyS(),
          ),
        ],
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final OrbSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = OrbArt.accent(skin);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? accent.withValues(alpha: 0.16) : AppPalette.glassFill,
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.7) : AppPalette.glassStroke,
          ),
        ),
        child: Column(
          children: <Widget>[
            OrbView(skin: skin, size: 42, animated: selected, momentum: selected ? 1 : 0.4),
            const SizedBox(height: 8),
            Text(
              OrbArt.label(skin),
              style: AppType.bodyS(
                color: selected ? AppPalette.textPrimary : AppPalette.textTertiary,
              ).copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? accent.withValues(alpha: 0.2) : AppPalette.glassFill,
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.75) : AppPalette.glassStroke,
          ),
        ),
        child: Icon(
          HabitIcons.resolve(iconKey),
          size: 21,
          color: selected ? accent : AppPalette.textSecondary,
        ),
      ),
    );
  }
}

class _KindSwitch extends StatelessWidget {
  const _KindSwitch({required this.kind, required this.onChanged});

  final HabitKind kind;
  final ValueChanged<HabitKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _KindTile(
            label: 'Build',
            caption: 'Do it',
            icon: AppIcons.plusCircle,
            selected: kind == HabitKind.build,
            tone: AppPalette.success,
            onTap: () => onChanged(HabitKind.build),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KindTile(
            label: 'Break',
            caption: 'Avoid it',
            icon: AppIcons.block,
            selected: kind == HabitKind.quit,
            tone: AppPalette.danger,
            onTap: () => onChanged(HabitKind.quit),
          ),
        ),
      ],
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? tone.withValues(alpha: 0.14) : AppPalette.glassFill,
          border: Border.all(
            color: selected ? tone.withValues(alpha: 0.6) : AppPalette.glassStroke,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: selected ? tone : AppPalette.textTertiary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: AppType.titleS()),
                Text(caption, style: AppType.bodyS().copyWith(fontSize: 10.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetStepper extends StatelessWidget {
  const _TargetStepper({
    required this.value,
    required this.unit,
    required this.onChanged,
    required this.onUnitChanged,
  });

  final int value;
  final TextEditingController unit;
  final ValueChanged<int> onChanged;
  final VoidCallback onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Daily target', style: AppType.titleS()),
              const SizedBox(height: 3),
              Text('How many taps close the day', style: AppType.bodyS()),
            ],
          ),
        ),
        _StepButton(
          icon: AppIcons.minus,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppType.numeric(20),
          ),
        ),
        _StepButton(
          icon: AppIcons.plus,
          onTap: value < 50 ? () => onChanged(value + 1) : null,
        ),
        if (value > 1) ...<Widget>[
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: TextField(
              controller: unit,
              onChanged: (_) => onUnitChanged(),
              textAlign: TextAlign.center,
              style: AppType.bodyM(color: AppPalette.textPrimary),
              decoration: const InputDecoration(
                hintText: 'unit',
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: GlassIconButton(icon: icon, size: 38, onPressed: onTap),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  static const List<String> _labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Repeat on', style: AppType.titleS()),
            const Spacer(),
            _quick(context, 'All', <int>{1, 2, 3, 4, 5, 6, 7}),
            const SizedBox(width: 6),
            _quick(context, 'Week', <int>{1, 2, 3, 4, 5}),
            const SizedBox(width: 6),
            _quick(context, 'Wknd', <int>{6, 7}),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            for (int d = 1; d <= 7; d++) ...<Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final Set<int> next = <int>{...selected};
                    if (!next.remove(d)) next.add(d);
                    if (next.isNotEmpty) onChanged(next);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: selected.contains(d)
                          ? accent.withValues(alpha: 0.2)
                          : AppPalette.glassFill,
                      border: Border.all(
                        color: selected.contains(d)
                            ? accent.withValues(alpha: 0.7)
                            : AppPalette.glassStroke,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _labels[d - 1],
                        style: AppType.label(
                          color: selected.contains(d)
                              ? AppPalette.textPrimary
                              : AppPalette.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (d != 7) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  Widget _quick(BuildContext context, String label, Set<int> days) {
    return GestureDetector(
      onTap: () => onChanged(days),
      child: Text(
        label,
        style: AppType.bodyS(
          color: setEquals(selected, days)
              ? Theme.of(context).colorScheme.primary
              : AppPalette.textTertiary,
        ).copyWith(fontSize: 11),
      ),
    );
  }

  static bool setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
