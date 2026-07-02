import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/add_money_controller.dart';

class AddMoneySheet extends ConsumerStatefulWidget {
  const AddMoneySheet({super.key});

  @override
  ConsumerState<AddMoneySheet> createState() => _AddMoneySheetState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMoneySheet(),
    );
  }
}

const _quickAmounts = [500, 1000, 2000, 5000];

class _AddMoneySheetState extends ConsumerState<AddMoneySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMoneyControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen(addMoneyControllerProvider, (prev, next) {
      if (next.success && context.mounted) Navigator.of(context).pop();
    });

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add money', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Min \u20b910, max \u20b91,00,000 per transaction.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: textTheme.displayLarge,
              decoration: InputDecoration(
                prefixText: '\u20b9 ',
                hintText: '0',
                errorText: state.error?.message,
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Wrap(
              spacing: 8,
              children: _quickAmounts
                  .map((a) => ActionChip(
                        label: Text('\u20b9$a'),
                        onPressed: () => setState(() => _controller.text = '$a'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            PrimaryButton(
              label: 'Continue to pay',
              isLoading: state.isBusy,
              onPressed: () {
                final amount = num.tryParse(_controller.text);
                if (amount == null || amount < 10) return;
                ref.read(addMoneyControllerProvider.notifier).startAddMoney(amount);
              },
            ),
          ],
        ),
      ),
    );
  }
}
