import 'package:flutter/material.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import '../utils/error_helper.dart';

// Worker-specific jobs/proposals provider. NOT the client app's jobs_provider —
// this one is scoped to browsing open jobs and submitting bids.
class JobsProvider extends ChangeNotifier {
  List<dynamic> _nearbyJobs = [];
  List<dynamic> _allJobs = [];
  List<dynamic> _myProposals = [];
  Map<String, dynamic>? _selectedJob;

  bool _isLoadingNearby = false;
  bool _isLoadingAll = false;
  bool _isLoadingJob = false;
  bool _isSubmittingProposal = false;
  bool _isLoadingProposals = false;
  String? _error;

  // Jobs the worker has proposed to during this session, keyed by jobId,
  // since there is no backend "my proposals" list to check against yet.
  final Map<String, Map<String, dynamic>> _localProposals = {};

  List<dynamic> get nearbyJobs => _nearbyJobs;
  List<dynamic> get allJobs => _allJobs;
  List<dynamic> get myProposals => _myProposals;
  Map<String, dynamic>? get selectedJob => _selectedJob;
  bool get isLoadingNearby => _isLoadingNearby;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingJob => _isLoadingJob;
  bool get isSubmittingProposal => _isSubmittingProposal;
  bool get isLoadingProposals => _isLoadingProposals;
  String? get error => _error;

  bool hasProposedTo(String jobId) => _localProposals.containsKey(jobId);
  Map<String, dynamic>? proposalFor(String jobId) => _localProposals[jobId];

  Future<void> fetchNearbyJobs({double lat = 28.6139, double lng = 77.2090, double radius = 25}) async {
    _isLoadingNearby = true;
    notifyListeners();
    try {
      final res = await DioClient.instance.dio.get(
        ApiConstants.nearbyJobs,
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radius},
      );
      _nearbyJobs = res.data['data'] ?? res.data ?? [];
    } catch (_) {
      _nearbyJobs = [];
    }
    _isLoadingNearby = false;
    notifyListeners();
  }

  Future<void> fetchAllJobs() async {
    _isLoadingAll = true;
    notifyListeners();
    try {
      final res = await DioClient.instance.dio.get(ApiConstants.jobs);
      _allJobs = res.data['data'] ?? res.data ?? [];
    } catch (_) {
      _allJobs = [];
    }
    _isLoadingAll = false;
    notifyListeners();
  }

  Future<void> fetchJobById(String jobId) async {
    _isLoadingJob = true;
    _selectedJob = null;
    notifyListeners();
    try {
      final res = await DioClient.instance.dio.get('${ApiConstants.jobs}/$jobId');
      _selectedJob = res.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = ErrorHelper.extract(e);
    }
    _isLoadingJob = false;
    notifyListeners();
  }

  Future<bool> submitProposal({
    required String jobId,
    required num bidAmount,
    required int estimatedDays,
    required String coverLetter,
  }) async {
    _isSubmittingProposal = true;
    _error = null;
    notifyListeners();
    try {
      final res = await DioClient.instance.dio.post(
        '${ApiConstants.proposals}/$jobId',
        data: {
          'coverLetter': coverLetter,
          'bidAmount': bidAmount,
          'estimatedDays': estimatedDays,
        },
      );
      final proposal = res.data['data'] as Map<String, dynamic>?;
      _localProposals[jobId] = proposal ??
          {
            'coverLetter': coverLetter,
            'bidAmount': bidAmount,
            'estimatedDays': estimatedDays,
            'status': 'pending',
          };
      _isSubmittingProposal = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHelper.extract(e);
      _isSubmittingProposal = false;
      notifyListeners();
      return false;
    }
  }

  // NOTE: GET /proposals/my-proposals does not exist on the backend yet
  // (verified against proposalRoutes.js — only POST /:jobId, GET /job/:jobId,
  // PUT /:id/accept and PUT /:id/reject exist). We still call it so the UI is
  // ready the day it ships, but always degrade to an empty list on failure.
  Future<void> fetchMyProposals() async {
    _isLoadingProposals = true;
    notifyListeners();
    try {
      final res = await DioClient.instance.dio.get('${ApiConstants.proposals}/my-proposals');
      _myProposals = res.data['data'] ?? res.data ?? [];
    } catch (_) {
      _myProposals = [];
    }
    _isLoadingProposals = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
