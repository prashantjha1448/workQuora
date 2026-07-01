import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/post_job_controller.dart';
import '../widgets/post_job_step_indicator.dart';
import '../widgets/skill_chip_input.dart';

class PostJobScreen extends ConsumerWidget {
  const PostJobScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Soft client-side gate. The server enforces this for real inside
    // jobController.createJob (Aadhaar + PAN check) — this just saves the
    // user from filling a 4-step form only to hit a 400 at the end.
    if (user != null && !user.kycVerified) {
      return const _KycGateScreen();
    }

    final state = ref.watch(postJobControllerProvider);

    if (state.createdJob != null) {
      return const _SuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: state.step == 0
            ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/home'))
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => ref.read(postJobControllerProvider.notifier).prevStep(),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackMd),
              child: PostJobStepIndicator(currentStep: state.step),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Padding(
                  key: ValueKey(state.step),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                  child: SingleChildScrollView(child: _StepBody(step: state.step)),
                ),
              ),
            ),
            _BottomBar(state: state),
          ],
        ),
      ),
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({required this.step});
  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (step) {
      case 0:
        return const _BasicsStep();
      case 1:
        return const _DetailsStep();
      case 2:
        return const _BudgetStep();
      default:
        return const _ReviewStep();
    }
  }
}

class _BasicsStep extends ConsumerStatefulWidget {
  const _BasicsStep();

  @override
  ConsumerState<_BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends ConsumerState<_BasicsStep> {
  late final _titleController =
      TextEditingController(text: ref.read(postJobControllerProvider).title);
  late final _descriptionController =
      TextEditingController(text: ref.read(postJobControllerProvider).description);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(postJobControllerProvider.notifier);
    final state = ref.watch(postJobControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text("Let's start with the basics", style: textTheme.displayLarge),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          "Tell us what you're looking for. This helps us match you with the right talent.",
          style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Job Title', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: _titleController,
          onChanged: controller.setTitle,
          decoration: const InputDecoration(hintText: 'e.g. Senior Mobile App Developer'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text('Category', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.stackSm),
        DropdownButtonFormField<String>(
          initialValue: state.category.isEmpty ? null : state.category,
          decoration: const InputDecoration(hintText: 'Select a category'),
          items: kJobCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => controller.setCategory(v ?? ''),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text('Job Description', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: _descriptionController,
          onChanged: controller.setDescription,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Briefly describe the key objectives and requirements…',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DetailsStep extends ConsumerStatefulWidget {
  const _DetailsStep();

  @override
  ConsumerState<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<_DetailsStep> {
  late final _addressController =
      TextEditingController(text: ref.read(postJobControllerProvider).address);

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(postJobControllerProvider.notifier);
    final state = ref.watch(postJobControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Skills & location', style: textTheme.displayLarge?.copyWith(fontSize: 26)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'List the skills required and where the work will happen.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Required skills', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.stackSm),
        SkillChipInput(skills: state.skills, onAdd: controller.addSkill, onRemove: controller.removeSkill),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Job location', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: _addressController,
          onChanged: controller.setAddress,
          decoration: const InputDecoration(
            hintText: 'e.g. San Francisco, CA',
            prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.outline),
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        if (state.isLocating)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Detecting your location…'),
            ]),
          )
        else if (state.hasLocation)
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text('Location detected', style: textTheme.labelMedium?.copyWith(color: AppColors.secondary)),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: controller.fetchLocation,
            icon: const Icon(Icons.my_location_rounded, size: 16),
            label: const Text('Use my current location'),
          ),
        if (state.locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(state.locationError!, style: textTheme.labelMedium?.copyWith(color: AppColors.error)),
          ),
        const SizedBox(height: AppSpacing.stackLg),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: state.isUrgent,
          onChanged: controller.toggleUrgent,
          title: const Text('Mark as urgent'),
          subtitle: const Text('Urgent jobs get priority visibility with freelancers'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _BudgetStep extends ConsumerWidget {
  const _BudgetStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(postJobControllerProvider.notifier);
    final state = ref.watch(postJobControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Set your budget', style: textTheme.displayLarge?.copyWith(fontSize: 26)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Give a realistic range — freelancers will bid within it.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Min budget', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
                  const SizedBox(height: AppSpacing.stackSm),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => controller.setMinBudget(num.tryParse(v)),
                    decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Max budget', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
                  const SizedBox(height: AppSpacing.stackSm),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => controller.setMaxBudget(num.tryParse(v)),
                    decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (state.minBudget != null && state.maxBudget != null && state.maxBudget! < state.minBudget!)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Max budget should be greater than or equal to min budget.',
              style: textTheme.labelMedium?.copyWith(color: AppColors.error),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postJobControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(label, style: textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              ),
              Expanded(child: Text(value, style: textTheme.bodyMedium)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Review & post', style: textTheme.displayLarge?.copyWith(fontSize: 26)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Double-check everything before it goes live to freelancers.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                row('Title', state.title),
                row('Category', state.category),
                row('Skills', state.skills.join(', ')),
                row('Budget', '\$${state.minBudget} – \$${state.maxBudget}'),
                row('Location', state.address),
                row('Urgent', state.isUrgent ? 'Yes' : 'No'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text('Description', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: 6),
        Text(state.description, style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        if (state.submitError != null && !state.isKycRequiredError) ...[
          const SizedBox(height: AppSpacing.stackMd),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(state.submitError!.message, style: textTheme.bodyMedium?.copyWith(color: AppColors.onErrorContainer)),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.state});
  final PostJobState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(postJobControllerProvider.notifier);
    final isLastStep = state.step == kPostJobSteps.length - 1;
    final canProceed = controller.canGoNext();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
        AppSpacing.containerMargin,
        AppSpacing.stackMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: AppColors.outlineVariant.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: isLastStep ? 'Post Job' : 'Continue',
          icon: isLastStep ? Icons.bolt_rounded : Icons.arrow_forward_rounded,
          isLoading: state.isSubmitting,
          onPressed: !canProceed
              ? null
              : isLastStep
                  ? controller.submit
                  : controller.nextStep,
        ),
      ),
    );
  }
}

class _KycGateScreen extends ConsumerWidget {
  const _KycGateScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Verify your identity first', style: textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'WorkQuora requires Aadhaar + PAN verification before you can post a job — '
                "it keeps the marketplace safe for everyone.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              PrimaryButton(
                label: 'Complete KYC in Profile',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/profile'),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextButton(
                onPressed: () => ref.read(authControllerProvider.notifier).refreshUser(),
                child: const Text('I just verified — refresh status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessScreen extends ConsumerWidget {
  const _SuccessScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final job = ref.watch(postJobControllerProvider).createdJob!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.secondary, size: 36),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Job posted!', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                '"${job.title}" is now live and visible to freelancers nearby.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              PrimaryButton(
                label: 'Back to Home',
                onPressed: () {
                  ref.read(postJobControllerProvider.notifier).reset();
                  context.go('/home');
                },
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextButton(
                onPressed: () => ref.read(postJobControllerProvider.notifier).reset(),
                child: const Text('Post another job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
