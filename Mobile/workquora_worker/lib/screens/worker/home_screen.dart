import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/utils/time_utils.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});
  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    context.read<DashboardProvider>().fetchDashboard();
    final pos = await _resolvePosition();
    if (!mounted) return;
    context.read<JobsProvider>().fetchNearbyJobs(lat: pos.latitude, lng: pos.longitude);
  }

  // Best-effort location fetch; falls back to a default New Delhi point so
  // nearby jobs still render for users who deny the permission.
  Future<Position> _resolvePosition() async {
    const fallback = 28.6139;
    const fallbackLng = 77.2090;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return Position(
          latitude: fallback, longitude: fallbackLng, timestamp: DateTime.now(),
          accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
        );
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return Position(
        latitude: fallback, longitude: fallbackLng, timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobs = context.watch<JobsProvider>();
    final dash = context.watch<DashboardProvider>();
    final user = auth.user ?? {};
    final name = (user['name'] ?? 'Worker').toString().split(' ').first;
    final avail = user['isAvailable'] == true;
    final isKyc = user['isKycVerified'] == true;
    final rating = (user['averageRating'] ?? 0.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _load,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hi $name 👋', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                      GestureDetector(
                        onTap: () => auth.updateAvailability(!avail),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: avail ? AppColors.primary : AppColors.textSecondary, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(avail ? 'Online — receiving jobs' : 'Offline', style: TextStyle(color: avail ? AppColors.primary : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.push('/notifications'),
                  ),
                  IconButton(
                    icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.go('/earnings'),
                  ),
                ]),
              ),
            ),
            if (!isKyc)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push('/kyc'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withOpacity(0.4))),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Complete KYC to start earning', style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
                      ]),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  children: [
                    _statCard('Active Projects', '${dash.pendingTasks}', Icons.work_outline, AppColors.primary),
                    _statCard('Total Earned', formatCurrency(dash.allTimeIncome), Icons.currency_rupee, AppColors.primary),
                    _statCard('Completion Rate', '${dash.completionRate.toStringAsFixed(0)}%', Icons.check_circle_outline, AppColors.info),
                    _statCard('Avg Rating', rating > 0 ? rating.toStringAsFixed(1) : '—', Icons.star_outline, AppColors.warning),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Nearby Jobs', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  GestureDetector(onTap: () => context.go('/jobs'), child: Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
            jobs.isLoadingNearby
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Shimmer.fromColors(
                          baseColor: AppColors.surface,
                          highlightColor: AppColors.surface2,
                          child: Container(height: 100, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18))),
                        ),
                      ),
                      childCount: 3,
                    ),
                  )
                : jobs.nearbyJobs.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
                            child: Column(children: [
                              Icon(Icons.search_off, color: AppColors.textSecondary, size: 40),
                              const SizedBox(height: 10),
                              Text('No nearby jobs right now', style: TextStyle(color: AppColors.textSecondary)),
                            ]),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _jobCard(context, jobs.nearbyJobs[i]),
                            childCount: jobs.nearbyJobs.take(5).length,
                          ),
                        ),
                      ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _quickAction(context, 'Browse Jobs', Icons.work_outline, () => context.go('/jobs'))),
                    const SizedBox(width: 12),
                    Expanded(child: _quickAction(context, 'My Proposals', Icons.description_outlined, () => context.push('/proposals'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _quickAction(context, 'My Earnings', Icons.account_balance_wallet_outlined, () => context.go('/earnings'))),
                    const SizedBox(width: 12),
                    Expanded(child: Container()),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String label, String val, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ]),
      );

  Widget _quickAction(BuildContext context, String label, IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _jobCard(BuildContext context, Map<String, dynamic> job) {
    final title = job['title'] ?? 'Job';
    final budgetMin = job['budgetRange']?['min'] ?? job['budget'] ?? 0;
    final budgetMax = job['budgetRange']?['max'];
    final cat = job['category'] ?? '';
    final id = (job['_id'] ?? job['id'] ?? '').toString();
    final posted = timeAgo(job['createdAt']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('$cat', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          if (posted.isNotEmpty) Text(posted, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(budgetMax != null ? '₹$budgetMin - ₹$budgetMax' : '₹$budgetMin', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: id.isEmpty ? null : () => context.push('/job/$id'),
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
            child: Text('View', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}
