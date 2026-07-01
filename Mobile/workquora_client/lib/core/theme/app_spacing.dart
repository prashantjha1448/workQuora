import 'package:flutter/material.dart';

/// Spacing & radius tokens from DESIGN.md. Using a tiny static class instead
/// of magic numbers keeps every screen visually consistent and makes future
/// theme tweaks a one-file change.
class AppSpacing {
  AppSpacing._();

  static const containerMargin = 16.0;
  static const cardPadding = 20.0;
  static const gutter = 12.0;
  static const stackSm = 8.0;
  static const stackMd = 16.0;
  static const stackLg = 24.0;
}

class AppRadius {
  AppRadius._();

  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
  static const full = 999.0;

  static final smR = BorderRadius.circular(sm);
  static final mdR = BorderRadius.circular(md);
  static final lgR = BorderRadius.circular(lg);
  static final xlR = BorderRadius.circular(xl);
  static final xxlR = BorderRadius.circular(xxl);
  static final fullR = BorderRadius.circular(full);
}
