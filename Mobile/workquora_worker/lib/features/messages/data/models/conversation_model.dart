class ConversationModel {
  const ConversationModel({
    required this.jobId,
    required this.otherUserId,
    this.jobTitle = '',
    required this.name,
    this.profilePic,
    this.lastMessage = '',
    this.lastMessageTime = '',
    this.unreadCount = 0,
  });

  final String jobId;
  final String otherUserId;
  final String jobTitle;
  final String name;
  final String? profilePic;
  final String lastMessage;
  /// Already formatted server-side (`toLocaleDateString('en-IN')`) — render
  /// as-is rather than re-parsing, to avoid locale mismatches.
  final String lastMessageTime;
  final int unreadCount;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      jobId: json['jobId'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      profilePic: json['profilePic'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] as String? ?? '',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
