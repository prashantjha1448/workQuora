import 'package:flutter/material.dart';

/// Design tokens lifted 1:1 from DESIGN.md ("SkillSync" / wQ Recruit system).
/// Do NOT hardcode hex colors anywhere else in the app — always reference these.
class AppColors {
  AppColors._();

  static const surface = Color(0xFFF8F9FA);
  static const surfaceDim = Color(0xFFD9DADB);
  static const surfaceBright = Color(0xFFF8F9FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainer = Color(0xFFEDEEEF);
  static const surfaceContainerHigh = Color(0xFFE7E8E9);
  static const surfaceContainerHighest = Color(0xFFE1E3E4);

  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF464555);
  static const inverseSurface = Color(0xFF2E3132);
  static const inverseOnSurface = Color(0xFFF0F1F2);

  static const outline = Color(0xFF777587);
  static const outlineVariant = Color(0xFFC7C4D8);
  static const outlineSubtle = Color(0xFFC7C4D8);

  static const surfaceTint = Color(0xFF4D44E3);
  static const primary = Color(0xFF1E00A9);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF3525CD);
  static const onPrimaryContainer = Color(0xFFB1AFFF);
  static const inversePrimary = Color(0xFFC3C0FF);

  static const secondary = Color(0xFF006E2D);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF97F4A3);
  static const onSecondaryContainer = Color(0xFF0A7231);

  static const tertiary = Color(0xFF002B7B);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF003FAC);
  static const onTertiaryContainer = Color(0xFF9EB5FF);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const primaryFixed = Color(0xFFE2DFFF);
  static const primaryFixedDim = Color(0xFFC3C0FF);
  static const onPrimaryFixed = Color(0xFF0F0069);
  static const onPrimaryFixedVariant = Color(0xFF3323CC);

  static const secondaryFixed = Color(0xFF9AF7A5);
  static const secondaryFixedDim = Color(0xFF7EDA8C);
  static const onSecondaryFixed = Color(0xFF002109);
  static const onSecondaryFixedVariant = Color(0xFF005320);

  static const tertiaryFixed = Color(0xFFDBE1FF);
  static const tertiaryFixedDim = Color(0xFFB4C5FF);
  static const onTertiaryFixed = Color(0xFF00174B);
  static const onTertiaryFixedVariant = Color(0xFF003EA8);

  static const background = Color(0xFFF8F9FA);
  static const onBackground = Color(0xFF191C1D);
  static const surfaceVariant = Color(0xFFE1E3E4);

  static const promoOrange = Color(0xFFFF9800);
  static const starRating = Color(0xFFFFC107);
  static const verifiedBlue = Color(0xFF3525CD);

  // ---- Worker-app green theme variant (per app icon: indigo=client, green=worker) ----
  static const workerPrimary = Color(0xFF006E2D);
  static const workerPrimaryContainer = Color(0xFF0A7231);
}
