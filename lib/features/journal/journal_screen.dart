import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/screen_shell.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';

/// Free-form notes tied to a date. Editorial layout — wide text, no cards
/// around the writing area, so it feels like paper rather than a form.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _text = TextEditingController();
  DateTime _day = DayKey.today();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _load() {
    _text.text = context.read<HabitController>().noteFor(_day) ?? '';
    setState(() => _dirty = false);
  }

  Future<void> _save() async {
    await context.read<HabitController>().saveNote(_day, _text.text);
    if (!mounted) return;
    context.read<SettingsController>().success();
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Entry saved.',
            style: AppType.bodyM(color: AppPalette.textPrimary),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final Map<String, String> entries = habits.journal;
    final List<String> keys = entries.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));

    return ScreenShell(
      title: 'Journal',
      subtitle: '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
      seed: 8,
      intensity: 0.7,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      actions: <Widget>[
        if (_dirty)
          GlassIconButton(
            icon: AppIcons.check,
            onPressed: _save,
            tooltip: 'Save',
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      DateFormat('EEEE').format(_day),
                      style: AppType.displayM(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMMM yyyy').format(_day),
                      style: AppType.bodyS(),
                    ),
                  ],
                ),
              ),
              GlassIconButton(
                icon: AppIcons.caretLeft,
                size: 40,
                onPressed: () {
                  setState(() => _day = _day.subtract(const Duration(days: 1)));
                  _load();
                },
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: AppIcons.caretRight,
                size: 40,
                onPressed: DayKey.isSameDay(_day, DayKey.today())
                    ? null
                    : () {
                        setState(() => _day = _day.add(const Duration(days: 1)));
                        _load();
                      },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: AppPalette.glassStroke),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: TextField(
              controller: _text,
              maxLines: 9,
              minLines: 7,
              onChanged: (_) {
                if (!_dirty) setState(() => _dirty = true);
              },
              style: AppType.bodyL(color: AppPalette.textPrimary)
                  .copyWith(height: 1.65),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: 'How did the trail feel today?',
                hintStyle: AppType.bodyL(color: AppPalette.textTertiary),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AuroraButton(
            label: 'Save entry',
            icon: AppIcons.check,
            onPressed: _dirty ? _save : null,
          ),
          if (keys.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: AppIcons.editNote,
                title: 'Blank pages',
                message: 'Nothing written yet. Today is a good place to start.',
              ),
            )
          else ...<Widget>[
            const SectionLabel('Earlier entries'),
            for (int i = 0; i < keys.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EntryCard(
                  day: DayKey.parse(keys[i]),
                  text: entries[keys[i]]!,
                  onTap: () {
                    setState(() => _day = DayKey.parse(keys[i]));
                    _load();
                  },
                ).animate().fadeIn(delay: (40 * i).ms, duration: 280.ms),
              ),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.day,
    required this.text,
    required this.onTap,
  });

  final DateTime day;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                DateFormat('d MMM yyyy').format(day).toUpperCase(),
                style: AppType.overline(),
              ),
              const Spacer(),
              Text(
                DateFormat('EEE').format(day),
                style: AppType.bodyS().copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppType.bodyM(color: AppPalette.textSecondary),
          ),
        ],
      ),
    );
  }
}
