import 'package:flutter/material.dart';

/// Colour language of the product. Deep space navy canvas, a neon aurora
/// gradient lifted straight from the launcher icon, and a restrained set of
/// semantic accents.
class AppPalette {
  const AppPalette._();

  // Canvas
  static const Color voidBlack = Color(0xFF04060F);
  static const Color canvas = Color(0xFF070A18);
  static const Color canvasRaised = Color(0xFF0C1024);
  static const Color canvasOverlay = Color(0xFF121734);

  // Aurora (matches the app icon ring)
  static const Color auroraBlue = Color(0xFF2E9BFF);
  static const Color auroraIndigo = Color(0xFF6C5CE7);
  static const Color auroraViolet = Color(0xFF9B5CFF);
  static const Color auroraMagenta = Color(0xFFFF3D9A);

  // Text
  static const Color textPrimary = Color(0xFFF4F6FF);
  static const Color textSecondary = Color(0xFFA6ADCB);
  static const Color textTertiary = Color(0xFF6B7398);

  // Semantic
  static const Color success = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color info = Color(0xFF43C6FF);

  // Surfaces
  // Strokes stay a soft white so edges read on any background.
  static const Color glassStroke = Color(0x24FFFFFF);
  static const Color glassStrokeStrong = Color(0x3DFFFFFF);
  // Fills are a dark navy base (not translucent white) so every panel looks
  // identical regardless of the aurora bloom drifting behind it.
  static const Color glassFill = Color(0x7A0C1024);
  static const Color glassFillStrong = Color(0x9E121734);

  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[auroraBlue, auroraViolet, auroraMagenta],
  );

  static const LinearGradient auroraSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x332E9BFF), Color(0x339B5CFF), Color(0x33FF3D9A)],
  );

  static const LinearGradient canvasGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF0A0F26), Color(0xFF070A18), Color(0xFF04060F)],
    stops: <double>[0.0, 0.55, 1.0],
  );

  /// Deterministic accent for an orb colour key.
  static const Map<String, Color> orbAccents = <String, Color>{
    'green': Color(0xFF57E389),
    'orange': Color(0xFFFF9F43),
    'purple': Color(0xFFA55CFF),
    'red': Color(0xFFFF5C5C),
  };
}
