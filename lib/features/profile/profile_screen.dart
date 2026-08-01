import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/orb_stats.dart';
import '../../data/models/user_profile.dart';
import '../../state/habit_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/settings_controller.dart';
import '../about/about_screen.dart';
import '../appearance/appearance_screen.dart';
import '../data/data_screen.dart';
import '../settings/settings_screen.dart';
import '../web/web_page_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profile = context.watch<ProfileController>();
    final HabitController habits = context.watch<HabitController>();
    final SettingsController settings = context.watch<SettingsController>();
    final TrailSummary summary = habits.summary;
    final Color accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      extendBody: true,
      body: AuroraBackdrop(
        accent: accent,
        animated: !settings.value.reduceMotion,
        seed: 15,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: <Widget>[
              _ProfileHeader(profile: profile),
              const SizedBox(height: 20),
              _QuickStats(summary: summary, focus: habits.focusMinutes),
              const SectionLabel('Preferences'),
              GlassPanel(
                radius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  children: <Widget>[
                    SettingRow(
                      icon: AppIcons.settings,
                      title: 'Settings',
                      subtitle: 'Behaviour, haptics, week start',
                      onTap: () => pushScreen(context, const SettingsScreen()),
                    ),
                    const Divider(),
                    SettingRow(
                      icon: AppIcons.palette,
                      title: 'Appearance',
                      subtitle: 'Accent colour and trail environment',
                      onTap: () => pushScreen(context, const AppearanceScreen()),
                    ),
                    const Divider(),
                    SettingRow(
                      icon: AppIcons.database,
                      title: 'Data & storage',
                      subtitle: 'Everything is stored on this device',
                      onTap: () => pushScreen(context, const DataScreen()),
                    ),
                  ],
                ),
              ),
              const SectionLabel('Support'),
              GlassPanel(
                radius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  children: <Widget>[
                    SettingRow(
                      icon: AppIcons.lifebuoy,
                      title: 'Support',
                      subtitle: 'Ask a question or report a problem',
                      onTap: () => pushScreen(
                        context,
                        const WebPageScreen(kind: WebPageKind.support),
                      ),
                    ),
                    const Divider(),
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
                      icon: AppIcons.info,
                      title: 'About',
                      subtitle: 'Version ${AppConfig.version}',
                      onTap: () => pushScreen(context, const AboutScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: Text(
                  '${AppConfig.appName} · ${AppConfig.version}',
                  style: AppType.bodyS().copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final ProfileController profile;

  @override
  Widget build(BuildContext context) {
    final UserProfile user = profile.value;
    final Color accent = Theme.of(context).colorScheme.primary;

    return GlassPanel(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      gradient: AppPalette.auroraSoft,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => _openAvatarSheet(context, profile),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppPalette.aurora,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: profile.avatarFile != null
                        ? Image.file(
                            profile.avatarFile!,
                            fit: BoxFit.cover,
                            width: 102,
                            height: 102,
                            errorBuilder: (_, _, _) =>
                                _Initials(text: user.initials),
                          )
                        : _Initials(text: user.initials),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.canvasOverlay,
                    border: Border.all(color: AppPalette.glassStrokeStrong),
                  ),
                  child: const Icon(AppIcons.camera,
                      size: 15, color: AppPalette.textPrimary),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scaleXY(
                begin: 0.9,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 16),
          Text(user.name, style: AppType.displayM()),
          const SizedBox(height: 5),
          Text(
            user.motto.isEmpty
                ? 'Walking the trail since ${DateFormat('MMMM yyyy').format(user.joinedAt)}'
                : user.motto,
            style: AppType.bodyS(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GhostButton(
                label: 'Edit profile',
                icon: AppIcons.edit,
                height: 44,
                onPressed: () => _openEditSheet(context, profile),
              ),
              const SizedBox(width: 10),
              GhostButton(
                label: 'Photo',
                icon: AppIcons.image,
                height: 44,
                onPressed: () => _openAvatarSheet(context, profile),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.canvasOverlay,
      alignment: Alignment.center,
      child: Text(text, style: AppType.numeric(34)),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.summary, required this.focus});

  final TrailSummary summary;
  final int focus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatBox(
            value: '${summary.orbs.length}',
            label: 'orbs',
            icon: AppIcons.sphere,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '${summary.dayStreak}',
            label: 'streak',
            icon: AppIcons.fire,
            tone: AppPalette.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: summary.totalDistance >= 1000
                ? '${(summary.totalDistance / 1000).toStringAsFixed(1)}k'
                : '${summary.totalDistance.round()}',
            label: 'metres',
            icon: AppIcons.path,
            tone: AppPalette.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '$focus',
            label: 'focus',
            icon: AppIcons.timer,
            tone: AppPalette.success,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    this.tone,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final Color color = tone ?? Theme.of(context).colorScheme.primary;
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 9),
          Text(value, style: AppType.numeric(17)),
          const SizedBox(height: 3),
          Text(label, style: AppType.bodyS().copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

Future<void> _openAvatarSheet(
  BuildContext context,
  ProfileController profile,
) async {
  final SettingsController settings = context.read<SettingsController>();
  settings.tap();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => _Sheet(
      title: 'Profile photo',
      children: <Widget>[
        SettingRow(
          icon: AppIcons.camera,
          title: 'Take a photo',
          subtitle: 'Use the camera',
          onTap: () async {
            Navigator.of(sheetContext).pop();
            await _pick(context, profile, ImageSource.camera);
          },
        ),
        const Divider(),
        SettingRow(
          icon: AppIcons.image,
          title: 'Choose from gallery',
          subtitle: 'Pick an existing picture',
          onTap: () async {
            Navigator.of(sheetContext).pop();
            await _pick(context, profile, ImageSource.gallery);
          },
        ),
        if (profile.value.avatarPath != null) ...<Widget>[
          const Divider(),
          SettingRow(
            icon: AppIcons.trash,
            title: 'Remove photo',
            subtitle: 'Go back to your initials',
            tone: AppPalette.danger,
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await profile.removeAvatar();
            },
          ),
        ],
      ],
    ),
  );
}

Future<void> _pick(
  BuildContext context,
  ProfileController profile,
  ImageSource source,
) async {
  try {
    final bool picked = await profile.pickAvatar(source);
    if (!context.mounted || !picked) return;
    context.read<SettingsController>().success();
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Camera is not available on this device.'
                : 'Could not open the gallery.',
            style: AppType.bodyM(color: AppPalette.textPrimary),
          ),
        ),
      );
  }
}

Future<void> _openEditSheet(
  BuildContext context,
  ProfileController profile,
) async {
  final TextEditingController name =
      TextEditingController(text: profile.value.name);
  final TextEditingController motto =
      TextEditingController(text: profile.value.motto);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _Sheet(
        title: 'Edit profile',
        children: <Widget>[
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            style: AppType.titleS(),
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(AppIcons.userCircle, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: motto,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.bodyM(color: AppPalette.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Motto',
              hintText: 'Keep the orbs rolling',
            ),
          ),
          const SizedBox(height: 18),
          AuroraButton(
            label: 'Save',
            icon: AppIcons.check,
            onPressed: () async {
              await profile.setName(name.text);
              await profile.setMotto(motto.text);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ],
      ),
    ),
  );

  name.dispose();
  motto.dispose();
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: GlassPanel(
          radius: 28,
          strong: true,
          // No BackdropFilter here: a blur that is re-sampled on every frame
          // while the keyboard animates in can stall the UI thread. The sheet
          // is opaque anyway, so a solid surface looks identical and is fast.
          blur: 0,
          tint: AppPalette.canvasOverlay,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppPalette.glassStrokeStrong,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(title, style: AppType.titleM()),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
