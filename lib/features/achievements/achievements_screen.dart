import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/habit_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/achievement.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementTier? _filter;

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final TrailSummary summary = habits.summary;

    final List<Achievement> all = AchievementCatalog.all
        .where((Achievement a) => _filter == null || a.tier == _filter)
        .toList()
      ..sort((Achievement a, Achievement b) {
        final int ua = a.isUnlocked(summary) ? 0 : 1;
        final int ub = b.isUnlocked(summary) ? 0 : 1;
        if (ua != ub) return ua - ub;
        return b.progressFor(summary).compareTo(a.progressFor(summary));
      });

    final int unlocked = AchievementCatalog.all
        .where((Achievement a) => a.isUnlocked(summary))
        .length;

    return ScreenShell(
      title: 'Achievements',
      subtitle: '$unlocked of ${AchievementCatalog.all.length} unlocked',
      seed: 12,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.all(20),
            gradient: AppPalette.auroraSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text('$unlocked', style: AppType.numeric(40)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 5),
                      child: Text(
                        '/ ${AchievementCatalog.all.length}',
                        style: AppType.bodyM(),
                      ),
                    ),
                    const Spacer(),
                    const Icon(AppIcons.medal,
                        size: 32, color: AppPalette.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                AuroraBar(
                  value: unlocked / AchievementCatalog.all.length,
                  height: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                AuroraChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final AchievementTier t in AchievementTier.values) ...<Widget>[
                  const SizedBox(width: 8),
                  AuroraChip(
                    label: t.label,
                    selected: _filter == t,
                    color: _tierColor(t),
                    onTap: () => setState(() => _filter = t),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < all.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AchievementCard(
                achievement: all[i],
                summary: summary,
              ).animate().fadeIn(delay: (35 * i).ms, duration: 280.ms).slideY(
                    begin: 0.08,
                    curve: Curves.easeOutCubic,
                  ),
            ),
        ],
      ),
    );
  }

  static Color _tierColor(AchievementTier t) => switch (t) {
        AchievementTier.bronze => const Color(0xFFCD7F32),
        AchievementTier.silver => const Color(0xFFB8C4D9),
        AchievementTier.gold => AppPalette.warning,
        AchievementTier.mythic => AppPalette.auroraMagenta,
      };
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.summary});

  final Achievement achievement;
  final TrailSummary summary;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = achievement.isUnlocked(summary);
    final double progress = achievement.progressFor(summary);
    final Color tone = _AchievementsScreenState._tierColor(achievement.tier);

    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.all(16),
      strong: unlocked,
      strokeColor: unlocked ? tone.withValues(alpha: 0.45) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? tone.withValues(alpha: 0.18)
                  : AppPalette.glassFillStrong,
              border: Border.all(
                color: unlocked
                    ? tone.withValues(alpha: 0.5)
                    : AppPalette.glassStroke,
              ),
              boxShadow: <BoxShadow>[
                if (unlocked)
                  BoxShadow(
                    color: tone.withValues(alpha: 0.22),
                    blurRadius: 18,
                  ),
              ],
            ),
            child: Icon(
              unlocked
                  ? HabitIcons.resolveBold(achievement.iconKey)
                  : AppIcons.lock,
              size: 21,
              color: unlocked ? tone : AppPalette.textTertiary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        achievement.title,
                        style: AppType.titleS(
                          color: unlocked
                              ? AppPalette.textPrimary
                              : AppPalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: tone.withValues(alpha: 0.14),
                      ),
                      child: Text(
                        achievement.tier.label.toUpperCase(),
                        style: AppType.overline(color: tone)
                            .copyWith(fontSize: 8.5, letterSpacing: 1.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(achievement.description, style: AppType.bodyS()),
                const SizedBox(height: 11),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AuroraBar(
                        value: progress,
                        height: 5,
                        gradient: LinearGradient(
                          colors: <Color>[tone, tone.withValues(alpha: 0.5)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_fmt(achievement.valueFor(summary))}/${_fmt(achievement.goal)}',
                      style: AppType.bodyS(
                        color: unlocked ? tone : AppPalette.textTertiary,
                      ).copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(num v) =>
      v is int ? '$v' : v.round().toString();
}
