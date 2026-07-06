import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/utils/time_utils.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _category = 'All';

  static const _categories = ['All', 'Plumbing', 'Electrical', 'Painting', 'Carpentry', 'Gardening', 'Cleaning', 'Moving', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<JobsProvider>().fetchAllJobs());
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _filtered(List<dynamic> jobs) {
    return jobs.where((j) {
      final title = (j['title'] ?? '').toString().toLowerCase();
      final desc = (j['description'] ?? '').toString().toLowerCase();
      final cat = (j['category'] ?? '').toString();
      final matchesCategory = _category == 'All' || cat.toLowerCase() == _category.toLowerCase();
      final matchesQuery = _query.isEmpty || title.contains(_query) || desc.contains(_query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobsProvider = context.watch<JobsProvider>();
    final filtered = _filtered(jobsProvider.allJobs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Browse Jobs'), backgroundColor: AppColors.background, elevation: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => context.read<JobsProvider>().fetchAllJobs(),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _categories[i];
                final selected = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(c, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: jobsProvider.isLoadingAll
                ? _skeleton()
                : filtered.isEmpty
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(children: [
                            Icon(Icons.work_off_outlined, color: AppColors.textSecondary, size: 48),
                            const SizedBox(height: 12),
                            Text('No jobs found', style: TextStyle(color: AppColors.textSecondary)),
                          ]),
                        ),
                      ])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _jobCard(context, filtered[i]),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _jobCard(BuildContext context, Map<String, dynamic> job) {
    final title = job['title'] ?? 'Job';
    final desc = job['description'] ?? '';
    final cat = job['category'] ?? '';
    final budgetMin = job['budgetRange']?['min'] ?? job['budget'] ?? 0;
    final budgetMax = job['budgetRange']?['max'];
    final id = (job['_id'] ?? job['id'] ?? '').toString();
    final posted = timeAgo(job['createdAt']?.toString());
    final location = job['location']?['address'] ?? job['location']?['city'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
          Text(budgetMax != null ? '₹$budgetMin-₹$budgetMax' : '₹$budgetMin', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
        ]),
        const SizedBox(height: 6),
        Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('$cat', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          if (location.toString().isNotEmpty) ...[
            Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 13),
            Flexible(child: Text(' $location', style: TextStyle(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
          ],
          const Spacer(),
          if (posted.isNotEmpty) Text(posted, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: id.isEmpty ? null : () => context.push('/job/$id'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('View & Bid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _skeleton() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surface2,
            child: Container(height: 130, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16))),
          ),
        ),
      );
}
