import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import 'app_buttons.dart';
import 'aurora_backdrop.dart';

/// Shared page chrome: aurora backdrop, floating header, scroll body.
class ScreenShell extends StatelessWidget {
  const ScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.showBack = true,
    this.seed = 0,
    this.intensity = 1.0,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 32),
    this.floating,
    this.scrollable = true,
    this.headerTrailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final int seed;
  final double intensity;
  final EdgeInsets padding;
  final Widget? floating;
  final bool scrollable;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Header(
          title: title,
          subtitle: subtitle,
          actions: actions,
          showBack: showBack,
          trailing: headerTrailing,
        ),
        Expanded(
          child: scrollable
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: padding,
                  child: child,
                )
              : Padding(padding: padding, child: child),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      extendBody: true,
      body: AuroraBackdrop(
        accent: Theme.of(context).colorScheme.primary,
        animated: !settings.value.reduceMotion,
        intensity: intensity,
        seed: seed,
        child: SafeArea(
          bottom: false,
          child: floating == null
              ? body
              : Stack(
                  children: <Widget>[
                    body,
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
                      child: floating!,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showBack,
    required this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (showBack) ...<Widget>[
            GlassIconButton(
              icon: AppIcons.arrowLeft,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: AppType.titleL(), maxLines: 1),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppType.bodyS(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
          for (final Widget action in actions) ...<Widget>[
            const SizedBox(width: 10),
            action,
          ],
        ],
      ),
    );
  }
}

/// Small uppercase heading that separates blocks inside a page.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 12, top: 26),
  });

  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Theme.of(context).colorScheme.primary,
                  AppPalette.auroraMagenta,
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text.toUpperCase(), style: AppType.overline())),
          ?trailing,
        ],
      ),
    );
  }
}
