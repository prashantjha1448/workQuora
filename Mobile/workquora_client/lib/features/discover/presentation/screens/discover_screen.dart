import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/discover_controller.dart';
import '../widgets/category_chip.dart';
import '../widgets/talent_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Trigger client-side "load more" 300px before the actual bottom —
    // feels instant, no visible loading gap during normal scroll speed.
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(discoverControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(discoverControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    12,
                    AppSpacing.containerMargin,
                    AppSpacing.stackMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Discover Elite Talent', style: textTheme.displayLarge),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        "Connect with the world's most distinguished independent "
                        'professionals for your high-impact projects.',
                        style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => ref.read(discoverControllerProvider.notifier).setKeyword(value),
                        decoration: const InputDecoration(
                          hintText: 'Search expertise, skills, or roles...',
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CategoryChipRow(
                  selected: state.category,
                  onSelected: (c) => ref.read(discoverControllerProvider.notifier).setCategory(c),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.stackMd)),
              ..._buildBody(state),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(DiscoverState state) {
    if (state.isLocating) {
      return [const SliverFillRemaining(hasScrollBody: false, child: _CenteredMessage(message: 'Finding talent near you…'))];
    }

    if (state.error != null && state.allResults.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(
            message: state.error!.message,
            onRetry: () => state.hasLocation
                ? ref.read(discoverControllerProvider.notifier).refresh()
                : ref.read(discoverControllerProvider.notifier).retryLocation(),
          ),
        ),
      ];
    }

    if (state.isLoading && state.allResults.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
          sliver: SliverList.separated(
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (context, index) => const _TalentCardShimmer(),
          ),
        ),
      ];
    }

    if (state.allResults.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _CenteredMessage(message: 'No talent found nearby.\nTry a different search or category.'),
        ),
      ];
    }

    final visible = state.visibleResults;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
        sliver: SliverList.separated(
          itemCount: visible.length + (state.canLoadMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.stackMd),
          itemBuilder: (context, index) {
            if (index >= visible.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
              );
            }
            final talent = visible[index];
            return TalentCard(
              talent: talent,
              onTap: () => context.push('/discover/${talent.id}'),
              onMessage: () {},
              onHire: () {},
            );
          },
        ),
      ),
    ];
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
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
    return Center(
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
    );
  }
}

class _TalentCardShimmer extends StatelessWidget {
  const _TalentCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainer,
      highlightColor: AppColors.surfaceContainerLow,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
