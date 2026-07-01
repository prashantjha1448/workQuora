import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/chat_controller.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.jobId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.jobTitle,
  });

  final String jobId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? jobTitle;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  ChatParams get _params => (jobId: widget.jobId, otherUserId: widget.otherUserId);

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(_params));
    final myUserId = ref.watch(currentUserProvider)?.id;

    ref.listen(chatControllerProvider(_params), (prev, next) {
      if ((prev?.messages.length ?? 0) != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipOval(
              child: widget.otherUserAvatar == null || widget.otherUserAvatar!.isEmpty
                  ? Container(
                      width: 36,
                      height: 36,
                      color: AppColors.surfaceContainer,
                      child: const Icon(Icons.person_rounded, size: 18, color: AppColors.outline),
                    )
                  : CachedNetworkImage(
                      imageUrl: widget.otherUserAvatar!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      memCacheWidth: 72,
                      memCacheHeight: 72,
                    ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName ?? 'Conversation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    state.isSocketConnected ? 'Online' : 'Connecting…',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: state.isSocketConnected ? AppColors.secondary : AppColors.outline,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _MessageList(state: state, myUserId: myUserId, scrollController: _scrollController)),
            ChatInputBar(
              onSend: (text) => ref.read(chatControllerProvider(_params).notifier).sendMessage(text),
              onTypingChanged: (isTyping) =>
                  ref.read(chatControllerProvider(_params).notifier).notifyTyping(isTyping),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state, required this.myUserId, required this.scrollController});

  final ChatState state;
  final String? myUserId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.historyError != null && state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            state.historyError!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          'Say hello 👋',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackMd),
      itemCount: state.messages.length + (state.isOtherTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const TypingIndicator();
        }
        final message = state.messages[index];
        return MessageBubble(message: message, isMine: message.senderId == myUserId);
      },
    );
  }
}
