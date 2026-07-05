import 'package:flutter/material.dart';

/// App color palette. Fields are computed getters (not `const`) so the app
/// can switch between dark and light palettes at runtime via [AppColors.setDark].
///
/// NOTE: because these are no longer compile-time constants, any widget tree
/// that references `AppColors.xxx` cannot be built with the `const` keyword.
class AppColors {
  AppColors._();

  /// Current mode flag. Defaults to dark to match the app's original look.
  /// Set via [setDark] by ThemeProvider — never write to this directly
  /// elsewhere.
  static bool _isDark = true;

  static bool get isDark => _isDark;

  /// Updates the active palette. Call this *before* notifyListeners() in
  /// ThemeProvider so any rebuild triggered by the listener already sees the
  /// new colors.
  static void setDark(bool value) {
    _isDark = value;
  }

  // Brand color — identical in both modes.
  static const Color primary = Color(0xFF1E00A9);

  static Color get primaryDark =>
      _isDark ? const Color(0xFF150078) : const Color(0xFF150078);

  static Color get primaryGlow =>
      _isDark ? const Color(0x331E00A9) : const Color(0x1A1E00A9);

  static Color get bg =>
      _isDark ? const Color(0xFF09090B) : const Color(0xFFFFFFFF);

  static Color get surface =>
      _isDark ? const Color(0xFF121214) : const Color(0xFFF7F7F8);

  static Color get surfaceAlt =>
      _isDark ? const Color(0xFF1A1A1F) : const Color(0xFFEFEFF2);

  static Color get border =>
      _isDark ? const Color(0xFF27272A) : const Color(0xFFE2E2E6);

  static Color get text =>
      _isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);

  static Color get textMuted =>
      _isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);

  static Color get success =>
      _isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

  static Color get error =>
      _isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);

  static Color get warning =>
      _isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);

  static Color get amber =>
      _isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  static Color get emerald =>
      _isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
}
