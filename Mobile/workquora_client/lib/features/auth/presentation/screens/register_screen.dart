import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/registration_controller.dart';
import '../widgets/auth_text_field.dart';
import 'otp_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(registrationControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          mobileNumber: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
          role: 'CLIENT',
        );

    final state = ref.read(registrationControllerProvider);
    if (!mounted) return;
    if (state.step == RegistrationStep.emailOtp) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OtpScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Join as a client', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Post jobs and hire elite freelance talent worldwide.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              AuthTextField(controller: _nameController, hint: 'Full name', icon: Icons.person_outline_rounded),
              const SizedBox(height: AppSpacing.stackMd),
              AuthTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              AuthTextField(
                controller: _mobileController,
                hint: 'Mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              AuthTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                errorText: regState.error?.message,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              PrimaryButton(label: 'Continue', isLoading: regState.isLoading, onPressed: _submit),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
