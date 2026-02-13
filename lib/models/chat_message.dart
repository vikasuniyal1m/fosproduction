/// Chat Message Model
class ChatMessage {
  final int id;
  final String senderType; // 'user', 'bot', 'admin'
  final String message;
  final String messageType; // 'text', 'image', 'file', 'quick_reply'
  final bool isRead;
  final String createdAt;
  
  ChatMessage({
    required this.id,
    required this.senderType,
    required this.message,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      senderType: json['sender_type'] as String? ?? 'user',
      message: json['message'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_type': senderType,
      'message': message,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
  
  bool get isUser => senderType == 'user';
  bool get isBot => senderType == 'bot';
  bool get isAdmin => senderType == 'admin';
}

