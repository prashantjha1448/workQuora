import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../core/utils/document_picker.dart';
import '../../widgets/app_button.dart';

class KycBankScreen extends StatefulWidget {
  const KycBankScreen({super.key});
  @override State<KycBankScreen> createState() => _KycBankScreenState();
}

class _KycBankScreenState extends State<KycBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _confirmAccountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  String? _filePath;
  bool _obscureAccount = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _accountCtrl.dispose(); _confirmAccountCtrl.dispose(); _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final path = await pickDocumentImage(context);
    if (path != null) setState(() => _filePath = path);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final ok = await context.read<KycProvider>().submitBank(
      accountNumber: _accountCtrl.text.trim(),
      ifsc: _ifscCtrl.text.trim().toUpperCase(),
      holderName: _nameCtrl.text.trim(),
      filePath: _filePath,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.pop();
    } else {
      final err = context.read<KycProvider>().error ?? 'Failed to submit bank details';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Bank Account Details'), backgroundColor: AppColors.bg, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Account Holder Name', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.text),
              decoration: _decoration('As per bank records'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the account holder\'s full name' : null,
            ),
            const SizedBox(height: 16),

            const Text('Account Number', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountCtrl,
              obscureText: _obscureAccount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.text),
              decoration: _decoration('9-18 digit account number').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureAccount ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted, size: 20),
                  onPressed: () => setState(() => _obscureAccount = !_obscureAccount),
                ),
              ),
              validator: (v) {
                final val = v ?? '';
                if (val.length < 9 || val.length > 18) return 'Account number must be 9-18 digits';
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text('Confirm Account Number', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmAccountCtrl,
              obscureText: _obscureAccount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.text),
              decoration: _decoration('Re-enter account number'),
              validator: (v) => v != _accountCtrl.text ? 'Account numbers do not match' : null,
            ),
            const SizedBox(height: 16),

            const Text('IFSC Code', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(11)],
              style: const TextStyle(color: AppColors.text),
              decoration: _decoration('e.g. SBIN0001234'),
              validator: (v) {
                final val = (v ?? '').toUpperCase();
                if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(val)) return 'Enter a valid IFSC code';
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text('Bank Passbook / Cheque (Optional)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            _filePath == null
                ? OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file, color: AppColors.primary),
                    label: const Text('Upload Document', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_filePath!), width: 44, height: 44, fit: BoxFit.cover)),
                      const SizedBox(width: 10),
                      const Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(child: Text('Document selected', style: TextStyle(color: AppColors.text, fontSize: 13))),
                      TextButton(onPressed: _pickFile, child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                    ]),
                  ),
            const SizedBox(height: 32),
            AppButton(label: 'Save Bank Details', loading: _submitting, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
