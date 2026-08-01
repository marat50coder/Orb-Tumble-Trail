import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../state/settings_controller.dart';
import '../journey/journey_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/statistics_screen.dart';
import '../today/today_screen.dart';
import '../trail/trail_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialTab;
  late final PageController _controller = PageController(initialPage: _index);

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem('Trail', AppIcons.path, AppIcons.path),
    _NavItem('Today', AppIcons.sun, AppIcons.sun),
    _NavItem('Stats', AppIcons.chartBar, AppIcons.chartBar),
    _NavItem('Journey', AppIcons.compass, AppIcons.compass),
    _NavItem('You', AppIcons.userCircle, AppIcons.userCircle),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i == _index) return;
    context.read<SettingsController>().tap();
    setState(() => _index = i);
    _controller.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.canvas,
      extendBody: true,
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const <Widget>[
          TrailScreen(),
          TodayScreen(),
          StatisticsScreen(),
          JourneyScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _TrailNavBar(
        items: _items,
        index: _index,
        onTap: _go,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _TrailNavBar extends StatelessWidget {
  const _TrailNavBar({
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppPalette.canvasRaised.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppPalette.glassStroke),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == index,
                        accent: accent,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 3,
              width: selected ? 18 : 0,
              margin: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: <Color>[accent, AppPalette.auroraMagenta],
                ),
              ),
            ),
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 21,
              color: selected ? accent : AppPalette.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppType.bodyS(
                color: selected ? AppPalette.textPrimary : AppPalette.textTertiary,
              ).copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}
