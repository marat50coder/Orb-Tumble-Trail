import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';

/// A single-purpose timer. One orb, one number, nothing else — the quietest
/// screen in the app on purpose.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const List<int> _presets = <int>[10, 15, 25, 45, 60];

  int _minutes = 25;
  int _remaining = 25 * 60;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress =>
      _minutes == 0 ? 0 : 1 - (_remaining / (_minutes * 60));

  String get _clock {
    final int m = _remaining ~/ 60;
    final int s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _select(int minutes) {
    if (_running) return;
    setState(() {
      _minutes = minutes;
      _remaining = minutes * 60;
    });
  }

  void _toggle() {
    context.read<SettingsController>().impact();
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_remaining <= 1) {
        t.cancel();
        _complete();
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _reset() {
    _timer?.cancel();
    context.read<SettingsController>().tap();
    setState(() {
      _running = false;
      _remaining = _minutes * 60;
    });
  }

  Future<void> _complete() async {
    setState(() {
      _running = false;
      _remaining = 0;
    });
    final HabitController habits = context.read<HabitController>();
    context.read<SettingsController>().success();
    await habits.addFocusMinutes(_minutes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Session complete — $_minutes focused minutes banked.',
            style: AppType.bodyM(color: AppPalette.textPrimary),
          ),
        ),
      );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _remaining = _minutes * 60);
  }

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final Color accent = Theme.of(context).colorScheme.primary;

    return ScreenShell(
      title: 'Focus',
      subtitle: '${habits.focusMinutes} minutes banked so far',
      seed: 7,
      intensity: 0.6,
      scrollable: false,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: Column(
        children: <Widget>[
          const Spacer(),
          SizedBox(
            height: 300,
            width: 300,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ProgressRing(
                  value: _progress,
                  size: 300,
                  stroke: 4,
                  colors: <Color>[accent, AppPalette.auroraMagenta],
                ),
                Opacity(
                  opacity: 0.32,
                  child: OrbView(
                    skin: OrbSkin.purple,
                    size: 210,
                    momentum: _running ? 1 : 0.3,
                    animated: _running,
                    spin: _running,
                    showGlow: false,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(_clock, style: AppType.numeric(58)),
                    const SizedBox(height: 8),
                    Text(
                      _running ? 'ROLLING' : 'PAUSED',
                      style: AppType.overline(
                        color: _running ? accent : AppPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final int m in _presets)
                AuroraChip(
                  label: '$m min',
                  selected: m == _minutes,
                  onTap: _running ? null : () => _select(m),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              GlassIconButton(
                icon: AppIcons.refresh,
                size: 56,
                onPressed: _reset,
                tooltip: 'Reset',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuroraButton(
                  label: _running ? 'Pause' : 'Start rolling',
                  icon: _running
                      ? AppIcons.pause
                      : AppIcons.play,
                  onPressed: _toggle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                const Icon(AppIcons.info,
                    size: 18, color: AppPalette.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Focused minutes feed your Journey stats. The timer keeps '
                    'running while this screen is open.',
                    style: AppType.bodyS(),
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
