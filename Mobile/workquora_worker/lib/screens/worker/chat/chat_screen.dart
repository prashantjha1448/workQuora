import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/error_helper.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String jobId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({super.key, required this.jobId, required this.otherUserId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _blockedReason;

  String get _roomId => '${widget.jobId}_${widget.otherUserId}';

  @override
  void initState() {
    super.initState();
    _fetch();
    SocketService().socket?.emit('join_room', {'roomId': _roomId});
    SocketService().socket?.on('receive_message', _onReceive);
  }

  @override
  void dispose() {
    SocketService().socket?.emit('leave_room', {'roomId': _roomId});
    SocketService().socket?.off('receive_message', _onReceive);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onReceive(dynamic data) {
    if (!mounted || data is! Map) return;
    final myId = context.read<AuthProvider>().user?['_id']?.toString() ?? context.read<AuthProvider>().user?['id']?.toString();
    final msgJobId = (data['job'] ?? '').toString();
    final sender = (data['senderId'] ?? data['sender'])?.toString();
    final receiver = data['receiver']?.toString();
    final matchesThread = msgJobId == widget.jobId &&
        ((sender == widget.otherUserId && receiver == myId) || (sender == myId && receiver == widget.otherUserId));
    if (!matchesThread) return;
    setState(() => _messages = [..._messages, data]);
    _scrollToBottom();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await DioClient.instance.dio.get('/messages/${widget.jobId}/${widget.otherUserId}');
      _messages = res.data['data'] ?? [];
    } catch (_) {
      _messages = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _blockedReason = null;
    });
    try {
      final res = await DioClient.instance.dio.post('/messages', data: {
        'receiverId': widget.otherUserId,
        'jobId': widget.jobId,
        'text': text,
      });
      final payload = res.data['data'];
      if (payload != null) {
        setState(() => _messages = [..._messages, payload]);
        _scrollToBottom();
      }
      _msgCtrl.clear();
    } catch (e) {
      // Server-enforced rule: a freelancer can't initiate a chat unless the
      // client already messaged them or accepted their bid — surface that
      // 403 clearly instead of swallowing it, since it's an expected,
      // actionable state.
      setState(() => _blockedReason = ErrorHelper.extract(e));
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?['_id']?.toString() ?? context.watch<AuthProvider>().user?['id']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.otherUserName), backgroundColor: AppColors.background, elevation: 0),
      body: Column(children: [
        if (_blockedReason != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_blockedReason!, style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
          ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _messages.isEmpty
                  ? Center(child: Text('Say hello 👋', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i] as Map;
                        final senderId = (m['senderId'] ?? m['sender'])?.toString();
                        final isMe = myId != null ? senderId == myId : senderId != widget.otherUserId;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: isMe ? null : Border.all(color: AppColors.border),
                            ),
                            child: Text(m['text']?.toString() ?? '', style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14)),
                          ),
                        );
                      },
                    ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                  child: TextField(
                    controller: _msgCtrl,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isSending ? null : _send,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: _isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
