/// Chat Conversation Model
class ChatConversation {
  final int id;
  final String sessionId;
  final String status; // 'active', 'resolved', 'closed'
  final int messageCount;
  final String lastMessage;
  final String createdAt;
  final String updatedAt;
  
  ChatConversation({
    required this.id,
    required this.sessionId,
    required this.status,
    this.messageCount = 0,
    this.lastMessage = '',
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      messageCount: json['message_count'] as int? ?? 0,
      lastMessage: json['last_message'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'status': status,
      'message_count': messageCount,
      'last_message': lastMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
}

