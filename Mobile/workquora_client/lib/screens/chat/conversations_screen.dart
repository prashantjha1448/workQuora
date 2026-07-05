import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/error_helper.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await DioClient.instance.dio.get(ApiConstants.conversations);
      // Response key is 'conversations', not 'data'.
      _conversations = res.data['conversations'] as List? ?? [];
    } catch (e) {
      _error = ErrorHelper.extractError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    // lastMessageTime is already a localized date string (en-IN) from the
    // backend, not raw ISO — try to parse it, but fall back to showing it
    // verbatim if it doesn't parse as a DateTime.
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Messages'), backgroundColor: AppColors.bg, elevation: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: _loading
            ? ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: 3,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Shimmer.fromColors(
                    baseColor: AppColors.surface,
                    highlightColor: AppColors.surfaceAlt,
                    child: Container(height: 64, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              )
            : _error != null
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    const SizedBox(height: 100),
                    Icon(Icons.error_outline, color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Center(child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted))),
                    const SizedBox(height: 16),
                    Center(child: TextButton(onPressed: _load, child: Text('Retry', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))),
                  ])
                : _conversations.isEmpty
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                        SizedBox(height: 120),
                        Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Center(child: Text('No conversations yet', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600))),
                        SizedBox(height: 6),
                        Center(child: Text('Messages appear after posting a job', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                      ])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _conversations.length,
                        itemBuilder: (_, i) {
                          final convo = _conversations[i];
                          final name = convo['name']?.toString() ?? 'User';
                          final pic = convo['profilePic']?.toString() ?? '';
                          final unread = (convo['unreadCount'] ?? 0) as int;
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              backgroundImage: pic.isNotEmpty ? CachedNetworkImageProvider(pic) : null,
                              child: pic.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
                            ),
                            title: Text(name, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Text(convo['lastMessage']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_timeAgo(convo['lastMessageTime']?.toString()), style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              if (unread > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                  child: Text('$unread', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ]),
                            onTap: () => context.push('/chat', extra: {
                              'jobId': convo['jobId'],
                              'otherUserId': convo['otherUserId'],
                              'otherUserName': name,
                              'otherUserAvatar': pic,
                            }),
                          );
                        },
                      ),
      ),
    );
  }
}
