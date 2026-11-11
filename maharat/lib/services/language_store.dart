import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the chosen language on this device, so it applies from the very
/// first screen, before sign-in.
class LanguageStore {
  static const _key = 'app_language';

  Future<String?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (error) {
      debugPrint('Could not read language: $error');
      return null;
    }
  }

  Future<void> save(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, language);
    } catch (error) {
      debugPrint('Could not save language: $error');
    }
  }
}
