import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/location/location_service.dart';
import '../../discover/application/discover_controller.dart' show kDiscoverCategories;
import '../data/models/job_model.dart';
import '../data/post_job_providers.dart';

const kPostJobSteps = ['Basics', 'Details', 'Budget', 'Review'];

/// Reuses Discover's category list (minus 'All') so client + freelancer
/// taxonomy stays in sync from a single source of truth.
List<String> get kJobCategories => kDiscoverCategories.where((c) => c != 'All').toList();

class PostJobState {
  const PostJobState({
    this.step = 0,
    this.title = '',
    this.category = '',
    this.description = '',
    this.skills = const [],
    this.minBudget,
    this.maxBudget,
    this.isUrgent = false,
    this.address = '',
    this.lat,
    this.lng,
    this.isLocating = false,
    this.locationError,
    this.isSubmitting = false,
    this.submitError,
    this.createdJob,
  });

  final int step;
  final String title;
  final String category;
  final String description;
  final List<String> skills;
  final num? minBudget;
  final num? maxBudget;
  final bool isUrgent;
  final String address;
  final double? lat;
  final double? lng;
  final bool isLocating;
  final String? locationError;
  final bool isSubmitting;
  final AppFailure? submitError;
  final JobModel? createdJob;

  bool get hasLocation => lat != null && lng != null;

  bool get isBasicsValid => title.trim().isNotEmpty && category.isNotEmpty && description.trim().length >= 10;
  bool get isDetailsValid => skills.isNotEmpty && address.trim().isNotEmpty && hasLocation;
  bool get isBudgetValid =>
      minBudget != null && maxBudget != null && minBudget! > 0 && maxBudget! >= minBudget!;

  bool get isKycRequiredError => submitError?.statusCode == 428;

  PostJobState copyWith({
    int? step,
    String? title,
    String? category,
    String? description,
    List<String>? skills,
    num? minBudget,
    bool clearMinBudget = false,
    num? maxBudget,
    bool clearMaxBudget = false,
    bool? isUrgent,
    String? address,
    double? lat,
    double? lng,
    bool? isLocating,
    String? locationError,
    bool clearLocationError = false,
    bool? isSubmitting,
    AppFailure? submitError,
    bool clearSubmitError = false,
    JobModel? createdJob,
  }) {
    return PostJobState(
      step: step ?? this.step,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      minBudget: clearMinBudget ? null : (minBudget ?? this.minBudget),
      maxBudget: clearMaxBudget ? null : (maxBudget ?? this.maxBudget),
      isUrgent: isUrgent ?? this.isUrgent,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isLocating: isLocating ?? this.isLocating,
      locationError: clearLocationError ? null : (locationError ?? this.locationError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      createdJob: createdJob ?? this.createdJob,
    );
  }
}

class PostJobController extends Notifier<PostJobState> {
  @override
  PostJobState build() => const PostJobState();

  void setTitle(String v) => state = state.copyWith(title: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setAddress(String v) => state = state.copyWith(address: v);
  void toggleUrgent(bool v) => state = state.copyWith(isUrgent: v);

  void setMinBudget(num? v) =>
      state = v == null ? state.copyWith(clearMinBudget: true) : state.copyWith(minBudget: v);
  void setMaxBudget(num? v) =>
      state = v == null ? state.copyWith(clearMaxBudget: true) : state.copyWith(maxBudget: v);

  void addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || state.skills.contains(trimmed)) return;
    state = state.copyWith(skills: [...state.skills, trimmed]);
  }

  void removeSkill(String skill) {
    state = state.copyWith(skills: state.skills.where((s) => s != skill).toList());
  }

  Future<void> fetchLocation() async {
    state = state.copyWith(isLocating: true, clearLocationError: true);
    try {
      final position = await LocationService().getCurrentPosition();
      state = state.copyWith(isLocating: false, lat: position.lat, lng: position.lng);
    } on LocationFailure catch (e) {
      state = state.copyWith(isLocating: false, locationError: e.message);
    } catch (_) {
      state = state.copyWith(isLocating: false, locationError: 'Could not get your location.');
    }
  }

  bool canGoNext() {
    switch (state.step) {
      case 0:
        return state.isBasicsValid;
      case 1:
        return state.isDetailsValid;
      case 2:
        return state.isBudgetValid;
      default:
        return true;
    }
  }

  void nextStep() {
    if (!canGoNext()) return;
    if (state.step < kPostJobSteps.length - 1) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void prevStep() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  Future<void> submit() async {
    if (!state.isBasicsValid || !state.isDetailsValid || !state.isBudgetValid) return;
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    final repo = ref.read(postJobRepositoryProvider);
    final result = await repo.createJob(
      title: state.title.trim(),
      description: state.description.trim(),
      category: state.category,
      skillsRequired: state.skills,
      minBudget: state.minBudget!,
      maxBudget: state.maxBudget!,
      lat: state.lat!,
      lng: state.lng!,
      address: state.address.trim(),
      isUrgent: state.isUrgent,
    );
    result.match(
      (failure) => state = state.copyWith(isSubmitting: false, submitError: failure),
      (job) => state = state.copyWith(isSubmitting: false, createdJob: job),
    );
  }

  void reset() => state = const PostJobState();
}

final postJobControllerProvider = NotifierProvider<PostJobController, PostJobState>(
  PostJobController.new,
);
