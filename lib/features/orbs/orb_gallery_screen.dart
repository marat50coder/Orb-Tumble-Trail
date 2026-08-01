import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';
import '../habits/habit_detail_screen.dart';

/// A showcase rather than a list: big artwork, one orb per card, with the
/// lore of each skin and how each state looks.
class OrbGalleryScreen extends StatelessWidget {
  const OrbGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final List<OrbStats> orbs = habits.summary.orbs;

    return ScreenShell(
      title: 'Orb gallery',
      subtitle: '${orbs.length} in the fleet · 4 skins · 5 states',
      seed: 13,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (orbs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30, bottom: 20),
              child: EmptyState(
                icon: AppIcons.sphere,
                title: 'Empty fleet',
                message: 'Your orbs will be displayed here once you forge them.',
              ),
            )
          else ...<Widget>[
            const SectionLabel('Your fleet', padding: EdgeInsets.only(bottom: 12)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: orbs.length,
              itemBuilder: (BuildContext context, int i) => _OrbCard(stats: orbs[i])
                  .animate()
                  .fadeIn(delay: (50 * i).ms, duration: 320.ms)
                  .scaleXY(begin: 0.94, curve: Curves.easeOutCubic),
            ),
          ],
          const SectionLabel('Skins'),
          for (final OrbSkin skin in OrbSkin.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkinRow(skin: skin, count: orbs
                  .where((OrbStats o) => o.habit.skin == skin)
                  .length),
            ),
          const SectionLabel('States'),
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                for (final OrbState state in OrbState.values) ...<Widget>[
                  _StateRow(state: state),
                  if (state != OrbState.values.last)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbCard extends StatelessWidget {
  const _OrbCard({required this.stats});

  final OrbStats stats;

  @override
  Widget build(BuildContext context) {
    final Color accent = OrbArt.accent(stats.habit.skin);
    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      onTap: () =>
          pushScreen(context, HabitDetailScreen(habitId: stats.habit.id)),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: OrbView(
                skin: stats.habit.skin,
                state: stats.state,
                size: 82,
                momentum: stats.momentum,
                spin: stats.state == OrbState.rolling,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stats.habit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.titleS(),
          ),
          const SizedBox(height: 3),
          Text(
            '${stats.distance.round()} m · ${OrbArt.label(stats.habit.skin)}',
            style: AppType.bodyS().copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          AuroraBar(
            value: stats.progressToNextCheckpoint,
            height: 4,
            gradient: LinearGradient(
              colors: <Color>[accent, AppPalette.auroraMagenta],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinRow extends StatelessWidget {
  const _SkinRow({required this.skin, required this.count});

  final OrbSkin skin;
  final int count;

  static String _lore(OrbSkin skin) => switch (skin) {
        OrbSkin.green => 'Light and quick. Best for habits you repeat often.',
        OrbSkin.orange => 'Burns hot. Suits work and effort you have to push into.',
        OrbSkin.purple => 'Quiet and deep. Made for mind, rest and reflection.',
        OrbSkin.red => 'Heavy. Use it for the habit that changes everything else.',
      };

  @override
  Widget build(BuildContext context) {
    final Color accent = OrbArt.accent(skin);
    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          OrbView(skin: skin, size: 48, momentum: 1),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(OrbArt.label(skin), style: AppType.titleS(color: accent)),
                    const Spacer(),
                    Text(
                      count == 0 ? 'unused' : '$count in use',
                      style: AppType.bodyS().copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_lore(skin), style: AppType.bodyS()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateRow extends StatelessWidget {
  const _StateRow({required this.state});

  final OrbState state;

  static String _title(OrbState s) => switch (s) {
        OrbState.rolling => 'Rolling',
        OrbState.waiting => 'Waiting',
        OrbState.resting => 'Resting',
        OrbState.slipping => 'Slipping',
        OrbState.shattered => 'Shattered',
      };

  static String _body(OrbState s) => switch (s) {
        OrbState.rolling => 'Completed today — full colour, spinning, glowing.',
        OrbState.waiting => 'Scheduled today, still untouched. Dimmed.',
        OrbState.resting => 'Not scheduled today. Turns to stone until its next day.',
        OrbState.slipping => 'One or two missed days. Colour drains away.',
        OrbState.shattered => 'Three misses in a row. Cracks open — one completion reforges it.',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        OrbView(
          skin: OrbSkin.purple,
          state: state,
          size: 44,
          momentum: state == OrbState.rolling ? 1 : 0.3,
          animated: state == OrbState.rolling,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_title(state), style: AppType.titleS()),
              const SizedBox(height: 3),
              Text(_body(state), style: AppType.bodyS()),
            ],
          ),
        ),
      ],
    );
  }
}
