import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation, required this.onTap});

  final ConversationModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: hasUnread ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasUnread
              ? [BoxShadow(color: AppColors.outlineVariant.withValues(alpha: 0.25), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            ClipOval(
              child: conversation.profilePic == null || conversation.profilePic!.isEmpty
                  ? Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surfaceContainer,
                      child: const Icon(Icons.person_rounded, color: AppColors.outline),
                    )
                  : CachedNetworkImage(
                      imageUrl: conversation.profilePic!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      memCacheWidth: 96,
                      memCacheHeight: 96,
                    ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: textTheme.titleLarge?.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (conversation.jobTitle.isNotEmpty)
                    Text(
                      conversation.jobTitle,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage,
                    style: textTheme.bodyMedium?.copyWith(
                      color: hasUnread ? AppColors.onSurface : AppColors.onSurfaceVariant,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conversation.lastMessageTime, style: textTheme.labelSmall?.copyWith(color: AppColors.outline)),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
