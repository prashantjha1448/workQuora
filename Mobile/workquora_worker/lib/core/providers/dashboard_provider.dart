import 'package:flutter/material.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';

// Wraps GET /dashboard/freelancer — the single source of truth for
// finances/stats/recentTasks used by home_screen.dart, active_work_screen.dart
// and earnings_screen.dart.
class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _finances = {};
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentTasks = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  Map<String, dynamic> get finances => _finances;
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get recentTasks => _recentTasks;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  int get walletBalance => (_finances['walletBalance'] ?? 0) as int;
  int get todayIncome => (_finances['todayIncome'] ?? 0) as int;
  int get allTimeIncome => (_finances['allTimeIncome'] ?? 0) as int;

  int get totalAssignedTasks => (_stats['totalAssignedTasks'] ?? 0) as int;
  int get pendingTasks => (_stats['pendingTasks'] ?? 0) as int;
  int get completedTasks => (_stats['completedTasks'] ?? 0) as int;

  double get completionRate {
    if (totalAssignedTasks == 0) return 0;
    return (completedTasks / totalAssignedTasks) * 100;
  }

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await DioClient.instance.dio.get(ApiConstants.freelancerDashboard);
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      _finances = Map<String, dynamic>.from(data['finances'] ?? {});
      _stats = Map<String, dynamic>.from(data['stats'] ?? {});
      _recentTasks = data['recentTasks'] ?? [];
      _hasLoaded = true;
      _error = null;
    } catch (_) {
      _error = 'Could not load dashboard';
    }
    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic>? findTaskById(String taskId) {
    for (final t in _recentTasks) {
      if ((t['_id'] ?? t['id'])?.toString() == taskId) return Map<String, dynamic>.from(t);
    }
    return null;
  }

  // Used by proposals_screen.dart to resolve an accepted proposal's job to a
  // live task, since no endpoint links a proposal directly to its task.
  Map<String, dynamic>? findTaskByJobId(String jobId) {
    for (final t in _recentTasks) {
      final job = t['job'];
      final jid = job is Map ? (job['_id'] ?? job['id'])?.toString() : job?.toString();
      if (jid == jobId) return Map<String, dynamic>.from(t);
    }
    return null;
  }
}
