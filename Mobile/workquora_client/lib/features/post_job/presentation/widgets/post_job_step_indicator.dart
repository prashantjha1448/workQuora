import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/post_job_controller.dart';

class PostJobStepIndicator extends StatelessWidget {
  const PostJobStepIndicator({super.key, required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(kPostJobSteps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStepDone = (i ~/ 2) < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: leftStepDone ? AppColors.primary : AppColors.surfaceContainerHigh,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = stepIndex == currentStep;
        final isDone = stepIndex < currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: (isActive || isDone) ? AppColors.primary : AppColors.surfaceContainerHigh,
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.outline,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              kPostJobSteps[stepIndex],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.outline,
              ),
            ),
          ],
        );
      }),
    );
  }
}
