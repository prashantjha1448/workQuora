import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      // NOTE: top-level response key is `conversations`, not `data`.
      final res = await DioClient.instance.dio.get(ApiConstants.conversations);
      _conversations = res.data['conversations'] ?? [];
    } catch (_) {
      _conversations = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages'), backgroundColor: AppColors.background, elevation: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _fetch,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _conversations.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(children: [
                        Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text('No conversations yet', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text('Chats unlock once a client messages you or accepts your bid', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                      ]),
                    ),
                  ])
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    itemBuilder: (_, i) {
                      final c = _conversations[i] as Map;
                      final unread = (c['unreadCount'] ?? 0) as int;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.surface2,
                          backgroundImage: (c['profilePic'] ?? '').toString().isNotEmpty ? CachedNetworkImageProvider(c['profilePic']) : null,
                          child: (c['profilePic'] ?? '').toString().isEmpty ? Icon(Icons.person, color: AppColors.textSecondary) : null,
                        ),
                        title: Text(c['name']?.toString() ?? 'User', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '${(c['jobTitle'] ?? '').toString().isNotEmpty ? '${c['jobTitle']} • ' : ''}${c['lastMessage'] ?? ''}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(c['lastMessageTime']?.toString() ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          if (unread > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                        onTap: () => context.push('/chat', extra: {
                          'jobId': c['jobId'],
                          'otherUserId': c['otherUserId'],
                          'name': c['name'],
                          'profilePic': c['profilePic'],
                        }),
                      );
                    },
                  ),
      ),
    );
  }
}
