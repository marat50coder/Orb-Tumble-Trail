import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/habit_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/orb_view.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/habit.dart';
import '../../data/models/orb_stats.dart';
import '../../state/habit_controller.dart';
import '../../state/settings_controller.dart';
import '../habits/habit_detail_screen.dart';
import '../habits/habit_editor_screen.dart';
import '../habits/habits_screen.dart';
import 'trail_painter.dart';

/// The hero screen: a living scene where every habit is an orb travelling up
/// the trail, with a compact control deck pinned underneath.
class TrailScreen extends StatefulWidget {
  const TrailScreen({super.key});

  @override
  State<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends State<TrailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 1400));

  bool _celebratedToday = false;

  @override
  void initState() {
    super.initState();
    _ambient.repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _confetti.dispose();
    super.dispose();
  }

  String _environmentAsset(TrailEnvironment mode) {
    switch (mode) {
      case TrailEnvironment.morning:
        return AppAssets.bgMorning;
      case TrailEnvironment.afternoon:
        return AppAssets.bgAfternoon;
      case TrailEnvironment.evening:
        return AppAssets.bgEvening;
      case TrailEnvironment.auto:
        final int hour = DateTime.now().hour;
        if (hour < 11) return AppAssets.bgMorning;
        if (hour < 18) return AppAssets.bgAfternoon;
        return AppAssets.bgEvening;
    }
  }

  Future<void> _roll(Habit habit) async {
    final HabitController habits = context.read<HabitController>();
    final SettingsController settings = context.read<SettingsController>();
    final bool closed = await habits.roll(habit.id);
    if (!mounted) return;

    if (closed) {
      settings.success();
      final TrailSummary summary = habits.summary;
      if (summary.isPerfectToday && !_celebratedToday) {
        _celebratedToday = true;
        _confetti.play();
        _showPerfectDay();
      }
    } else {
      settings.tap();
    }
  }

  void _showPerfectDay() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Row(
            children: <Widget>[
              const Icon(AppIcons.sparkle,
                  color: AppPalette.warning, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Flawless day — every orb crossed the ridge.',
                  style: AppType.bodyM(color: AppPalette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final HabitController habits = context.watch<HabitController>();
    final SettingsController settings = context.watch<SettingsController>();
    final AppSettings prefs = settings.value;
    final TrailSummary summary = habits.summary;
    final Color accent = Theme.of(context).colorScheme.primary;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: _Environment(
            asset: _environmentAsset(prefs.environment),
            controller: _ambient,
            animated: !prefs.reduceMotion,
            particles: prefs.showParticles,
            accent: accent,
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _TrailHeader(summary: summary),
              Expanded(
                child: habits.hasHabits
                    ? _TrailStage(
                        orbs: summary.orbs,
                        compact: prefs.compactTrail,
                        ambient: _ambient,
                        accent: accent,
                        progress: summary.todayRatio,
                        onTapOrb: (OrbStats o) => pushScreen(
                          context,
                          HabitDetailScreen(habitId: o.habit.id),
                        ),
                        onRollOrb: (OrbStats o) => _roll(o.habit),
                      )
                    : _EmptyTrail(
                        onCreate: () => pushScreen(
                          context,
                          const HabitEditorScreen(),
                        ),
                      ),
              ),
              _ControlDeck(
                summary: summary,
                onRoll: _roll,
                onOpen: (Habit h) =>
                    pushScreen(context, HabitDetailScreen(habitId: h.id)),
                onAdd: () => pushScreen(context, const HabitEditorScreen()),
                onManage: () => pushScreen(context, const HabitsScreen()),
              ),
              // Clear the floating nav bar (68 + 12 padding) plus the device's
              // bottom safe inset so the footer bar is never covered.
              SizedBox(height: 92 + MediaQuery.viewPaddingOf(context).bottom),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.06,
            numberOfParticles: 18,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.28,
            shouldLoop: false,
            colors: const <Color>[
              AppPalette.auroraBlue,
              AppPalette.auroraViolet,
              AppPalette.auroraMagenta,
              AppPalette.success,
              AppPalette.warning,
            ],
          ),
        ),
      ],
    );
  }
}

class _Environment extends StatelessWidget {
  const _Environment({
    required this.asset,
    required this.controller,
    required this.animated,
    required this.particles,
    required this.accent,
  });

