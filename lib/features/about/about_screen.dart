import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/orb_view.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/habit.dart';
import '../web/web_page_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'About',
      subtitle: AppConfig.appName,
      seed: 20,
      intensity: 0.6,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Image.asset(AppAssets.logoMark, height: 110)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scaleXY(begin: 0.9, curve: Curves.easeOutBack),
                const SizedBox(height: 6),
                Text(AppConfig.appName, style: AppType.displayM()),
                const SizedBox(height: 6),
                Text(AppConfig.appTagline,
                    style: AppType.bodyS(), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SectionLabel('The idea'),
          GlassPanel(
            radius: 24,
            child: Text(
              'Most trackers ask you to tick boxes. Orb Tumble Trail turns each '
              'habit into a physical object with weight and momentum. Finish it '
              'and the orb rolls forward, gathering speed the longer you keep it '
              'going. Skip it and it tumbles back down the slope. Miss three '
              'scheduled days and it shatters — nothing is lost, but you can see '
              'the damage, and one completion is enough to reforge it.\n\n'
              'The result is a tracker you can read at a glance, without parsing '
              'a single number.',
              style: AppType.bodyM(color: AppPalette.textSecondary)
                  .copyWith(height: 1.62),
            ),
          ),
          const SectionLabel('Orb skins'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (final OrbSkin skin in OrbSkin.values)
                  Column(
                    children: <Widget>[
                      OrbView(skin: skin, size: 46, momentum: 1),
                      const SizedBox(height: 9),
                      Text(
                        OrbArt.label(skin),
                        style: AppType.bodyS().copyWith(fontSize: 10.5),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SectionLabel('Details'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                _Row(label: 'Version', value: AppConfig.version),
                const Divider(height: 22),
                _Row(label: 'Bundle ID', value: AppConfig.bundleId),
                const Divider(height: 22),
                _Row(label: 'App ID', value: AppConfig.appId),
                const Divider(height: 22),
                _Row(label: 'Works offline', value: 'Yes'),
              ],
            ),
          ),
          const SectionLabel('Legal'),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: <Widget>[
                SettingRow(
                  icon: AppIcons.shield,
                  title: 'Privacy policy',
                  subtitle: 'How your data is handled',
                  onTap: () => pushScreen(
                    context,
                    const WebPageScreen(kind: WebPageKind.privacy),
                  ),
                ),
                const Divider(),
                SettingRow(
                  icon: AppIcons.lifebuoy,
                  title: 'Support',
                  subtitle: AppConfig.supportEmail,
                  onTap: () => pushScreen(
                    context,
                    const WebPageScreen(kind: WebPageKind.support),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Text(
              'Made for people who keep rolling.',
              style: AppType.bodyS().copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: AppType.bodyM()),
        Text(value, style: AppType.label(color: AppPalette.textPrimary)),
      ],
    );
  }
}
