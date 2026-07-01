import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorText = 'Email aur password dono required hain');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final failure = await ref.read(authControllerProvider.notifier).login(
          emailOrUsername: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (failure != null) {
      setState(() => _errorText = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text('WQ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Welcome back', style: textTheme.displayLarge),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Login to continue hiring top talent on WorkQuora.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              AuthTextField(
                controller: _emailController,
                hint: 'Email or username',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              AuthTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                errorText: _errorText,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              PrimaryButton(label: 'Log in', isLoading: _isLoading, onPressed: _handleLogin),
              const SizedBox(height: AppSpacing.stackLg),
              Center(
                child: Wrap(
                  children: [
                    Text("Don't have an account? ",
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text('Sign up',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}