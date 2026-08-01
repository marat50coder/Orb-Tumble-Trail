import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';

class _Milestone {
  const _Milestone(this.distance, this.name, this.blurb);
  final double distance;
  final String name;
  final String blurb;
}

/// A vertical timeline. The only screen in the app built around a spine line,
/// which is what makes it read as a journey rather than a list.
class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  static const List<_Milestone> _stops = <_Milestone>[
    _Milestone(0, 'Trailhead', 'Where every orb starts its life.'),
    _Milestone(250, 'First Waypoint', 'The habit is no longer a novelty.'),
    _Milestone(750, 'Mossy Bridge', 'Momentum begins to carry itself.'),
    _Milestone(1500, 'Lantern Pass', 'A month of steady rolling, roughly.'),
    _Milestone(3000, 'Cloud Ridge', 'The habit now belongs to you.'),
    _Milestone(5000, 'Aurora Gate', 'Rare air. Very few orbs reach this far.'),
    _Milestone(10000, 'The Summit', 'Ten kilometres of accumulated discipline.'),
  ];

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final TrailSummary summary = habits.summary;
    final double total = summary.totalDistance;

    return ScreenShell(
      title: 'Milestones',
      subtitle: '${total.round()} m along the trail',
      seed: 14,
      intensity: 0.7,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _current(total).name,
                        style: AppType.titleM(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _next(total) == null
                            ? 'You have reached the summit.'
                            : '${(_next(total)!.distance - total).round()} m to '
                                '${_next(total)!.name}',
                        style: AppType.bodyS(),
                      ),
                    ],
                  ),
                ),
                ProgressRing(
                  value: _segmentProgress(total),
                  size: 70,
                  stroke: 6,
                  center: Text(
                    '${(_segmentProgress(total) * 100).round()}%',
                    style: AppType.numeric(13),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('The route'),
          for (int i = 0; i < _stops.length; i++)
            _TimelineTile(
              stop: _stops[i],
              reached: total >= _stops[i].distance,
              isLast: i == _stops.length - 1,
              progress: i + 1 < _stops.length
                  ? ((total - _stops[i].distance) /
                          (_stops[i + 1].distance - _stops[i].distance))
                      .clamp(0.0, 1.0)
                  : (total >= _stops[i].distance ? 1.0 : 0.0),
            ).animate().fadeIn(delay: (60 * i).ms, duration: 320.ms),
          const SectionLabel('Leading orbs'),
          _Leaders(orbs: summary.orbs),
        ],
      ),
    );
  }

  static _Milestone _current(double total) {
    _Milestone current = _stops.first;
    for (final _Milestone m in _stops) {
      if (total >= m.distance) current = m;
    }
    return current;
  }

  static _Milestone? _next(double total) {
    for (final _Milestone m in _stops) {
      if (total < m.distance) return m;
    }
    return null;
  }

  static double _segmentProgress(double total) {
    final _Milestone current = _current(total);
    final _Milestone? next = _next(total);
    if (next == null) return 1;
    return ((total - current.distance) / (next.distance - current.distance))
        .clamp(0.0, 1.0);
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.stop,
    required this.reached,
    required this.isLast,
    required this.progress,
  });

  final _Milestone stop;
  final bool reached;
  final bool isLast;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Column(
              children: <Widget>[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? accent : Colors.transparent,
                    border: Border.all(
                      color: reached ? accent : AppPalette.glassStrokeStrong,
                      width: 2,
                    ),
                    boxShadow: <BoxShadow>[
                      if (reached)
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 14,
                        ),
                    ],
                  ),
                  child: reached
                      ? const Icon(AppIcons.check,
                          size: 11, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          Container(width: 2, color: AppPalette.glassFillStrong),
                          FractionallySizedBox(
                            heightFactor: progress,
                            child: Container(width: 2, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: GlassPanel(
                radius: 20,
                padding: const EdgeInsets.all(15),
                strong: reached,
                strokeColor: reached ? accent.withValues(alpha: 0.4) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            stop.name,
                            style: AppType.titleS(
                              color: reached
                                  ? AppPalette.textPrimary
                                  : AppPalette.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          stop.distance >= 1000
                              ? '${(stop.distance / 1000).toStringAsFixed(0)} km'
                              : '${stop.distance.round()} m',
                          style: AppType.numeric(
                            12,
                            color: reached ? accent : AppPalette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(stop.blurb, style: AppType.bodyS()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leaders extends StatelessWidget {
  const _Leaders({required this.orbs});

  final List<OrbStats> orbs;

  @override
  Widget build(BuildContext context) {
    if (orbs.isEmpty) {
      return const EmptyState(
        icon: AppIcons.flag,
        title: 'Nobody on the route',
        message: 'Forge an orb and it will start collecting checkpoints.',
      );
    }

    final List<OrbStats> sorted = orbs.toList()
      ..sort((OrbStats a, OrbStats b) => b.distance.compareTo(a.distance));

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < sorted.length; i++) ...<Widget>[
            Row(
              children: <Widget>[
                OrbView(
                  skin: sorted[i].habit.skin,
                  state: sorted[i].state,
                  size: 34,
                  momentum: sorted[i].momentum,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    sorted[i].habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodyM(color: AppPalette.textPrimary),
                  ),
                ),
                Text(
                  '${sorted[i].distance.round()} m',
                  style: AppType.numeric(13, color: OrbArt.accent(sorted[i].habit.skin)),
                ),
              ],
            ),
            if (i != sorted.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Divider(),
              ),
          ],
        ],
      ),
    );
  }
}