  final String asset;
  final AnimationController controller;
  final bool animated;
  final bool particles;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.medium,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xCC050814),
                Color(0x66050814),
                Color(0xE6050814),
                Color(0xFF050814),
              ],
              stops: <double>[0.0, 0.34, 0.78, 1.0],
            ),
          ),
        ),
        if (particles)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, _) => CustomPaint(
                painter: MotePainter(
                  t: animated ? controller.value : 0.2,
                  color: Colors.white,
                  count: 26,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrailHeader extends StatelessWidget {
  const _TrailHeader({required this.summary});

  final TrailSummary summary;

  String get _greeting {
    final int h = DateTime.now().hour;
    if (h < 5) return 'Still awake';
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(),
                  style: AppType.overline(),
                ),
                const SizedBox(height: 6),
                Text(_greeting, style: AppType.displayM()),
              ],
            ),
          ),
          _StreakBadge(days: summary.dayStreak, accent: accent),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days, required this.accent});

  final int days;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool alive = days > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: alive
            ? AppPalette.warning.withValues(alpha: 0.14)
            : AppPalette.glassFill,
        border: Border.all(
          color: alive
              ? AppPalette.warning.withValues(alpha: 0.45)
              : AppPalette.glassStroke,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            alive ? AppIcons.fire : AppIcons.fire,
            size: 16,
            color: alive ? AppPalette.warning : AppPalette.textTertiary,
          ),
          const SizedBox(width: 7),
          Text(
            '$days',
            style: AppType.numeric(15,
                color: alive ? AppPalette.textPrimary : AppPalette.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// The scene itself — path plus the orbs sitting on it.
class _TrailStage extends StatelessWidget {
  const _TrailStage({
    required this.orbs,
    required this.compact,
    required this.ambient,
    required this.accent,
    required this.progress,
    required this.onTapOrb,
    required this.onRollOrb,
  });

  final List<OrbStats> orbs;
  final bool compact;
  final AnimationController ambient;
  final Color accent;
  final double progress;
  final ValueChanged<OrbStats> onTapOrb;
  final ValueChanged<OrbStats> onRollOrb;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final Path path = TrailGeometry.build(size, compact: compact);
        final List<ui.PathMetric> metrics = path.computeMetrics().toList();
        final ui.PathMetric? metric = metrics.isEmpty ? null : metrics.first;

        final int checkpoints = orbs.fold<int>(
          0,
          (int s, OrbStats o) => s + o.checkpointsReached,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: ambient,
                  builder: (BuildContext context, _) => CustomPaint(
                    painter: TrailPainter(
                      accent: accent,
                      progress: progress,
                      checkpoints: checkpoints,
                      compact: compact,
                      glowPhase: ambient.value,
                    ),
                  ),
                ),
              ),
            ),
            if (metric != null)
              for (int i = 0; i < orbs.length; i++)
                _PositionedOrb(
                  key: ValueKey<String>(orbs[i].habit.id),
                  metric: metric,
                  stats: orbs[i],
                  index: i,
                  total: orbs.length,
                  onTap: () => onTapOrb(orbs[i]),
                  onDoubleTap: () => onRollOrb(orbs[i]),
                ),
          ],
        );
      },
    );
  }
}

class _PositionedOrb extends StatelessWidget {
  const _PositionedOrb({
    super.key,
    required this.metric,
    required this.stats,
    required this.index,
    required this.total,
    required this.onTap,
    required this.onDoubleTap,
  });

  final ui.PathMetric metric;
  final OrbStats stats;
  final int index;
  final int total;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final DateTime today = DayKey.today();
    final double ratio = stats.habit.ratioOn(today);

    // Every orb climbs the SAME trail; its height is its progress today.
    // A finished orb rests near the top (the "ridge"), an untouched one sits
    // at the foot. To keep orbs at similar progress from stacking exactly, we
    // add a small symmetric stagger around each one's natural position.
    const double foot = 0.10;
    const double ridge = 0.92;
    final double natural = foot + ratio * (ridge - foot);

    final double staggerSpan = math.min(0.07 * (total - 1), 0.34);
    final double stagger =
        total <= 1 ? 0 : (index / (total - 1) - 0.5) * staggerSpan;

    final double target = (natural + stagger).clamp(0.05, 0.97);

    final double size = 60 - math.min(total, 6) * 2.4;

    return _AnimatedOrbPosition(
      target: target,
      metric: metric,
      size: size,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: OrbView(
        skin: stats.habit.skin,
        state: stats.state,
        size: size,
        momentum: stats.momentum,
        spin: stats.state == OrbState.rolling,
      ),
    );
  }
}

/// Wraps an orb widget in an animated position along the trail path.
/// Uses a [StatefulWidget] so the tween can properly animate FROM the
/// previous position when `target` changes.
class _AnimatedOrbPosition extends StatefulWidget {
  const _AnimatedOrbPosition({
    required this.target,
    required this.metric,
    required this.size,
    required this.onTap,
    required this.onDoubleTap,
    required this.child,
  });

  final double target;
  final ui.PathMetric metric;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final Widget child;

  @override
  State<_AnimatedOrbPosition> createState() => _AnimatedOrbPositionState();
}

