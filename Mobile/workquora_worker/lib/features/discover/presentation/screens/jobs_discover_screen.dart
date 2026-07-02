import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/jobs_discover_controller.dart';
import '../../data/models/job_model.dart';

/// Worker "Browse gigs" screen — matches the green "Featured Opportunities /
/// Urgent Near You" design. Real jobs from /geo/nearby-jobs, ranked by the
/// skill+distance+recency algorithm in JobsDiscoverController.
class JobsDiscoverScreen extends ConsumerWidget {
  const JobsDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobsDiscoverControllerProvider);
    final tt = AppTypography.light;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(jobsDiscoverControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Search
                    Container(
                      decoration: BoxDecoration(
                          color: AppColors.surfaceContainer, borderRadius: AppRadius.mdR),
                      child: TextField(
                        onChanged: (v) =>
                            ref.read(jobsDiscoverControllerProvider.notifier).setKeyword(v),
                        decoration: InputDecoration(
                          hintText: 'Search for gigs...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.outline),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category chips
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kJobCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = kJobCategories[i];
                          final sel = state.category == cat;
                          return GestureDetector(
                            onTap: () => ref
                                .read(jobsDiscoverControllerProvider.notifier)
                                .setCategory(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.surfaceContainer,
                                borderRadius: AppRadius.fullR,
                              ),
                              child: Text(cat,
                                  style: tt.labelMedium?.copyWith(
                                      color: sel ? Colors.white : AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (state.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      )
                    else if (state.error != null)
                      _Error(
                        message: state.error!.message,
                        onRetry: () =>
                            ref.read(jobsDiscoverControllerProvider.notifier).refresh(),
                      )
                    else if (state.jobs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text('No gigs found nearby.',
                              style: tt.bodyLarge?.copyWith(color: AppColors.outline)),
                        ),
                      )
                    else ...[
                      Text('Suggested For You',
                          style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Ranked by your skills, distance & freshness',
                          style: tt.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      ...state.jobs.map((j) => _JobCard(job: j)),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final tt = AppTypography.light;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.lgR,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (job.category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.primaryFixed, borderRadius: AppRadius.fullR),
                  child: Text(job.category.toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                          color: AppColors.onPrimaryFixed, fontWeight: FontWeight.w800)),
                ),
              const Spacer(),
              Text('₹${job.budget}',
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.outline),
              const SizedBox(width: 4),
              Text(
                job.distance > 0
                    ? '${job.distance} miles away'
                    : (job.locationName.isNotEmpty ? job.locationName : 'Nearby'),
                style: tt.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          if (job.skillsRequired.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: job.skillsRequired.take(4).map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainer, borderRadius: AppRadius.fullR),
                  child: Text(s,
                      style: tt.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => context.push('/gig/${job.id}'),
                  child: const Text('Accept Gig', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => context.push('/gig/${job.id}'),
                  child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.light.bodyLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
