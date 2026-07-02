import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/core_providers.dart';
import '../../profile_kyc/application/profile_controller.dart';
import '../data/models/job_model.dart';

/// Worker job-discovery controller.
///
/// Pipeline: detect location → GET /geo/nearby-jobs → rank client-side by a
/// weighted score combining SKILL MATCH (worker's own skills vs job's
/// skillsRequired), DISTANCE (closer = better), and RECENCY. The worker's
/// skills come from their profile (1–5 skills). Category chips and the search
/// box filter the ranked list. Backend has no skill filter yet, so ranking is
/// done here — this is where "suggested by skill + nearest + best match"
/// actually happens.
class JobsDiscoverState {
  const JobsDiscoverState({
    this.jobs = const [],
    this.category = 'All',
    this.keyword = '',
    this.isLoading = true,
    this.error,
    this.hasLocation = false,
  });

  final List<JobModel> jobs; // already ranked + filtered
  final String category;
  final String keyword;
  final bool isLoading;
  final AppFailure? error;
  final bool hasLocation;

  JobsDiscoverState copyWith({
    List<JobModel>? jobs,
    String? category,
    String? keyword,
    bool? isLoading,
    AppFailure? error,
    bool clearError = false,
    bool? hasLocation,
  }) =>
      JobsDiscoverState(
        jobs: jobs ?? this.jobs,
        category: category ?? this.category,
        keyword: keyword ?? this.keyword,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        hasLocation: hasLocation ?? this.hasLocation,
      );
}

const kJobCategories = <String>[
  'All', 'Plumbing', 'Electrical', 'IT Support', 'Cleaning',
  'Carpentry', 'Design', 'Development',
];

class JobsDiscoverController extends Notifier<JobsDiscoverState> {
  List<JobModel> _raw = const [];
  double? _lat, _lng;
  Timer? _debounce;

  @override
  JobsDiscoverState build() {
    Future.microtask(_bootstrap);
    return const JobsDiscoverState();
  }

  Future<void> _bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pos = await LocationService().getCurrentPosition();
      _lat = pos.lat;
      _lng = pos.lng;
      state = state.copyWith(hasLocation: true);
      await _fetch();
    } on LocationFailure catch (e) {
      state = state.copyWith(isLoading: false, hasLocation: false, error: AppFailure.fromMessage(e.message));
    } catch (_) {
      state = state.copyWith(isLoading: false, error: AppFailure.fromMessage('Could not detect location.'));
    }
  }

  Future<void> _fetch() async {
    if (_lat == null || _lng == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get(ApiEndpoints.nearbyJobs, queryParameters: {
        'lat': _lat,
        'lng': _lng,
        'radius': 25,
        if (state.category != 'All') 'category': state.category,
        if (state.keyword.isNotEmpty) 'keyword': state.keyword,
      });
      final list = (res.data['jobs'] ?? res.data['data'] ?? []) as List;
      _raw = list.map((e) => JobModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, jobs: _rank(_raw));
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: AppFailure.fromMessage(
              (e.response?.data is Map ? e.response?.data['message'] : null) ??
                  'Could not load gigs. Please try again.'));
    } catch (_) {
      state = state.copyWith(isLoading: false, error: AppFailure.fromMessage('Unexpected error.'));
    }
  }

  /// Weighted ranking: skill match dominates, then proximity, then recency.
  /// Worker's skills are read from their profile (may be empty until they set
  /// them; then ranking falls back to distance-only).
  List<JobModel> _rank(List<JobModel> jobs) {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    final workerSkills = profile?.skills ?? const <String>[];

    double score(JobModel j) {
      final skill = j.skillOverlap(workerSkills).toDouble(); // 0..5
      final proximity = j.distance <= 0 ? 0.0 : (1 / (1 + j.distance)); // 0..1
      final recency = j.createdAt == null
          ? 0.0
          : (1 / (1 + DateTime.now().difference(j.createdAt!).inHours / 24.0)); // 0..1
      // Skill is the strongest signal (×10), then proximity (×4), then recency (×2).
      return skill * 10 + proximity * 4 + recency * 2;
    }

    final sorted = [...jobs]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  void setCategory(String c) {
    state = state.copyWith(category: c);
    _fetch();
  }

  void setKeyword(String k) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(keyword: k);
      _fetch();
    });
  }

  Future<void> refresh() => _bootstrap();
}

final jobsDiscoverControllerProvider =
    NotifierProvider<JobsDiscoverController, JobsDiscoverState>(JobsDiscoverController.new);
