import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/habit_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/achievement.dart';
import '../../data/models/orb_stats.dart';
import '../../data/models/player_progress.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../achievements/achievements_screen.dart';
import '../focus/focus_screen.dart';
import '../journal/journal_screen.dart';
import '../milestones/milestones_screen.dart';
import '../orbs/orb_gallery_screen.dart';
import '../quests/quests_screen.dart';

/// Hub tab: how far the whole trail has come, and where to go next.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final SettingsController settings = context.watch<SettingsController>();
    final TrailSummary summary = habits.summary;
    final Color accent = Theme.of(context).colorScheme.primary;
    final List<Achievement> unlocked = habits.unlockedAchievements;

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      extendBody: true,
      body: AuroraBackdrop(
        accent: accent,
        animated: !settings.value.reduceMotion,
        seed: 11,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: <Widget>[
              Text('Journey', style: AppType.displayM()),
              const SizedBox(height: 3),
              Text('Everything you have covered so far', style: AppType.bodyS()),
              const SizedBox(height: 20),
              _JourneyHero(summary: summary, focusMinutes: habits.focusMinutes),
              const SizedBox(height: 12),
              _QuestBanner(
                progress: habits.progress,
                claimable: habits.todayQuests
                    .where((QuestProgress q) => q.claimable)
                    .length,
              ),
              const SectionLabel('Explore'),
              _Tiles(
                unlocked: unlocked.length,
                total: AchievementCatalog.all.length,
                orbCount: summary.orbs.length,
              ),
              const SectionLabel('Recent badges'),
              if (unlocked.isEmpty)
                GlassPanel(
                  radius: 22,
                  child: Row(
                    children: <Widget>[
                      const Icon(AppIcons.medal,
                          size: 22, color: AppPalette.textTertiary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'No badges yet. The first one lands the moment an orb rolls.',
                          style: AppType.bodyM(color: AppPalette.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: unlocked.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int i) => _BadgeChip(
                      achievement: unlocked[unlocked.length - 1 - i],
                    ).animate().fadeIn(delay: (50 * i).ms, duration: 300.ms),
                  ),
                ),
              const SectionLabel('Fleet'),
              _Fleet(orbs: summary.orbs),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({required this.summary, required this.focusMinutes});

  final TrailSummary summary;
  final int focusMinutes;

  @override
  Widget build(BuildContext context) {
    final int checkpoints = summary.orbs
        .fold<int>(0, (int s, OrbStats o) => s + o.checkpointsReached);
    final double km = summary.totalDistance / 1000;

    return GlassPanel(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      gradient: AppPalette.auroraSoft,
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                km >= 1
                    ? km.toStringAsFixed(2)
                    : summary.totalDistance.round().toString(),
                style: AppType.numeric(46),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(km >= 1 ? 'km' : 'm', style: AppType.titleM()),
              ),
              const Spacer(),
              const Icon(AppIcons.path,
                  size: 34, color: AppPalette.textSecondary),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('rolled across the whole trail', style: AppType.bodyS()),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              StatTile(
                value: '$checkpoints',
                caption: 'checkpoints',
                icon: AppIcons.flag,
                valueSize: 20,
              ),
              StatTile(
                value: '${summary.perfectDays}',
                caption: 'flawless days',
                icon: AppIcons.sparkle,
                tone: AppPalette.warning,
                valueSize: 20,
              ),
              StatTile(
                value: '${summary.totalCompletions}',
                caption: 'completions',
                icon: AppIcons.checkCircle,
                tone: AppPalette.success,
                valueSize: 20,
              ),
              StatTile(
                value: '$focusMinutes',
                caption: 'focus min',
                icon: AppIcons.timer,
                tone: AppPalette.info,
                valueSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestBanner extends StatelessWidget {
  const _QuestBanner({required this.progress, required this.claimable});

  final PlayerProgress progress;
  final int claimable;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(16),
      onTap: () => pushScreen(context, const QuestsScreen()),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[accent, AppPalette.auroraMagenta],
              ),
            ),
            child: Text('${progress.level}',
                style: AppType.numeric(20, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('Quests', style: AppType.titleS()),
                    if (claimable > 0) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppPalette.warning.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text('$claimable ready',
                            style: AppType.bodyS(color: AppPalette.warning)
                                .copyWith(fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                AuroraBar(value: progress.levelProgress, height: 7),
                const SizedBox(height: 5),
                Text(
                  '${progress.rank} \u2022 ${progress.shieldsAvailable} shields',
                  style: AppType.bodyS().copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(AppIcons.caretRight,
              size: 15, color: AppPalette.textTertiary),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({
    required this.unlocked,
    required this.total,
    required this.orbCount,
  });

  final int unlocked;
  final int total;
  final int orbCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _BigTile(
                icon: AppIcons.medal,
                title: 'Achievements',
                caption: '$unlocked of $total unlocked',
                onTap: () => pushScreen(context, const AchievementsScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigTile(
                icon: AppIcons.sphere,
                title: 'Orb gallery',
                caption: '$orbCount in the fleet',
                onTap: () => pushScreen(context, const OrbGalleryScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _BigTile(
                icon: AppIcons.flag,
                title: 'Milestones',
                caption: 'Your checkpoint log',
                onTap: () => pushScreen(context, const MilestonesScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigTile(
                icon: AppIcons.timer,
                title: 'Focus',
                caption: 'Deep work timer',
                onTap: () => pushScreen(context, const FocusScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BigTile(
          icon: AppIcons.editNote,
          title: 'Journal',
          caption: 'Write down how the day went',
          wide: true,
          onTap: () => pushScreen(context, const JournalScreen()),
        ),
      ],
    );
  }
}

class _BigTile extends StatelessWidget {
  const _BigTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
    this.wide = false,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: wide
          ? Row(
              children: <Widget>[
                Icon(icon, size: 26, color: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(title, style: AppType.titleS()),
                      const SizedBox(height: 2),
                      Text(caption, style: AppType.bodyS()),
                    ],
                  ),
                ),
                const Icon(AppIcons.caretRight,
                    size: 15, color: AppPalette.textTertiary),
              ],
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 28, color: accent),
                  const SizedBox(height: 18),
                  Text(title, style: AppType.titleS()),
                  const SizedBox(height: 4),
                  Text(caption, style: AppType.bodyS(), maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final Color tone = switch (achievement.tier) {
      AchievementTier.bronze => const Color(0xFFCD7F32),
      AchievementTier.silver => const Color(0xFFB8C4D9),
      AchievementTier.gold => AppPalette.warning,
      AchievementTier.mythic => AppPalette.auroraMagenta,
    };

    return SizedBox(
      width: 112,
      child: GlassPanel(
        radius: 22,
        padding: const EdgeInsets.all(14),
        strokeColor: tone.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.withValues(alpha: 0.16),
                border: Border.all(color: tone.withValues(alpha: 0.45)),
              ),
              child: Icon(
                HabitIcons.resolveBold(achievement.iconKey),
                size: 18,
                color: tone,
              ),
            ),
            const Spacer(),
            Text(
              achievement.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.bodyS(color: AppPalette.textPrimary)
                  .copyWith(fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              achievement.tier.label,
              style: AppType.bodyS(color: tone).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fleet extends StatelessWidget {
  const _Fleet({required this.orbs});

  final List<OrbStats> orbs;

  @override
  Widget build(BuildContext context) {
    if (orbs.isEmpty) {
      return const EmptyState(
        icon: AppIcons.sphere,
        title: 'No orbs in the fleet',
        message: 'Forge one from the trail screen to begin.',
      );
    }

    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: <Widget>[
          for (final OrbStats o in orbs)
            SizedBox(
              width: 62,
              child: Column(
                children: <Widget>[
                  OrbView(
                    skin: o.habit.skin,
                    state: o.state,
                    size: 46,
                    momentum: o.momentum,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    o.habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppType.bodyS().copyWith(fontSize: 10),
                  ),
                  Text(
                    '${o.distance.round()}m',
                    style: AppType.bodyS(color: OrbArt.accent(o.habit.skin))
                        .copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
