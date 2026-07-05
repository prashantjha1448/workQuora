import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../core/utils/document_picker.dart';
import '../../widgets/app_button.dart';

class KycPanScreen extends StatefulWidget {
  const KycPanScreen({super.key});
  @override State<KycPanScreen> createState() => _KycPanScreenState();
}

class _KycPanScreenState extends State<KycPanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panCtrl = TextEditingController();
  String? _filePath;
  bool _submitting = false;

  @override
  void dispose() { _panCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final path = await pickDocumentImage(context);
    if (path != null) setState(() => _filePath = path);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload your PAN card image'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _submitting = true);
    final ok = await context.read<KycProvider>().submitPan(panNumber: _panCtrl.text.trim().toUpperCase(), filePath: _filePath!);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.pop();
    } else {
      final err = context.read<KycProvider>().error ?? 'Failed to submit PAN details';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('PAN Card Verification'), backgroundColor: AppColors.bg, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PAN Number', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _panCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(10)],
              style: TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'e.g. ABCDE1234F',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
              ),
              validator: (v) {
                final val = (v ?? '').toUpperCase();
                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(val)) {
                  return 'Enter a valid 10-character PAN number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('PAN Card Image', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _filePath == null
                ? OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.upload_file, color: AppColors.primary),
                    label: Text('Upload PAN Card Image', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_filePath!), width: 44, height: 44, fit: BoxFit.cover)),
                      const SizedBox(width: 10),
                      Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Document selected', style: TextStyle(color: AppColors.text, fontSize: 13))),
                      TextButton(onPressed: _pickFile, child: Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                    ]),
                  ),
            const SizedBox(height: 32),
            AppButton(label: 'Submit PAN Card', loading: _submitting, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
