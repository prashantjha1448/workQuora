import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/error_helper.dart';

class ActiveWorkScreen extends StatefulWidget {
  final String taskId;
  const ActiveWorkScreen({super.key, required this.taskId});
  @override
  State<ActiveWorkScreen> createState() => _ActiveWorkScreenState();
}

class _ActiveWorkScreenState extends State<ActiveWorkScreen> {
  static const _steps = ['assigned', 'traveling', 'working', 'completed'];
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dash = context.read<DashboardProvider>();
      if (!dash.hasLoaded) await dash.fetchDashboard();
    });
  }

  Map<String, dynamic>? _task(DashboardProvider dash) => dash.findTaskById(widget.taskId);

  Future<void> _updateStatus(String next) async {
    setState(() => _updating = true);
    try {
      await DioClient.instance.dio.put('/tasks/${widget.taskId}/status', data: {'status': next});
      if (!mounted) return;
      await context.read<DashboardProvider>().fetchDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked as ${next.toUpperCase()}'), backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.extract(e)), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _confirmComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Mark as Completed?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('This tells the client the job is done and requests payment release. You can\'t undo this.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Confirm', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) _updateStatus('completed');
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final task = _task(dash);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Active Job'), backgroundColor: AppColors.background, elevation: 0),
      body: dash.isLoading && task == null
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : task == null
              ? Center(child: Text('Task not found', style: TextStyle(color: AppColors.textSecondary)))
              : _buildBody(context, task),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> task) {
    final job = task['job'];
    final title = job is Map ? (job['title'] ?? 'Task') : 'Task';
    final budgetMin = job is Map ? (job['budgetRange']?['min'] ?? job['budget'] ?? 0) : 0;
    final status = (task['status'] ?? 'assigned').toString();
    final stepIndex = _steps.indexOf(status).clamp(0, _steps.length - 1);
    // client on Task is just an ObjectId string — no name available from this endpoint.
    final clientId = task['client']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('₹$budgetMin', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          clientId == null ? 'Client info unavailable' : 'Client ID: ${clientId.substring(0, clientId.length > 8 ? 8 : clientId.length)}…',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 28),
        _progressBar(stepIndex),
        const SizedBox(height: 28),
        _actionButton(context, status),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/conversations'),
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 18),
            label: Text('Message Client', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }

  Widget _progressBar(int stepIndex) {
    const labels = ['Assigned', 'Traveling', 'Working', 'Completed'];
    return Row(
      children: List.generate(labels.length, (i) {
        final done = i <= stepIndex;
        return Expanded(
          child: Column(children: [
            Row(children: [
              if (i > 0) Expanded(child: Container(height: 3, color: i <= stepIndex ? AppColors.primary : AppColors.border)),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: done ? AppColors.primary : AppColors.surface, shape: BoxShape.circle, border: Border.all(color: done ? AppColors.primary : AppColors.border, width: 2)),
                child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
              if (i < labels.length - 1) Expanded(child: Container(height: 3, color: i < stepIndex ? AppColors.primary : AppColors.border)),
            ]),
            const SizedBox(height: 6),
            Text(labels[i], style: TextStyle(color: done ? AppColors.primary : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        );
      }),
    );
  }

  Widget _actionButton(BuildContext context, String status) {
    String? label;
    String? next;
    VoidCallback? onTap;

    switch (status) {
      case 'assigned':
        label = 'Start Traveling';
        next = 'traveling';
        break;
      case 'traveling':
        label = 'Start Working';
        next = 'working';
        break;
      case 'working':
        label = 'Mark Completed';
        next = 'completed';
        break;
      default:
        label = null;
    }

    if (label == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: 8),
          Text('Job Completed', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
        ]),
      );
    }

    onTap = next == 'completed' ? _confirmComplete : () => _updateStatus(next!);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _updating ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
        child: _updating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
