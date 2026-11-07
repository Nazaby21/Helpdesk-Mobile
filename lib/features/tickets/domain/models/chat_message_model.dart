class ChatMessageModel {
  const ChatMessageModel({
    this.id,
    required this.ticketId,
    this.senderId,
    required this.sender,
    required this.content,
    this.timestamp,
  });

  final int? id;
  final int ticketId;
  final int? senderId;
  final String sender;
  final String content;
  final String? timestamp;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as int?,
      ticketId: json['ticketId'] as int? ?? 0,
      senderId: json['senderId'] as int?,
      sender: json['sender'] as String? ?? 'User',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'sender': sender,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
