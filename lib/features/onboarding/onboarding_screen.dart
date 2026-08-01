import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/habit_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_preset.dart';
import '../../state/habit_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/settings_controller.dart';
import '../home/home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();
  final Set<String> _chosen = <String>{};

  int _index = 0;
  bool _saving = false;

  static const int _pageCount = 5;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    context.read<SettingsController>().tap();
    if (_index < _pageCount - 1) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    final HabitController habits = context.read<HabitController>();
    final SettingsController settings = context.read<SettingsController>();
    final ProfileController profile = context.read<ProfileController>();

    if (_name.text.trim().isNotEmpty) {
      await profile.setName(_name.text);
    }
    for (final HabitPreset preset
        in HabitPresets.all.where((HabitPreset p) => _chosen.contains(p.title))) {
      await habits.createFromPreset(preset);
    }
    await settings.completeOnboarding();

    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 560),
        pageBuilder: (_, _, _) => const HomeShell(),
        transitionsBuilder: (_, Animation<double> a, _, Widget child) =>
            FadeTransition(opacity: a, child: child),
      ),
      (Route<dynamic> route) => false,
    );
  }

  bool get _canAdvance => switch (_index) {
        3 => _chosen.isNotEmpty,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final bool last = _index == _pageCount - 1;
    return Scaffold(
      backgroundColor: AppPalette.canvas,
      body: AuroraBackdrop(
        accent: Theme.of(context).colorScheme.primary,
        seed: _index,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _TopBar(
                index: _index,
                onSkip: _index < 3 ? () => _pages.jumpToPage(3) : null,
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (int i) => setState(() => _index = i),
                  children: <Widget>[
                    const _StoryPage(
                      art: _OrbTrio(),
                      eyebrow: 'Welcome',
                      title: 'Every habit\nbecomes an orb',
                      body:
                          'Pick what matters, give it a colour, and it takes '
                          'shape as a living orb resting at the head of your trail.',
                    ),
                    const _StoryPage(
                      art: _RollingOrb(),
                      eyebrow: 'Momentum',
                      title: 'Finish it and\nthe orb rolls',
                      body:
                          'Each completed day pushes the orb further down the '
                          'trail. Consecutive days multiply how far it travels.',
                    ),
                    const _StoryPage(
                      art: _TumbleOrb(),
                      eyebrow: 'Consequence',
                      title: 'Skip it and\nthe orb tumbles',
                      body:
                          'A missed day rolls the orb backwards. Three in a row '
                          'and it shatters — one completion is enough to reforge it.',
                    ),
                    _PickPage(
                      chosen: _chosen,
                      onToggle: (String title) => setState(() {
                        if (!_chosen.remove(title)) _chosen.add(title);
                      }),
                    ),
                    _NamePage(controller: _name, chosen: _chosen.length),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
                child: Column(
                  children: <Widget>[
                    SmoothPageIndicator(
                      controller: _pages,
                      count: _pageCount,
                      effect: ExpandingDotsEffect(
                        dotHeight: 6,
                        dotWidth: 6,
                        expansionFactor: 4,
                        spacing: 6,
                        dotColor: AppPalette.glassFillStrong,
                        activeDotColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AuroraButton(
                      label: last ? 'Enter the trail' : 'Continue',
                      icon: last
                          ? AppIcons.arrowRight
                          : AppIcons.caretRight,
                      busy: _saving,
                      onPressed: _canAdvance ? _next : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.onSkip});

  final int index;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 18, 0),
      child: Row(
        children: <Widget>[
          Image.asset(AppAssets.logoMark, height: 30, opacity: const AlwaysStoppedAnimation<double>(0.9)),
          const SizedBox(width: 10),
          Text('ORB TUMBLE TRAIL', style: AppType.overline()),
          const Spacer(),
          if (onSkip != null)
            TextButton(
              onPressed: onSkip,
              child: Text('Skip', style: AppType.label()),
            ),
        ],
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.art,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final Widget art;
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Center(child: art)),
          Text(eyebrow.toUpperCase(), style: AppType.overline())
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.3, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          Text(title, style: AppType.displayL())
              .animate()
              .fadeIn(delay: 90.ms, duration: 460.ms)
              .slideY(begin: 0.25, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          Text(body, style: AppType.bodyL())
              .animate()
              .fadeIn(delay: 180.ms, duration: 500.ms),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _OrbTrio extends StatelessWidget {
  const _OrbTrio();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 8,
            top: 42,
            child: const OrbView(skin: OrbSkin.green, size: 78, momentum: 0.7)
                .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                .moveY(begin: -6, end: 6, duration: 2600.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            right: 4,
            top: 18,
            child: const OrbView(skin: OrbSkin.orange, size: 64, momentum: 0.5)
                .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                .moveY(begin: 7, end: -7, duration: 3100.ms, curve: Curves.easeInOut),
          ),
          const OrbView(skin: OrbSkin.purple, size: 128, momentum: 1),
          Positioned(
            right: 34,
            bottom: 22,
            child: const OrbView(skin: OrbSkin.red, size: 54, momentum: 0.6)
                .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                .moveY(begin: -5, end: 5, duration: 2200.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

class _RollingOrb extends StatelessWidget {
  const _RollingOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: 62,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.transparent,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                    AppPalette.auroraMagenta.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 72,
            child: const OrbView(skin: OrbSkin.green, size: 108, spin: true)
                .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                .moveX(begin: -70, end: 70, duration: 3400.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

class _TumbleOrb extends StatelessWidget {
  const _TumbleOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 34,
            left: 26,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 132,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppPalette.glassFillStrong,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 34,
            child: const OrbView(
              skin: OrbSkin.red,
              state: OrbState.shattered,
              size: 116,
            )
                .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                .rotate(begin: -0.03, end: 0.03, duration: 2800.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

class _PickPage extends StatefulWidget {
  const _PickPage({required this.chosen, required this.onToggle});

  final Set<String> chosen;
  final ValueChanged<String> onToggle;

  @override
  State<_PickPage> createState() => _PickPageState();
}

class _PickPageState extends State<_PickPage> {
  String _category = HabitPresets.categories.first;

  @override
  Widget build(BuildContext context) {
    final List<HabitPreset> presets = HabitPresets.byCategory(_category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Choose your orbs', style: AppType.displayM()),
              const SizedBox(height: 8),
              Text(
                'Start with two or three. You can shape them later.',
                style: AppType.bodyM(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: HabitPresets.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int i) {
              final String c = HabitPresets.categories[i];
              return AuroraChip(
                label: c,
                selected: c == _category,
                onTap: () => setState(() => _category = c),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            physics: const BouncingScrollPhysics(),
            itemCount: presets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int i) {
              final HabitPreset p = presets[i];
              final bool selected = widget.chosen.contains(p.title);
              return _PresetRow(
                preset: p,
                selected: selected,
                onTap: () => widget.onToggle(p.title),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final HabitPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = OrbArt.accent(preset.skin);
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      strong: selected,
      strokeColor: selected ? accent.withValues(alpha: 0.7) : null,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          OrbView(
            skin: preset.skin,
            size: 40,
            state: selected ? OrbState.rolling : OrbState.waiting,
            momentum: selected ? 1 : 0.4,
            animated: selected,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(preset.title, style: AppType.titleS()),
                const SizedBox(height: 2),
                Text(
                  preset.dailyTarget > 1
                      ? '${preset.dailyTarget} ${preset.unit}s a day'
                      : (preset.kind == HabitKind.quit
                          ? 'Stay clean today'
                          : 'Once a day'),
                  style: AppType.bodyS(),
                ),
              ],
            ),
          ),
          Icon(
            HabitIcons.resolve(preset.iconKey),
            size: 20,
            color: selected ? accent : AppPalette.textTertiary,
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? accent : Colors.transparent,
              border: Border.all(
                color: selected ? accent : AppPalette.glassStrokeStrong,
                width: 1.4,
              ),
            ),
            child: selected
                ? const Icon(AppIcons.check, size: 14, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller, required this.chosen});

  final TextEditingController controller;
  final int chosen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ProgressRing(
                    value: math.min(1, chosen / 3),
                    size: 158,
                    stroke: 6,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('$chosen', style: AppType.numeric(44)),
                      const SizedBox(height: 4),
                      Text(
                        chosen == 1 ? 'orb ready' : 'orbs ready',
                        style: AppType.bodyS(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Almost there', style: AppType.overline()),
          const SizedBox(height: 10),
          Text('What should\nthe trail call you?', style: AppType.displayM()),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: AppType.titleM(),
            decoration: const InputDecoration(
              hintText: 'Your name',
              prefixIcon: Icon(AppIcons.userCircle, size: 22),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Optional — you can change it any time in your profile.',
            style: AppType.bodyS(),
          ),
        ],
      ),
    );
  }
}
