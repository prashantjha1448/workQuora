import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/talent_model.dart';

class TalentCard extends StatelessWidget {
  const TalentCard({
    super.key,
    required this.talent,
    required this.onMessage,
    required this.onHire,
    this.onTap,
  });

  final TalentModel talent;
  final VoidCallback onMessage;
  final VoidCallback onHire;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(url: talent.avatar, isVerified: talent.isVerified),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        talent.name,
                        style: textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (talent.title.isNotEmpty)
                        Text(
                          talent.title,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.starRating),
                          const SizedBox(width: 4),
                          Text(talent.averageRating.toStringAsFixed(1), style: textTheme.labelMedium),
                          const SizedBox(width: 8),
                          Text('•', style: textTheme.labelMedium?.copyWith(color: AppColors.outline)),
                          const SizedBox(width: 8),
                          Text(
                            talent.hourlyRate > 0 ? '\$${talent.hourlyRate}/hr' : 'Rate on request',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (talent.distance > 0) ...[
                            const SizedBox(width: 8),
                            Text('•', style: textTheme.labelMedium?.copyWith(color: AppColors.outline)),
                            const SizedBox(width: 8),
                            Text('${talent.distance} km', style: textTheme.labelSmall),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (talent.skills.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stackMd),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: talent.skills
                    .take(3)
                    .map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: const Text('Message'),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onHire,
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Hire'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.isVerified});
  final String? url;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.stackSm),
          child: url == null || url!.isEmpty
              ? Container(
                  width: 56,
                  height: 56,
                  color: AppColors.surfaceContainer,
                  child: const Icon(Icons.person_rounded, color: AppColors.outline),
                )
              : CachedNetworkImage(
                  imageUrl: url!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  // Downscale decode target — avoids decoding a huge source
                  // image just to show a 56x56 thumbnail (big memory win
                  // across a long scrollable list at scale).
                  memCacheWidth: 112,
                  memCacheHeight: 112,
                  placeholder: (context, _) => Shimmer.fromColors(
                    baseColor: AppColors.surfaceContainer,
                    highlightColor: AppColors.surfaceContainerLow,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, _, __) => Container(
                    color: AppColors.surfaceContainer,
                    child: const Icon(Icons.person_rounded, color: AppColors.outline),
                  ),
                ),
        ),
        if (isVerified)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded, size: 16, color: AppColors.verifiedBlue),
            ),
          ),
      ],
    );
  }
}
