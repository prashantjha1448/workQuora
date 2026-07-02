import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/review_model.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: review.reviewerAvatar == null || review.reviewerAvatar!.isEmpty
                ? Container(
                    width: 36,
                    height: 36,
                    color: AppColors.surfaceContainer,
                    child: const Icon(Icons.person_rounded, size: 18, color: AppColors.outline),
                  )
                : CachedNetworkImage(
                    imageUrl: review.reviewerAvatar!,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(review.reviewerName, style: textTheme.titleLarge?.copyWith(fontSize: 14)),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMd().format(review.createdAt),
                      style: textTheme.labelSmall?.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 15,
                      color: AppColors.starRating,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(review.comment, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
