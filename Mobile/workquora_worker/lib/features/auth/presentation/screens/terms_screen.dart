import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/core_providers.dart';

/// One-time Terms & Conditions gate.
/// Shown ONCE, right after a worker verifies their email during registration.
/// Acceptance is persisted in secure storage under `terms_accepted_v1`; the
/// router checks this key so it's never shown again on later logins. The
/// worker cannot proceed to /home until the box is checked and Accepted.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _checked = false;
  bool _saving = false;

  Future<void> _accept() async {
    if (!_checked || _saving) return;
    setState(() => _saving = true);
    final storage = ref.read(secureStorageProvider);
    await storage.write('terms_accepted_v1', 'true');
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final tt = AppTypography.light;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.primary, borderRadius: AppRadius.mdR),
                    child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Terms & Conditions',
                      style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppRadius.lgR,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _termsText,
                    style: tt.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant, height: 1.6),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _checked,
                    onChanged: (v) => setState(() => _checked = v ?? false),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                        'I have read and agree to the Terms of Service, Platform Fee & GST policy, and Privacy Policy.',
                        style: tt.bodyMedium),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _checked ? AppColors.primary : AppColors.surfaceContainerHigh,
                        foregroundColor: _checked ? Colors.white : AppColors.outline,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
                      ),
                      onPressed: _checked && !_saving ? _accept : null,
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Accept & Continue',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _termsText = '''
Welcome to WorkQuora.

1. PLATFORM FEE & GST
When you complete a job, WorkQuora deducts a platform service fee plus applicable GST (as per the prevailing GST rate) from the settled amount, similar to other on-demand marketplaces. The exact breakdown is shown on every settlement before payout.

2. SKILLS & MATCHING
You must list at least 1 and at most 5 skills. Jobs are matched and recommended to you based on these skills, your location, your rating, and your track record (jobs completed, success rate, response time).

3. RATINGS
Clients rate you after each completed job. Your rating, number of completed jobs, success rate and response time affect your ranking in client search results.

4. COMMUNICATION
Clients initiate conversations. You cannot cold-message a client directly; you may only reply once a client has messaged you about a job.

5. IDENTITY VERIFICATION (KYC)
To withdraw funds you must complete KYC (Aadhaar, PAN, and bank verification). KYC requests are reviewed and approved by WorkQuora administrators.

6. WALLET & PAYMENTS
Your wallet is secured with a PIN. All transactions are processed through secured payment channels.

7. DATA & CHATS
Chats may be cleared from your device when both parties confirm a job is complete, but a record is retained securely in our systems as required by law.

By tapping "Accept & Continue" you agree to these terms. This screen is shown only once, at sign-up.
''';
