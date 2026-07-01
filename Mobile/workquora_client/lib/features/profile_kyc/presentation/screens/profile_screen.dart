import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/profile_controller.dart';
import 'edit_profile_screen.dart';
import 'kyc_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.stackMd),
                  OutlinedButton(
                    onPressed: () => ref.read(profileControllerProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) return const SizedBox.shrink();
            return RefreshIndicator(
              onRefresh: () => ref.read(profileControllerProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.containerMargin),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryContainer],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Text(profile.name, style: textTheme.headlineMedium),
                        if (profile.username != null)
                          Text('@${profile.username}', style: textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
                        const SizedBox(height: AppSpacing.stackSm),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Row(
                    children: [
                      Expanded(
                        child: _ShortcutCard(
                          icon: profile.kycVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                          label: profile.kycVerified ? 'KYC Verified' : 'Complete KYC',
                          color: profile.kycVerified ? AppColors.secondary : AppColors.promoOrange,
                          background: profile.kycVerified ? AppColors.secondaryContainer : AppColors.errorContainer,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KycScreen())),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: _ShortcutCard(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Wallet',
                          color: AppColors.primary,
                          background: AppColors.primaryFixed,
                          onTap: () => context.push('/wallet'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.outline),
                          title: const Text('Change password'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined, color: AppColors.outline),
                          title: const Text('Notifications'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.shield_outlined, color: AppColors.outline),
                          title: const Text('Identity verification'),
                          subtitle: Text(profile.kycVerified ? 'Verified' : 'Pending'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KycScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log out'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
