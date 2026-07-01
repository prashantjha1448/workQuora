import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/location/location_service.dart';
import '../data/discover_providers.dart';
import '../data/models/talent_model.dart';

const kDiscoverCategories = <String>[
  'All',
  'Design & Creative',
  'Development',
  'Marketing',
  'Writing',
  'Cybersecurity',
  'Data & AI',
];

const _kPageBatchSize = 10;

class DiscoverState {
  const DiscoverState({
    this.allResults = const [],
    this.visibleCount = _kPageBatchSize,
    this.category = 'All',
    this.keyword = '',
    this.isLoading = false,
    this.isLocating = false,
    this.error,
    this.hasLocation = false,
  });

  final List<TalentModel> allResults;
  final int visibleCount;
  final String category;
  final String keyword;
  final bool isLoading;
  final bool isLocating;
  final AppFailure? error;
  final bool hasLocation;

  List<TalentModel> get visibleResults => allResults.take(visibleCount).toList();
  bool get canLoadMore => visibleCount < allResults.length;

  DiscoverState copyWith({
    List<TalentModel>? allResults,
    int? visibleCount,
    String? category,
    String? keyword,
    bool? isLoading,
    bool? isLocating,
    AppFailure? error,
    bool clearError = false,
    bool? hasLocation,
  }) {
    return DiscoverState(
      allResults: allResults ?? this.allResults,
      visibleCount: visibleCount ?? this.visibleCount,
      category: category ?? this.category,
      keyword: keyword ?? this.keyword,
      isLoading: isLoading ?? this.isLoading,
      isLocating: isLocating ?? this.isLocating,
      error: clearError ? null : (error ?? this.error),
      hasLocation: hasLocation ?? this.hasLocation,
    );
  }
}

class DiscoverController extends Notifier<DiscoverState> {
  Timer? _debounce;
  double? _lat;
  double? _lng;

  @override
  DiscoverState build() {
    ref.onDispose(() => _debounce?.cancel());
    // Kick off location + first search right after first build.
    Future.microtask(_bootstrap);
    return const DiscoverState();
  }

  Future<void> _bootstrap() async {
    state = state.copyWith(isLocating: true, clearError: true);
    try {
      final position = await LocationService().getCurrentPosition();
      _lat = position.lat;
      _lng = position.lng;
      state = state.copyWith(isLocating: false, hasLocation: true);
      await _search();
    } on LocationFailure catch (e) {
      state = state.copyWith(isLocating: false, error: AppFailure.fromMessage(e.message));
    } catch (_) {
      state = state.copyWith(
        isLocating: false,
        error: AppFailure.fromMessage('Could not get your location.'),
      );
    }
  }

  Future<void> _search() async {
    if (_lat == null || _lng == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(discoverRepositoryProvider);
    final result = await repo.searchTalent(
      lat: _lat!,
      lng: _lng!,
      category: state.category,
      keyword: state.keyword,
    );
    result.match(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (talents) => state = state.copyWith(
        isLoading: false,
        allResults: talents,
        visibleCount: _kPageBatchSize,
      ),
    );
  }

  void setCategory(String category) {
    if (category == state.category) return;
    state = state.copyWith(category: category);
    _search();
  }

  /// Debounced — avoids firing a network request on every keystroke. At
  /// scale this single change is the difference between O(keystrokes) and
  /// O(pauses-in-typing) requests hitting the search service.
  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> refresh() => _search();

  /// Reveals the next batch from the already-fetched in-memory list — this
  /// is a client-side mitigation only. The real fix is backend pagination
  /// (page/limit) on GET /geo/nearby-freelancers; flagged in README.
  void loadMore() {
    if (!state.canLoadMore) return;
    state = state.copyWith(visibleCount: state.visibleCount + _kPageBatchSize);
  }

  Future<void> retryLocation() => _bootstrap();
}

final discoverControllerProvider = NotifierProvider<DiscoverController, DiscoverState>(
  DiscoverController.new,
);
