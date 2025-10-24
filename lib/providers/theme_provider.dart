import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_providers.dart';

/// Notifier for managing theme mode (light/dark/system)
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const String _key = 'theme_mode';

  ThemeModeNotifier(this._prefs) : super(ThemeMode.light) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final themeIndex = _prefs.getInt(_key);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setInt(_key, mode.index);
  }

  Future<void> toggleTheme() async {
    // Cycle through: light -> dark -> system -> light
    final nextMode = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    await setThemeMode(nextMode);
  }
}

/// Provider for theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});
