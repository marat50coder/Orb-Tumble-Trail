import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/player_progress.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';

/// Meta-progression hub: level, XP, streak shields and the day's quests.
class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final PlayerProgress progress = habits.progress;
    final List<QuestProgress> quests = habits.todayQuests;
    final int claimable =
        quests.where((QuestProgress q) => q.claimable).length;

    return ScreenShell(
      title: 'Quests',
      subtitle: 'Level up your whole trail',
      seed: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _LevelHero(progress: progress),
          const SizedBox(height: 12),
          _ShieldCard(progress: progress),
          SectionLabel(
            'Daily quests',
            trailing: claimable > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppPalette.warning.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$claimable ready',
                      style: AppType.bodyS(color: AppPalette.warning)
                          .copyWith(fontSize: 10.5),
                    ),
                  )
                : null,
          ),
          for (int i = 0; i < quests.length; i++) ...<Widget>[
            _QuestTile(entry: quests[i])
                .animate()
                .fadeIn(delay: (60 * i).ms, duration: 300.ms)
                .moveY(begin: 8, end: 0),
            if (i != quests.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          _EconomyNote(),
        ],
      ),
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return GlassPanel(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      gradient: AppPalette.auroraSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[accent, AppPalette.auroraMagenta],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text('${progress.level}',
                    style: AppType.numeric(26, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Level ${progress.level}', style: AppType.titleM()),
                    const SizedBox(height: 2),
                    Text(progress.rank,
                        style: AppType.bodyS(color: AppPalette.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('${progress.totalXp}',
                      style: AppType.numeric(20, color: accent)),
                  Text('total XP', style: AppType.bodyS().copyWith(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          AuroraBar(value: progress.levelProgress, height: 10),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('${progress.xpIntoLevel} / ${progress.xpForLevel} XP',
                  style: AppType.bodyS()),
              Text('${progress.xpForLevel - progress.xpIntoLevel} to level ${progress.level + 1}',
                  style: AppType.bodyS(color: AppPalette.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShieldCard extends StatelessWidget {
  const _ShieldCard({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.info.withValues(alpha: 0.16),
                  border:
                      Border.all(color: AppPalette.info.withValues(alpha: 0.45)),
                ),
                child: const Icon(AppIcons.shield,
                    size: 24, color: AppPalette.info),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Streak shields', style: AppType.titleS()),
                    const SizedBox(height: 3),
                    Text(
                      'Freeze a missed day so it never breaks an orb\u2019s streak. Spend one from any orb\u2019s detail screen.',
                      style: AppType.bodyS(color: AppPalette.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: <Widget>[
                  Text('${progress.shieldsAvailable}',
                      style: AppType.numeric(28, color: AppPalette.info)),
                  Text('ready', style: AppType.bodyS().copyWith(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AuroraBar(
            value: progress.shieldProgress,
            height: 7,
            gradient: LinearGradient(
              colors: <Color>[
                AppPalette.info,
                AppPalette.info.withValues(alpha: 0.5),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${progress.completionsToNextShield} more completions to the next shield',
              style: AppType.bodyS(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.entry});

  final QuestProgress entry;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final Color tone = entry.claimed
        ? AppPalette.success
        : entry.complete
            ? AppPalette.warning
            : accent;

    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.all(16),
      strokeColor: entry.claimable ? AppPalette.warning.withValues(alpha: 0.5) : null,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: tone.withValues(alpha: 0.15),
                  border: Border.all(color: tone.withValues(alpha: 0.4)),
                ),
                child: Icon(entry.quest.icon, size: 20, color: tone),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(entry.quest.title, style: AppType.titleS()),
                    const SizedBox(height: 2),
                    Text(entry.quest.subtitle, style: AppType.bodyS()),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RewardOrAction(entry: entry),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: AuroraBar(
                  value: entry.ratio,
                  height: 7,
                  gradient: LinearGradient(
                    colors: <Color>[tone, tone.withValues(alpha: 0.6)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${entry.current.clamp(0, entry.quest.target)}/${entry.quest.target}',
                  style: AppType.numeric(13, color: AppPalette.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardOrAction extends StatelessWidget {
  const _RewardOrAction({required this.entry});

  final QuestProgress entry;

  @override
  Widget build(BuildContext context) {
    if (entry.claimed) {
      return const Icon(AppIcons.checkCircle,
          size: 26, color: AppPalette.success);
    }
    if (entry.claimable) {
      return _ClaimButton(questId: entry.quest.id, xp: entry.quest.xp);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text('+${entry.quest.xp}',
            style: AppType.numeric(16, color: AppPalette.warning)),
        Text('XP', style: AppType.bodyS().copyWith(fontSize: 10)),
      ],
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.questId, required this.xp});

  final String questId;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final bool ok =
            await context.read<HabitController>().claimQuest(questId);
        if (!context.mounted) return;
        if (ok) context.read<SettingsController>().success();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: <Color>[AppPalette.warning, AppPalette.auroraMagenta],
          ),
        ),
        child: Text('Claim +$xp',
            style: AppType.titleS(color: Colors.white).copyWith(fontSize: 13)),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          begin: 1,
          end: 1.05,
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _EconomyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          const Icon(AppIcons.sparkle, size: 20, color: AppPalette.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Every completed orb is worth ${PlayerProgress.xpPerCompletion} XP, a flawless day ${PlayerProgress.xpPerPerfectDay} XP. Quests and badges pour in extra.',
              style: AppType.bodyS(color: AppPalette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
