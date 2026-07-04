import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<KycProvider>().fetchStatus());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kyc = context.watch<KycProvider>();
    final user = auth.user ?? {};
    final name = user['name'] ?? 'User';
    final email = user['email'] ?? '';
    final isEmail = user['isEmailVerified'] == true;
    // The Kyc-model-level status (5-of-5 steps) is the live source of truth
    // during the flow; fall back to the cached User.isKycVerified flag
    // (core PAN+Aadhaar-driven) if KYC status hasn't loaded yet.
    final isKyc = kyc.isFullyVerified || (kyc.status == null && user['isKycVerified'] == true);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: AppColors.bg, expandedHeight: 200, pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => const _EditProfileSheet(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => context.push('/settings'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF7C3AED), Color(0xFF06B6D4)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                const Text('Client', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _badge(isEmail ? '✉ Email Verified' : '✉ Email Unverified', isEmail ? AppColors.emerald : AppColors.textMuted),
            const SizedBox(width: 10),
            _badge(isKyc ? '✓ KYC Verified' : '! KYC Pending', isKyc ? AppColors.emerald : AppColors.warning),
          ]),
          const SizedBox(height: 28),
          _tile(Icons.email_outlined, 'Email', email),
          _tile(Icons.phone_outlined, 'Mobile', user['mobileNumber'] ?? 'Not added'),
          _tile(Icons.badge_outlined, 'Username', '@${user['username'] ?? ''}'),
          _tile(Icons.shield_outlined, 'KYC Status', isKyc ? 'Verified ✓' : 'Pending — Complete KYC'),
          const SizedBox(height: 28),
          if (isKyc)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emerald),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified, color: AppColors.emerald, size: 16),
                  SizedBox(width: 6),
                  Text('KYC Verified', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold)),
                ]),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppButton(
                label: '🔐 Complete KYC Verification',
                onPressed: () { kyc.fetchStatus(); context.push('/kyc'); },
              ),
            ),
          AppButton(label: 'Logout', onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); }, color: AppColors.error),
          const SizedBox(height: 20),
        ]))),
      ]),
    );
  }

  Widget _badge(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));

  Widget _tile(IconData icon, String label, String value) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Icon(icon, color: AppColors.textMuted, size: 18), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text(value, style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
      ])),
    ]));
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _skillsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user ?? {};
    _nameCtrl = TextEditingController(text: user['name'] ?? '');
    _bioCtrl = TextEditingController(text: user['bio'] ?? '');
    final skills = user['skills'];
    _skillsCtrl = TextEditingController(text: skills is List ? skills.join(', ') : '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _bioCtrl.dispose(); _skillsCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    final skills = _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final ok = await context.read<AuthProvider>().updateProfile({
      'name': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'skills': skills,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success));
    } else {
      final err = context.read<AuthProvider>().error ?? 'Failed to update profile';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Edit Profile', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AppTextField(controller: _nameCtrl, hint: 'Full Name', icon: Icons.person_outline),
          const SizedBox(height: 12),
          AppTextField(controller: _bioCtrl, hint: 'Bio', icon: Icons.info_outline, maxLines: 3),
          const SizedBox(height: 12),
          AppTextField(controller: _skillsCtrl, hint: 'Skills (comma separated)', icon: Icons.star_outline),
          const SizedBox(height: 24),
          AppButton(label: 'Save Changes', loading: _saving, onPressed: _save),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
