import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

/// Manages the app's light/dark theme mode, persists the choice, and keeps
/// [AppColors]'s static palette flag in sync so `AppColors.xxx` getters
/// return the right colors everywhere in the widget tree.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'isDarkMode';

  final SharedPreferences _prefs;
  bool _isDarkMode;

  ThemeProvider(this._prefs) : _isDarkMode = _prefs.getBool(_prefsKey) ?? true {
    // Sync AppColors immediately on construction (it defaults to dark too,
    // but this makes the source of truth explicit and future-proof if the
    // AppColors default ever changes).
    AppColors.setDark(_isDarkMode);
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggle() => setDarkMode(!_isDarkMode);

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    // Update the static palette flag *before* notifying listeners so any
    // rebuild triggered by this change already reads the new colors.
    AppColors.setDark(_isDarkMode);
    await _prefs.setBool(_prefsKey, _isDarkMode);
    notifyListeners();
  }
}
