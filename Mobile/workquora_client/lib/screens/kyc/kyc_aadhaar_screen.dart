import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../core/utils/document_picker.dart';
import '../../widgets/app_button.dart';

class KycAadhaarScreen extends StatefulWidget {
  const KycAadhaarScreen({super.key});
  @override State<KycAadhaarScreen> createState() => _KycAadhaarScreenState();
}

class _KycAadhaarScreenState extends State<KycAadhaarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarCtrl = TextEditingController();
  String? _filePath;
  bool _submitting = false;

  @override
  void dispose() { _aadhaarCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final path = await pickDocumentImage(context);
    if (path != null) setState(() => _filePath = path);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your Aadhaar document'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _submitting = true);
    final ok = await context.read<KycProvider>().submitAadhaar(aadhaarNumber: _aadhaarCtrl.text.trim(), filePath: _filePath!);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.pop();
    } else {
      final err = context.read<KycProvider>().error ?? 'Failed to submit Aadhaar details';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Aadhaar Card Verification'), backgroundColor: AppColors.bg, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Aadhaar Number', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _aadhaarCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Enter 12-digit Aadhaar number',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
              validator: (v) {
                if (!RegExp(r'^[0-9]{12}$').hasMatch(v ?? '')) {
                  return 'Enter a valid 12-digit Aadhaar number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Aadhaar Document', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _filePath == null
                ? OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file, color: AppColors.primary),
                    label: const Text('Upload Aadhaar Document', style: TextStyle(color: AppColors.primary)),
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
            AppButton(label: 'Submit Aadhaar Card', loading: _submitting, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
