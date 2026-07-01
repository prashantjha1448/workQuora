import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/conversations_controller.dart';
import '../widgets/conversation_tile.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(conversationsProvider.future),
          child: conversationsAsync.when(
            loading: () => const _LoadingList(),
            error: (error, _) => _ErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(conversationsProvider),
            ),
            data: (conversations) {
              if (conversations.isEmpty) {
                return const _EmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.containerMargin),
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return ConversationTile(
                    conversation: conversation,
                    onTap: () => context.push(
                      '/messages/${conversation.jobId}/${conversation.otherUserId}',
                      extra: {
                        'name': conversation.name,
                        'profilePic': conversation.profilePic,
                        'jobTitle': conversation.jobTitle,
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 40, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text(
                    'No conversations yet.\nMessage a freelancer from a job to get started.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.stackMd),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
