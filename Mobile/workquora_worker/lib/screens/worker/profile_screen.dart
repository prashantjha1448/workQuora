import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? {};
    final name = user['name'] ?? 'Worker';
    final title = user['title'] ?? 'Freelancer';
    final email = user['email'] ?? '';
    final isKyc = user['isKycVerified'] == true;
    final rating = (user['averageRating'] ?? 0.0).toDouble();
    final skills = List<String>.from(user['skills'] ?? []);
    final hourlyRate = user['hourlyRate'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: AppColors.background,
          expandedHeight: 220,
          pinned: true,
          actions: [
            IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () => context.push('/settings')),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF065F46), AppColors.primary, const Color(0xFF06B6D4)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 50),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'W', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  if (rating > 0) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                    Text(' ${rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ]),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _badge(isKyc ? '✓ KYC Verified' : '! KYC Pending', isKyc ? AppColors.primary : AppColors.warning),
              ]),
              const SizedBox(height: 24),
              _tile(Icons.email_outlined, 'Email', email),
              _tile(Icons.phone_outlined, 'Mobile', user['mobileNumber'] ?? 'Not added'),
              _tile(Icons.badge_outlined, 'Username', '@${user['username'] ?? ''}'),
              _tile(Icons.work_outline, 'Profession', title),
              _tile(Icons.currency_rupee, 'Hourly Rate', hourlyRate != null ? '₹$hourlyRate/hr' : 'Not set'),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 20),
                Align(alignment: Alignment.centerLeft, child: Text('Skills', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                            child: Text(s, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 28),
              if (!isKyc)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppButton(label: '🔐 Complete KYC to Get Paid', onPressed: () => context.push('/kyc')),
                ),
              AppButton(
                label: 'Edit Profile',
                outlined: true,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => EditProfileSheet(user: user),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Logout',
                color: AppColors.error,
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  Widget _tile(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );
}

// Following the sheet-with-local-state pattern used elsewhere in this
// codebase (e.g. the withdraw bottom sheet in earnings_screen.dart).
// PUT /profile/update returns {success, message} with no updated user object
// (verified against profileController.js's updateProfile), so we merge the
// submitted fields into AuthProvider's local user map ourselves on success.
class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileSheet({super.key, required this.user});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _rateCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user['name']?.toString() ?? '');
    _bioCtrl = TextEditingController(text: widget.user['bio']?.toString() ?? '');
    _skillsCtrl = TextEditingController(text: (widget.user['skills'] as List?)?.join(', ') ?? '');
    _rateCtrl = TextEditingController(text: widget.user['hourlyRate']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final skills = _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final rate = num.tryParse(_rateCtrl.text.trim());

    setState(() => _submitting = true);
    try {
      await DioClient.instance.dio.put(ApiConstants.updateProfile, data: {
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'skills': skills,
        // hourlyRate is accepted by profileController.js's updateProfile whitelist.
        if (rate != null) 'hourlyRate': rate,
      });
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.patchLocalUser({
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'skills': skills,
        if (rate != null) 'hourlyRate': rate,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Profile updated'), backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.extract(e)), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit Profile', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppTextField(controller: _nameCtrl, hint: 'Full name', icon: Icons.person_outline),
          const SizedBox(height: 12),
          AppTextField(controller: _bioCtrl, hint: 'Short bio', icon: Icons.edit_note, maxLines: 3),
          const SizedBox(height: 12),
          AppTextField(controller: _skillsCtrl, hint: 'Skills (comma separated)', icon: Icons.build_outlined),
          const SizedBox(height: 12),
          AppTextField(controller: _rateCtrl, hint: 'Hourly rate (₹)', icon: Icons.currency_rupee, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          AppButton(label: 'Save Changes', loading: _submitting, onPressed: _save),
        ]),
      ),
    );
  }
}