class _AnimatedOrbPositionState extends State<_AnimatedOrbPosition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  late double _from = widget.target;
  late double _to = widget.target;

  @override
  void didUpdateWidget(covariant _AnimatedOrbPosition old) {
    super.didUpdateWidget(old);
    if ((old.target - widget.target).abs() > 0.001) {
      _from = old.target;
      _to = widget.target;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    return AnimatedBuilder(
      animation: _curve,
      builder: (BuildContext context, _) {
        final double t =
            _from + (_to - _from) * _curve.value;
        final ui.Tangent? tangent =
            widget.metric.getTangentForOffset(widget.metric.length * t);
        if (tangent == null) return const SizedBox.shrink();
        final Offset p = tangent.position;
        return Positioned(
          left: p.dx - s / 2,
          top: p.dy - s / 2 - 6,
          width: s,
          height: s,
          child: GestureDetector(
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            // Flick an orb up the trail to roll it forward — the "tumble".
            onVerticalDragEnd: (DragEndDetails d) {
              if ((d.primaryVelocity ?? 0) < -240) widget.onDoubleTap();
            },
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _EmptyTrail extends StatelessWidget {
  const _EmptyTrail({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.path,
      title: 'The trail is quiet',
      message:
          'Nothing is rolling yet. Forge your first orb and the path will start\n'
          'lighting up beneath it.',
      action: AuroraButton(
        label: 'Forge an orb',
        icon: AppIcons.plus,
        expanded: false,
        onPressed: onCreate,
      ),
    );
  }
}

/// Bottom deck: the practical half of the screen.
class _ControlDeck extends StatelessWidget {
  const _ControlDeck({
    required this.summary,
    required this.onRoll,
    required this.onOpen,
    required this.onAdd,
    required this.onManage,
  });

  final TrailSummary summary;
  final ValueChanged<Habit> onRoll;
  final ValueChanged<Habit> onOpen;
  final VoidCallback onAdd;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final List<OrbStats> orbs = summary.orbs;
    if (orbs.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.canvasRaised.withValues(alpha: 0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: const Border(
              top: BorderSide(color: AppPalette.glassStroke),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: orbs.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (BuildContext context, int i) {
                    if (i == orbs.length) {
                      return _AddOrbTile(onTap: onAdd);
                    }
                    return _OrbTile(
                      stats: orbs[i],
                      onTap: () => onRoll(orbs[i].habit),
                      onLongPress: () => onOpen(orbs[i].habit),
                    )
                        .animate()
                        .fadeIn(delay: (40 * i).ms, duration: 320.ms)
                        .slideY(begin: 0.18, curve: Curves.easeOutCubic);
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DeckFooter(summary: summary, onManage: onManage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbTile extends StatelessWidget {
  const _OrbTile({
    required this.stats,
    required this.onTap,
    required this.onLongPress,
  });

  final OrbStats stats;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final Habit habit = stats.habit;
    final bool done = stats.isCompleteToday;
    final bool scheduled = stats.isScheduledToday;
    final Color accent = OrbArt.accent(habit.skin);
    final double ratio = habit.ratioOn(DayKey.today());

    return SizedBox(
      width: 86,
      child: Material(
        color: done ? accent.withValues(alpha: 0.14) : AppPalette.glassFill,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: scheduled && !done ? onTap : onLongPress,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: done
                    ? accent.withValues(alpha: 0.6)
                    : AppPalette.glassStroke,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: ProgressRing(
                        value: ratio,
                        size: 46,
                        stroke: 3,
                        colors: <Color>[accent, AppPalette.auroraMagenta],
                      ),
                    ),
                    Icon(
                      HabitIcons.resolve(habit.iconKey),
                      size: 20,
                      color: done ? accent : AppPalette.textSecondary,
                    ),
                    if (done)
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.success,
                            border: Border.all(
                              color: AppPalette.canvasRaised,
                              width: 1.6,
                            ),
                          ),
                          child: const Icon(
                            AppIcons.check,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppType.bodyS(
                    color: done ? AppPalette.textPrimary : AppPalette.textSecondary,
                  ).copyWith(fontSize: 11),
                ),
                if (habit.dailyTarget > 1)
                  Text(
                    '${habit.countOn(DayKey.today())}/${habit.dailyTarget}',
                    style: AppType.bodyS(color: accent).copyWith(fontSize: 10),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOrbTile extends StatelessWidget {
  const _AddOrbTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 66,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: DottedBorderBox(
            color: accent.withValues(alpha: 0.45),
            radius: 22,
            child: Center(
              child: Icon(AppIcons.plus, size: 22, color: accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckFooter extends StatelessWidget {
  const _DeckFooter({required this.summary, required this.onManage});

  final TrailSummary summary;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final int done = summary.todayCompleted;
    final int total = summary.todayScheduled;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text('$done', style: AppType.numeric(17)),
                  Text(' of $total', style: AppType.bodyS()),
                  const Spacer(),
                  Text(
                    '${summary.totalDistance.round()} m rolled',
                    style: AppType.bodyS(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AuroraBar(value: summary.todayRatio, height: 6),
            ],
          ),
        ),
        const SizedBox(width: 14),
        GlassIconButton(
          icon: AppIcons.sliders,
          onPressed: onManage,
          tooltip: 'Manage orbs',
        ),
      ],
    );
  }
}

/// Dashed outline container — used for the "add" affordance.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.radius = 20,
    this.dash = 5,
    this.gap = 4,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, radius: radius, dash: dash, gap: gap),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({
    required this.color,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) => old.color != color;
}
