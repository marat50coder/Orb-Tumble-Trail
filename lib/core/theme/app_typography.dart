
import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Both bundled families are variable fonts, so the weight axis has to be
/// driven explicitly through [FontVariation] — `fontWeight` alone would render
/// every style at the default 400.
///
/// Syne        — display / headings (geometric, futuristic, very distinctive)
/// PlusJakartaSans — body / UI text (modern geometric, readable, has personality)
class AppType {
  const AppType._();

  static const String display = 'Syne';
  static const String body = 'PlusJakartaSans';

  static TextStyle _v(
    String family,
    double size,
    int weight, {
    Color color = AppPalette.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: <FontVariation>[FontVariation('wght', weight.toDouble())],
    );
  }

  static TextStyle displayXL({Color color = AppPalette.textPrimary}) =>
      _v(display, 40, 700, color: color, height: 1.05, letterSpacing: -1.2);

  static TextStyle displayL({Color color = AppPalette.textPrimary}) =>
      _v(display, 32, 700, color: color, height: 1.1, letterSpacing: -0.9);

  static TextStyle displayM({Color color = AppPalette.textPrimary}) =>
      _v(display, 26, 600, color: color, height: 1.15, letterSpacing: -0.6);

  static TextStyle titleL({Color color = AppPalette.textPrimary}) =>
      _v(body, 22, 600, color: color, height: 1.2, letterSpacing: -0.3);

  static TextStyle titleM({Color color = AppPalette.textPrimary}) =>
      _v(body, 18, 600, color: color, height: 1.25, letterSpacing: -0.2);

  static TextStyle titleS({Color color = AppPalette.textPrimary}) =>
      _v(body, 15, 600, color: color, height: 1.3);

  static TextStyle bodyL({Color color = AppPalette.textSecondary}) =>
      _v(body, 16, 400, color: color, height: 1.5);

  static TextStyle bodyM({Color color = AppPalette.textSecondary}) =>
      _v(body, 14, 400, color: color, height: 1.5);

  static TextStyle bodyS({Color color = AppPalette.textTertiary}) =>
      _v(body, 12.5, 400, color: color, height: 1.45);

  static TextStyle label({Color color = AppPalette.textSecondary}) =>
      _v(body, 13, 500, color: color, height: 1.2, letterSpacing: 0.1);

  static TextStyle overline({Color color = AppPalette.textTertiary}) =>
      _v(body, 11, 600, color: color, height: 1.2, letterSpacing: 1.6);

  static TextStyle numeric(
    double size, {
    Color color = AppPalette.textPrimary,
    int weight = 600,
  }) =>
      _v(display, size, weight, color: color, height: 1.0, letterSpacing: -0.5);

  static TextTheme textTheme() => TextTheme(
        displayLarge: displayXL(),
        displayMedium: displayL(),
        displaySmall: displayM(),
        headlineMedium: titleL(),
        headlineSmall: titleM(),
        titleLarge: titleM(),
        titleMedium: titleS(),
        titleSmall: label(),
        bodyLarge: bodyL(),
        bodyMedium: bodyM(),
        bodySmall: bodyS(),
        labelLarge: label(color: AppPalette.textPrimary),
        labelMedium: label(),
        labelSmall: overline(),
      );
}
