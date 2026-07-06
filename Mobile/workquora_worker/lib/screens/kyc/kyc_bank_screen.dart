import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class KycBankScreen extends StatefulWidget {
  const KycBankScreen({super.key});
  @override
  State<KycBankScreen> createState() => _KycBankScreenState();
}

class _KycBankScreenState extends State<KycBankScreen> {
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String? _filePath;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _holderCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _filePath = picked.path);
  }

  Future<void> _submit() async {
    final account = _accountCtrl.text.trim();
    final ifsc = _ifscCtrl.text.trim().toUpperCase();
    final holder = _holderCtrl.text.trim();

    if (account.isEmpty || ifsc.isEmpty || holder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('All bank details are required'), backgroundColor: AppColors.error));
      return;
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Invalid IFSC code format'), backgroundColor: AppColors.error));
      return;
    }

    final kyc = context.read<KycProvider>();
    final ok = await kyc.submitBank(
      accountNumber: account,
      ifsc: ifsc,
      holderName: holder,
      pin: _pinCtrl.text.trim().isEmpty ? null : _pinCtrl.text.trim(),
      filePath: _filePath,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Bank details submitted — pending review'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kyc.error ?? 'Could not submit bank details'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = context.watch<KycProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bank Details'), backgroundColor: AppColors.background, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Link a bank account so you can withdraw your earnings.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          AppTextField(controller: _holderCtrl, hint: 'Account holder name', icon: Icons.person_outline),
          const SizedBox(height: 12),
          AppTextField(controller: _accountCtrl, hint: 'Account number', icon: Icons.account_balance_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(controller: _ifscCtrl, hint: 'IFSC code', icon: Icons.numbers),
          const SizedBox(height: 12),
          AppTextField(controller: _pinCtrl, hint: 'Set a 4-digit withdrawal PIN', icon: Icons.lock_outline, obscure: true, keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Icon(_filePath != null ? Icons.check_circle : Icons.upload_file_outlined, color: _filePath != null ? AppColors.success : AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(_filePath != null ? 'Passbook/cheque photo selected' : 'Upload passbook/cheque photo (optional)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Submit Bank Details', loading: kyc.isSubmitting, onPressed: _submit),
        ]),
      ),
    );
  }
}
