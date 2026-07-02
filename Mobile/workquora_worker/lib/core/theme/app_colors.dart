import 'package:flutter/material.dart';

/// Worker-app theme — "SkillSync Elite" from DESIGN.md.
/// Deep Forest Green primary, metallic grey secondary, warm off-white surface.
/// This is the ONLY file that differs in tokens from the client app; keeping
/// the same class name + field names means every existing widget re-themes
/// automatically with zero other changes.
class AppColors {
  AppColors._();

  static const surface = Color(0xFFFAFAF5);
  static const surfaceDim = Color(0xFFDADAD6);
  static const surfaceBright = Color(0xFFFAFAF5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F4EF);
  static const surfaceContainer = Color(0xFFEEEEE9);
  static const surfaceContainerHigh = Color(0xFFE8E8E4);
  static const surfaceContainerHighest = Color(0xFFE2E3DE);

  static const onSurface = Color(0xFF1A1C19);
  static const onSurfaceVariant = Color(0xFF424841);
  static const inverseSurface = Color(0xFF2F312E);
  static const inverseOnSurface = Color(0xFFF1F1EC);

  static const outline = Color(0xFF727970);
  static const outlineVariant = Color(0xFFC2C8BF);
  static const outlineSubtle = Color(0xFFC2C8BF);

  static const surfaceTint = Color(0xFF446648);
  static const primary = Color(0xFF002109);          // Deep Forest Green
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF002109);
  static const onPrimaryContainer = Color(0xFF698D6B);
  static const inversePrimary = Color(0xFFAAD0AB);

  static const secondary = Color(0xFF5C5F60);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE1E3E3);
  static const onSecondaryContainer = Color(0xFF626566);

  static const tertiary = Color(0xFF000000);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF310F21);
  static const onTertiaryContainer = Color(0xFFA7768B);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const primaryFixed = Color(0xFFC5EDC6);
  static const primaryFixedDim = Color(0xFFAAD0AB);
  static const onPrimaryFixed = Color(0xFF002109);
  static const onPrimaryFixedVariant = Color(0xFF2D4E31);

  static const secondaryFixed = Color(0xFFE1E3E3);
  static const secondaryFixedDim = Color(0xFFC5C7C8);
  static const onSecondaryFixed = Color(0xFF191C1D);
  static const onSecondaryFixedVariant = Color(0xFF454748);

  static const tertiaryFixed = Color(0xFFFFD8E7);
  static const tertiaryFixedDim = Color(0xFFEFB7CE);
  static const onTertiaryFixed = Color(0xFF310F21);
  static const onTertiaryFixedVariant = Color(0xFF633A4D);

  static const background = Color(0xFFFAFAF5);
  static const onBackground = Color(0xFF1A1C19);
  static const surfaceVariant = Color(0xFFE2E3DE);

  static const promoOrange = Color(0xFFB8860B);
  static const starRating = Color(0xFFC9A227);
  static const verifiedBlue = Color(0xFF446648);

  static const workerPrimary = Color(0xFF002109);
  static const workerPrimaryContainer = Color(0xFF446648);
}
