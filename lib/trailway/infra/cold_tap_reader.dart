import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Reads the cold-start push destination written by the native SceneDelegate
/// (killed-app push tap) and consumes it exactly once.
class ColdTapReader {
  static const String _dartKey = 'ott_relay_route';

  static Future<String?> consume() async {
    if (!Platform.isIOS) return null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(_dartKey)?.trim();
      if (value == null || value.isEmpty) return null;
      await preferences.remove(_dartKey);
      return value;
    } catch (_) {
      return null;
    }
  }
}
