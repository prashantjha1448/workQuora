import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
        ],
        Text(value, style: textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label, style: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}
