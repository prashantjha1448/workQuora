import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/core_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/messages_providers.dart';
import '../data/models/message_model.dart';

typedef ChatParams = ({String jobId, String otherUserId});

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoadingHistory = true,
    this.historyError,
    this.isSending = false,
    this.isOtherTyping = false,
    this.isSocketConnected = false,
  });

  final List<MessageModel> messages;
  final bool isLoadingHistory;
  final String? historyError;
  final bool isSending;
  final bool isOtherTyping;
  final bool isSocketConnected;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoadingHistory,
    String? historyError,
    bool clearHistoryError = false,
    bool? isSending,
    bool? isOtherTyping,
    bool? isSocketConnected,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      historyError: clearHistoryError ? null : (historyError ?? this.historyError),
      isSending: isSending ?? this.isSending,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
    );
  }
}

class ChatController extends AutoDisposeFamilyNotifier<ChatState, ChatParams> {
  StreamSubscription? _messageSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _connectionSub;
  Timer? _typingResetTimer;
  String? _myUserId;
  bool _disposed = false;

  /// The room this user joins to receive everything addressed to them for
  /// this job — see ChatSocketService doc comment for why it's
  /// `${jobId}_${myOwnId}`, not `${jobId}_${otherUserId}`.
  String get _myRoomId => '${arg.jobId}_$_myUserId';
  String get _otherRoomId => '${arg.jobId}_${arg.otherUserId}';

  @override
  ChatState build(ChatParams arg) {
    ref.onDispose(_teardown);
    Future.microtask(_init);
    return const ChatState();
  }

  Future<void> _init() async {
    _myUserId = ref.read(currentUserProvider)?.id;

    // 1. Load history over REST first — instant-feeling even before the
    // socket finishes its handshake.
    final repo = ref.read(messagesRepositoryProvider);
    final result = await repo.getChatHistory(jobId: arg.jobId, otherUserId: arg.otherUserId);
    if (_disposed) return;
    result.match(
      (failure) => state = state.copyWith(isLoadingHistory: false, historyError: failure.message),
      (messages) => state = state.copyWith(isLoadingHistory: false, messages: messages, clearHistoryError: true),
    );

    // 2. Connect socket + join this conversation's room only now that the
    // screen is actually open — never connected ambiently in the background.
    final socket = ref.read(chatSocketServiceProvider);
    await socket.connect();
    if (_disposed) return;
    socket.joinRoom(_myRoomId);

    _connectionSub = socket.onConnectionChange.listen((connected) {
      state = state.copyWith(isSocketConnected: connected);
      if (connected) socket.joinRoom(_myRoomId);
    });
    state = state.copyWith(isSocketConnected: socket.isConnected);

    _messageSub = socket.onMessage.listen(_handleIncomingMessage);

    _typingSub = socket.onTyping.listen((data) {
      if (data['userId'] == arg.otherUserId) {
        _typingResetTimer?.cancel();
        state = state.copyWith(isOtherTyping: data['isTyping'] == true);
        if (data['isTyping'] == true) {
          // Safety net — if a 'stopped typing' event is ever dropped, don't
          // leave the indicator stuck on forever.
          _typingResetTimer = Timer(const Duration(seconds: 6), () {
            state = state.copyWith(isOtherTyping: false);
          });
        }
      }
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> payload) {
    final message = MessageModel.fromJson(payload);
    // Personal rooms receive ALL of this user's conversations — filter down
    // to just this job + this counterpart before touching state.
    final belongsHere = message.jobId == arg.jobId &&
        (message.senderId == arg.otherUserId || message.senderId == _myUserId);
    if (!belongsHere) return;

    if (state.messages.any((m) => m.id == message.id)) return; // already have it

    // Replace the optimistic placeholder for our own just-sent message
    // instead of showing a duplicate bubble.
    if (message.senderId == _myUserId) {
      final optimisticIndex = state.messages.indexWhere((m) => m.isOptimistic && m.text == message.text);
      if (optimisticIndex != -1) {
        final updated = [...state.messages];
        updated[optimisticIndex] = message;
        state = state.copyWith(messages: updated, isSending: false);
        return;
      }
    }

    state = state.copyWith(messages: [...state.messages, message]);
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _myUserId == null) return;

    final optimistic = MessageModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderId: _myUserId!,
      receiverId: arg.otherUserId,
      jobId: arg.jobId,
      text: trimmed,
      status: 'sent',
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    state = state.copyWith(messages: [...state.messages, optimistic], isSending: true);

    ref.read(chatSocketServiceProvider).sendMessage(
          jobId: arg.jobId,
          receiverId: arg.otherUserId,
          text: trimmed,
        );
  }

  void notifyTyping(bool isTyping) {
    if (_myUserId == null) return;
    ref.read(chatSocketServiceProvider).sendTyping(
          roomId: _otherRoomId,
          userId: _myUserId!,
          isTyping: isTyping,
        );
  }

  void _teardown() {
    _disposed = true;
    _messageSub?.cancel();
    _typingSub?.cancel();
    _connectionSub?.cancel();
    _typingResetTimer?.cancel();
    final socket = ref.read(chatSocketServiceProvider);
    socket.leaveRoom(_myRoomId);
    socket.disconnect();
  }
}

final chatControllerProvider =
    NotifierProvider.autoDispose.family<ChatController, ChatState, ChatParams>(ChatController.new);
