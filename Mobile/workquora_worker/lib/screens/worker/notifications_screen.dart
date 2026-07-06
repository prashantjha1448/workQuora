import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/socket_service.dart';
import '../../core/utils/time_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Backend emits real-time notifications as 'receive_notification'
    // (verified in Backend/src/utils/notification.js — io.to(recipient).emit
    // ('receive_notification', ...)). SocketService already auto-joins the
    // user's personal room on connect, so we just need to listen here.
    SocketService().socket?.on('receive_notification', _onReceive);
  }

  void _onReceive(dynamic data) {
    if (!mounted) return;
    setState(() {
      _notifications = [data, ..._notifications];
    });
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await DioClient.instance.dio.get('/notifications');
      _notifications = res.data['notifications'] ?? res.data['data'] ?? [];
    } catch (_) {
      _notifications = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    SocketService().socket?.off('receive_notification', _onReceive);
    super.dispose();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'task_update':
        return Icons.work_outline;
      case 'system_alert':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: AppColors.background, elevation: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _fetch,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _notifications.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(children: [
                        Icon(Icons.notifications_none, color: AppColors.textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary)),
                      ]),
                    ),
                  ])
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i] as Map;
                      final type = (n['type'] ?? '').toString();
                      final isRead = n['isRead'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? AppColors.surface : AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Icon(_iconFor(type), color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n['message']?.toString() ?? '', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(timeAgo(n['createdAt']?.toString()), style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
