import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/socket_service.dart';
import '../../core/utils/error_helper.dart';

class ChatScreen extends StatefulWidget {
  final String jobId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.jobId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isOtherTyping = false;
  bool _isSending = false;
  Timer? _typingTimer;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketService _socket = SocketService();

  String get _myId {
    final user = context.read<AuthProvider>().user;
    return user?['_id']?.toString() ?? user?['id']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setupSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await DioClient.instance.dio.get('/messages/${widget.jobId}/${widget.otherUserId}');
      // Response: { success, data: [...messages] } sorted oldest→newest.
      // Reversed here since the list is rendered with reverse: true.
      setState(() {
        _messages = List<Map<String, dynamic>>.from((res.data['data'] as List).reversed);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.extractError(e)), backgroundColor: AppColors.error));
    }
  }

  void _setupSocket() {
    _socket.joinRoom(widget.jobId, widget.otherUserId);

    _socket.onReceiveMessage((data) {
      if (!mounted) return;
      final senderId = data['senderId']?.toString() ?? data['sender']?.toString();
      if (senderId != _myId) {
        setState(() => _messages.insert(0, data));
        _socket.emitMarkRead(widget.jobId, widget.otherUserId);
      }
    });

    _socket.onTypingStatus((data) {
      if (!mounted) return;
      final userId = data['userId']?.toString();
      if (userId != _myId) {
        setState(() => _isOtherTyping = data['isTyping'] == true);
      }
    });
  }

  @override
  void dispose() {
    _socket.leaveRoom(widget.jobId, widget.otherUserId);
    _socket.offReceiveMessage();
    _socket.offTypingStatus();
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final myId = _myId;

    setState(() {
      _isSending = true;
      _messages.insert(0, {
        '_id': tempId,
        'text': text,
        'sender': myId,
        'senderId': myId,
        'createdAt': DateTime.now().toIso8601String(),
        '_pending': true,
      });
    });
    _controller.clear();

    try {
      final res = await DioClient.instance.dio.post(
        ApiConstants.sendMessage,
        data: {
          'receiverId': widget.otherUserId,
          'jobId': widget.jobId,
          'text': text, // field name is 'text', not 'content'
        },
      );

      final confirmed = res.data['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['_id'] == tempId);
        if (idx != -1) _messages[idx] = confirmed;
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['_id'] == tempId);
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.extractError(e)), backgroundColor: AppColors.error));
    }
  }

  void _onTextChanged(String text) {
    final myId = _myId;
    _socket.emitTyping(jobId: widget.jobId, otherUserId: widget.otherUserId, myUserId: myId, isTyping: text.isNotEmpty);
    _typingTimer?.cancel();
    if (text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _socket.emitTyping(jobId: widget.jobId, otherUserId: widget.otherUserId, myUserId: myId, isTyping: false);
      });
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = (msg['sender'] ?? msg['senderId'])?.toString() == _myId;
    final isPending = msg['_pending'] == true;
    final text = msg['text']?.toString() ?? '';
    final time = _formatTime(msg['createdAt']?.toString() ?? msg['timestamp']?.toString());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: isMe ? 60 : 8, right: isMe ? 8 : 60, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(time, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              if (isMe && isPending) ...[
                const SizedBox(width: 4),
                const Icon(Icons.access_time, size: 10, color: Colors.white60),
              ] else if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 10, color: Colors.white60),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(24)),
            child: TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: _isSending
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.otherUserAvatar ?? '';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
            child: avatar.isEmpty
                ? Text(widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))
                : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('WorkQuora Chat', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: null),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i]),
                ),
        ),
        if (_isOtherTyping)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${widget.otherUserName} is typing', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 4),
              const _TypingDots(),
            ]),
          ),
        _buildInputBar(),
      ]),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  int _dot = 0;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..addListener(() {
        if (_ac.status == AnimationStatus.completed) {
          setState(() => _dot = (_dot + 1) % 3);
          _ac.reset();
          _ac.forward();
        }
      });
    _ac.forward();
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Container(
        width: 4, height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: i == _dot ? Colors.grey : Colors.grey.withOpacity(0.3), shape: BoxShape.circle),
      )),
    );
  }
}
