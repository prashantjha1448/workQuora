import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

/// Thin wrapper around socket_io_client matching the exact event contract
/// in chatSocket.js. Room semantics (verified against server emit logic,
/// NOT the misleading inline comment in chatSocket.js which says
/// "format: jobId_otherUserId" — the room you JOIN is actually
/// `${jobId}_${yourOwnUserId}`, since that's the room the server targets
/// when addressing messages TO you):
///
///   join_room({roomId: '$jobId_$myUserId'})   -> marks unread as read too
///   send_message({jobId, receiverId, text})    -> server resolves rooms
///   typing_status({roomId: '$jobId_$otherUserId', userId: myId, isTyping})
class ChatSocketService {
  ChatSocketService(this._secureStorage);
  final SecureStorageService _secureStorage;

  io.Socket? _socket;

  final _onMessage = StreamController<Map<String, dynamic>>.broadcast();
  final _onTyping = StreamController<Map<String, dynamic>>.broadcast();
  final _onDelivered = StreamController<Map<String, dynamic>>.broadcast();
  final _onRead = StreamController<Map<String, dynamic>>.broadcast();
  final _onConnectionChange = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _onMessage.stream;
  Stream<Map<String, dynamic>> get onTyping => _onTyping.stream;
  Stream<Map<String, dynamic>> get onDelivered => _onDelivered.stream;
  Stream<Map<String, dynamic>> get onRead => _onRead.stream;
  Stream<bool> get onConnectionChange => _onConnectionChange.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _secureStorage.accessToken;
    if (token == null) return;

    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // skip long-polling fallback — lighter on battery/data
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) => _onConnectionChange.add(true))
      ..onDisconnect((_) => _onConnectionChange.add(false))
      ..onConnectError((_) => _onConnectionChange.add(false))
      ..on('receive_message', (data) => _onMessage.add(Map<String, dynamic>.from(data as Map)))
      ..on('typing_status', (data) => _onTyping.add(Map<String, dynamic>.from(data as Map)))
      ..on('messages_delivered', (data) => _onDelivered.add(Map<String, dynamic>.from(data as Map)))
      ..on('messages_read', (data) => _onRead.add(Map<String, dynamic>.from(data as Map)))
      ..connect();
  }

  void joinRoom(String roomId) => _socket?.emit('join_room', {'roomId': roomId});
  void leaveRoom(String roomId) => _socket?.emit('leave_room', {'roomId': roomId});

  void sendMessage({required String jobId, required String receiverId, required String text}) {
    _socket?.emit('send_message', {'jobId': jobId, 'receiverId': receiverId, 'text': text});
  }

  void sendTyping({required String roomId, required String userId, required bool isTyping}) {
    _socket?.emit('typing_status', {'roomId': roomId, 'userId': userId, 'isTyping': isTyping});
  }

  /// Called when the chat screen is popped — tears the connection down
  /// completely rather than just unsubscribing, so no background socket
  /// keeps draining battery while the user browses the rest of the app.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
