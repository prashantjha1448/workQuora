import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/discover_controller.dart';

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({super.key, required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // "Peek" behavior from DESIGN.md — content bleeds past the container margin.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
        itemCount: kDiscoverCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.stackSm),
        itemBuilder: (context, index) {
          final category = kDiscoverCategories[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }
}
