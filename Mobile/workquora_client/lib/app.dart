import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class WorkQuoraApp extends ConsumerWidget {
  const WorkQuoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'wQ Recruit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      // Caps text scaling so premium layouts don't break on accessibility
      // settings with very large system font sizes — still respects user
      // preference up to a sane ceiling.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScale = mediaQuery.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScale),
          child: child!,
        );
      },
    );
  }
}
