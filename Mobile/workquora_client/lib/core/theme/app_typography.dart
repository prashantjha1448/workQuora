import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale lifted from DESIGN.md. `google_fonts` caches the font
/// file locally after first load, so repeated app launches don't re-download —
/// good for both memory and battery/network usage at scale.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color baseColor) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.01 * 12,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11,
        color: baseColor,
      ),
    );
  }

  static final light = textTheme(AppColors.onSurface);
  static final dark = textTheme(AppColors.inverseOnSurface);
}
