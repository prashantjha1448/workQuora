import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class KycAadhaarScreen extends StatefulWidget {
  const KycAadhaarScreen({super.key});
  @override
  State<KycAadhaarScreen> createState() => _KycAadhaarScreenState();
}

class _KycAadhaarScreenState extends State<KycAadhaarScreen> {
  final _aadhaarCtrl = TextEditingController();
  String? _filePath;

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _filePath = picked.path);
  }

  Future<void> _submit() async {
    final aadhaar = _aadhaarCtrl.text.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter a valid 12-digit Aadhaar number'), backgroundColor: AppColors.error));
      return;
    }
    final kyc = context.read<KycProvider>();
    final ok = await kyc.submitAadhaar(aadhaar, filePath: _filePath);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Aadhaar submitted!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kyc.error ?? 'Could not submit Aadhaar'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = context.watch<KycProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Aadhaar Verification'), backgroundColor: AppColors.background, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enter your 12-digit Aadhaar number.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          AppTextField(controller: _aadhaarCtrl, hint: 'Aadhaar Number', icon: Icons.credit_card_outlined, keyboardType: TextInputType.number),
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
                Text(_filePath != null ? 'Aadhaar photo selected' : 'Upload Aadhaar photo (optional)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Submit Aadhaar', loading: kyc.isSubmitting, onPressed: _submit),
        ]),
      ),
    );
  }
}
