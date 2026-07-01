import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/wallet_controller.dart';

class AddBankAccountSheet extends ConsumerStatefulWidget {
  const AddBankAccountSheet({super.key});

  @override
  ConsumerState<AddBankAccountSheet> createState() => _AddBankAccountSheetState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBankAccountSheet(),
    );
  }
}

class _AddBankAccountSheetState extends ConsumerState<AddBankAccountSheet> {
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_bankNameController.text.trim().isEmpty ||
        _accountNumberController.text.trim().isEmpty ||
        _ifscController.text.trim().isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final failure = await ref.read(walletControllerProvider.notifier).addBankAccount(
          bankName: _bankNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (failure != null) {
      setState(() => _error = failure.message);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
            Text('Add payment method', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.stackLg),
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(hintText: 'Bank name', prefixIcon: Icon(Icons.account_balance_outlined)),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Account number', prefixIcon: Icon(Icons.numbers_rounded)),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextField(
              controller: _ifscController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: 'IFSC code', prefixIcon: const Icon(Icons.tag_rounded), errorText: _error),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            PrimaryButton(label: 'Save', isLoading: _isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
