/// Central registry of bundled assets so paths are never duplicated.
class AppAssets {
  const AppAssets._();

  static const String _root = 'assets/';

  // Branding
  static const String icon = '${_root}icon.png';
  static const String logoMark = '${_root}image-removebg-preview.webp';
  static const String splashPortrait = '${_root}Frame 36.webp';
  static const String splashLandscape = '${_root}Frame 37.webp';

  // Trail environments
  static const String bgMorning = '${_root}bgMorning.webp';
  static const String bgAfternoon = '${_root}bgAfternon.webp';
  static const String bgEvening = '${_root}bgEvening.webp';
  static const String stoneTexture = '${_root}stone.webp';

  // Orbs
  static const String orbGreen = '${_root}green-removebg-preview.webp';
  static const String orbOrange = '${_root}orange-removebg-preview.webp';
  static const String orbPurple = '${_root}purple-removebg-preview.webp';
  static const String orbRed = '${_root}red-removebg-preview.webp';
  static const String orbDormant = '${_root}withoutColor_gray-removebg-preview.webp';
  static const String orbBroken = '${_root}broken-removebg-preview.webp';

  static const List<String> environments = <String>[
    bgMorning,
    bgAfternoon,
    bgEvening,
  ];

  /// Every image that should be warmed into the image cache before the first
  /// frame of the app is shown.
  static const List<String> preloadable = <String>[
    splashPortrait,
    splashLandscape,
    logoMark,
    bgMorning,
    bgAfternoon,
    bgEvening,
    stoneTexture,
    orbGreen,
    orbOrange,
    orbPurple,
    orbRed,
    orbDormant,
    orbBroken,
  ];
}
