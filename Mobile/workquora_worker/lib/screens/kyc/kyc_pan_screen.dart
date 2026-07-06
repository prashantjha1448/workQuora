import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class KycPanScreen extends StatefulWidget {
  const KycPanScreen({super.key});
  @override
  State<KycPanScreen> createState() => _KycPanScreenState();
}

class _KycPanScreenState extends State<KycPanScreen> {
  final _panCtrl = TextEditingController();
  String? _filePath;

  @override
  void dispose() {
    _panCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _filePath = picked.path);
  }

  Future<void> _submit() async {
    final pan = _panCtrl.text.trim().toUpperCase();
    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!regex.hasMatch(pan)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter a valid 10-character PAN number'), backgroundColor: AppColors.error));
      return;
    }
    final kyc = context.read<KycProvider>();
    final ok = await kyc.submitPan(pan, filePath: _filePath);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('PAN submitted!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kyc.error ?? 'Could not submit PAN'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = context.watch<KycProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PAN Verification'), backgroundColor: AppColors.background, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enter your PAN card number as printed on the card.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          AppTextField(controller: _panCtrl, hint: 'PAN Number (e.g. ABCDE1234F)', icon: Icons.badge_outlined),
          const SizedBox(height: 14),
          _imagePicker(),
          const SizedBox(height: 20),
          AppButton(label: 'Submit PAN', loading: kyc.isSubmitting, onPressed: _submit),
        ]),
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(_filePath != null ? Icons.check_circle : Icons.upload_file_outlined, color: _filePath != null ? AppColors.success : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(_filePath != null ? 'PAN photo selected' : 'Upload PAN photo (optional)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }
}
