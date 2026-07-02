import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/registration_controller.dart';
import '../widgets/username_field.dart';

/// Worker registration — role is fixed to FREELANCER.
/// Flow: form (with realtime username check) → email OTP → Terms gate → home.
/// Mobile OTP is intentionally SKIPPED for now (feature kept in backend for
/// the future but disabled in the worker flow, per product decision).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  UsernameStatus _usernameStatus = UsernameStatus.idle;

  @override
  void dispose() {
    for (final c in [_name, _email, _username, _password, _otp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submitForm() {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 6) {
      _snack('Please fill all fields (password min 6 chars).');
      return;
    }
    if (_usernameStatus != UsernameStatus.available) {
      _snack('Please pick an available username.');
      return;
    }
    ref.read(registrationControllerProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          username: _username.text.trim(),
          role: 'FREELANCER',
        );
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);
    final tt = AppTypography.light;

    // After email OTP verifies, go to the one-time Terms gate.
    ref.listen(registrationControllerProvider, (prev, next) {
      if (next.step == RegistrationStep.mobileOtp ||
          next.step == RegistrationStep.done) {
        // Mobile OTP disabled → jump straight to Terms after email verify.
        context.go('/terms');
      }
      if (next.error != null && next.error != prev?.error) {
        _snack(next.error!.message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: AppRadius.mdR),
                child: const Center(
                  child: Text('WQ',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.step == RegistrationStep.form
                    ? 'Join as a Professional'
                    : 'Verify your email',
                style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                state.step == RegistrationStep.form
                    ? 'Create your worker account to start finding gigs near you.'
                    : 'We sent a 6-digit code to ${state.email}',
                style: tt.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),

              if (state.step == RegistrationStep.form) ...[
                _label('Full Name'),
                _field(_name, 'Your name', Icons.person_outline_rounded),
                const SizedBox(height: 16),
                _label('Username'),
                UsernameField(
                  controller: _username,
                  onStatusChanged: (s) => setState(() => _usernameStatus = s),
                ),
                const SizedBox(height: 16),
                _label('Email'),
                _field(_email, 'you@example.com', Icons.mail_outline_rounded,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _label('Password'),
                _field(_password, 'Min 6 characters', Icons.lock_outline_rounded,
                    obscure: true),
                const SizedBox(height: 28),
                _primaryButton(
                  label: 'Create Account',
                  loading: state.isLoading,
                  onTap: _submitForm,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text.rich(TextSpan(
                      text: 'Already have an account? ',
                      style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      children: const [
                        TextSpan(
                            text: 'Log in',
                            style: TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    )),
                  ),
                ),
              ] else ...[
                _label('Verification Code'),
                _field(_otp, '6-digit code', Icons.pin_rounded,
                    keyboard: TextInputType.number),
                const SizedBox(height: 28),
                _primaryButton(
                  label: 'Verify & Continue',
                  loading: state.isLoading,
                  onTap: () => ref
                      .read(registrationControllerProvider.notifier)
                      .verifyEmailOtp(_otp.text.trim()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(t,
            style: AppTypography.light.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: AppRadius.mdR),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdR,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _primaryButton(
      {required String label, required bool loading, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
