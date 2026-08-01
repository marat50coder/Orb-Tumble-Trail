import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/habit.dart';
import '../../state/settings_controller.dart';

/// Visual preferences with a live preview at the top — the only screen where
/// the controls change what is drawn directly above them.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    final AppSettings s = controller.value;

    return ScreenShell(
      title: 'Appearance',
      subtitle: 'Make the trail yours',
      seed: 17,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Preview(settings: s),
          const SectionLabel('Accent'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (final AccentPreset a in AccentPreset.values)
                      _AccentDot(
                        preset: a,
                        selected: a == s.accent,
                        onTap: () {
                          controller.tap();
                          controller.setAccent(a);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'The accent drives buttons, charts, the trail glow and the '
                  'progress ring across every screen.',
                  style: AppType.bodyS(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SectionLabel('Environment'),
          Column(
            children: <Widget>[
              for (final TrailEnvironment e in TrailEnvironment.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EnvironmentRow(
                    environment: e,
                    selected: e == s.environment,
                    onTap: () {
                      controller.tap();
                      controller.setEnvironment(e);
                    },
                  ),
                ),
            ],
          ),
          const SectionLabel('Motion'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: <Widget>[
                SettingRow(
                  icon: AppIcons.wind,
                  title: 'Reduce motion',
                  subtitle: 'Freeze the ambient aurora',
                  trailing: Switch(
                    value: s.reduceMotion,
                    onChanged: controller.setReduceMotion,
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.sparkle,
                  title: 'Floating motes',
                  subtitle: 'Particles drifting over the scene',
                  trailing: Switch(
                    value: s.showParticles,
                    onChanged: controller.setShowParticles,
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.collapse,
                  title: 'Compact trail',
                  subtitle: 'Narrow the serpentine path',
                  trailing: Switch(
                    value: s.compactTrail,
                    onChanged: controller.setCompactTrail,
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

class _Preview extends StatelessWidget {
  const _Preview({required this.settings});

  final AppSettings settings;

  String get _asset {
    switch (settings.environment) {
      case TrailEnvironment.morning:
        return AppAssets.bgMorning;
      case TrailEnvironment.afternoon:
        return AppAssets.bgAfternoon;
      case TrailEnvironment.evening:
        return AppAssets.bgEvening;
      case TrailEnvironment.auto:
        final int h = DateTime.now().hour;
        if (h < 11) return AppAssets.bgMorning;
        if (h < 18) return AppAssets.bgAfternoon;
        return AppAssets.bgEvening;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = settings.accent.color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(_asset, fit: BoxFit.cover, alignment: Alignment.topCenter),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    const OrbView(skin: OrbSkin.purple, size: 46, momentum: 1),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Live preview', style: AppType.titleS()),
                          const SizedBox(height: 8),
                          AuroraBar(
                            value: 0.68,
                            height: 6,
                            gradient: LinearGradient(
                              colors: <Color>[accent, AppPalette.auroraMagenta],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AccentPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  preset.color,
                  Color.lerp(preset.color, AppPalette.auroraMagenta, 0.5)!,
                ],
              ),
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2.4,
              ),
              boxShadow: <BoxShadow>[
                if (selected)
                  BoxShadow(
                    color: preset.color.withValues(alpha: 0.5),
                    blurRadius: 18,
                  ),
              ],
            ),
            child: selected
                ? const Icon(AppIcons.check, size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            preset.label,
            style: AppType.bodyS(
              color: selected ? AppPalette.textPrimary : AppPalette.textTertiary,
            ).copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentRow extends StatelessWidget {
  const _EnvironmentRow({
    required this.environment,
    required this.selected,
    required this.onTap,
  });

  final TrailEnvironment environment;
  final bool selected;
  final VoidCallback onTap;

  String get _title => switch (environment) {
        TrailEnvironment.auto => 'Follow the clock',
        TrailEnvironment.morning => 'Dawn ridge',
        TrailEnvironment.afternoon => 'Golden hollow',
        TrailEnvironment.evening => 'Aurora isle',
      };

  String get _caption => switch (environment) {
        TrailEnvironment.auto => 'Changes as your day progresses',
        TrailEnvironment.morning => 'Soft light and a flowering path',
        TrailEnvironment.afternoon => 'Warm sunset over the village',
        TrailEnvironment.evening => 'Northern lights over the floating isle',
      };

  String? get _thumb => switch (environment) {
        TrailEnvironment.auto => null,
        TrailEnvironment.morning => AppAssets.bgMorning,
        TrailEnvironment.afternoon => AppAssets.bgAfternoon,
        TrailEnvironment.evening => AppAssets.bgEvening,
      };

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.all(12),
      strong: selected,
      strokeColor: selected ? accent.withValues(alpha: 0.6) : null,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 58,
              height: 58,
              child: _thumb == null
                  ? Container(
                      color: AppPalette.glassFillStrong,
                      child: const Icon(AppIcons.clock,
                          size: 22, color: AppPalette.textSecondary),
                    )
                  : Image.asset(_thumb!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_title, style: AppType.titleS()),
                const SizedBox(height: 3),
                Text(_caption, style: AppType.bodyS()),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? accent : Colors.transparent,
              border: Border.all(
                color: selected ? accent : AppPalette.glassStrokeStrong,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(AppIcons.check, size: 12, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}
