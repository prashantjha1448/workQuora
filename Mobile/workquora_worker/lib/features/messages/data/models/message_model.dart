/// Message.js fields, but the REST shape (`sender`/`receiver`/`createdAt`)
/// and the socket payload shape (`senderId`/`timestamp` spread on top of the
/// Mongoose doc) differ slightly — this factory reads both defensively
/// rather than assuming one shape, since that field-name-mismatch pattern
/// has bitten this codebase before (see KYC field mismatch in memory notes).
class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.jobId,
    required this.text,
    this.fileUrl,
    this.fileType = 'text',
    this.status = 'sent',
    this.isRead = false,
    required this.createdAt,
    this.isOptimistic = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String jobId;
  final String text;
  final String? fileUrl;
  final String fileType;
  final String status;
  final bool isRead;
  final DateTime createdAt;
  /// True for a locally-created message awaiting server confirmation —
  /// rendered with a "sending…" affordance, replaced once the real one
  /// arrives over the socket.
  final bool isOptimistic;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final jobField = json['job'];
    final jobId = jobField is Map ? (jobField['_id'] ?? '').toString() : (jobField ?? '').toString();

    return MessageModel(
      id: (json['_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? json['receiver'] ?? '').toString(),
      jobId: jobId,
      text: json['text'] as String? ?? '',
      fileUrl: json['fileUrl'] as String?,
      fileType: json['fileType'] as String? ?? 'text',
      status: json['status'] as String? ?? 'sent',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse((json['timestamp'] ?? json['createdAt'] ?? '') as String? ?? '') ??
          DateTime.now(),
    );
  }

  MessageModel copyWith({String? status, bool? isRead, bool? isOptimistic, String? id}) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId,
      receiverId: receiverId,
      jobId: jobId,
      text: text,
      fileUrl: fileUrl,
      fileType: fileType,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }
}
