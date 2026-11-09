class NotificationModel {
  const NotificationModel({
    required this.id,
    this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.ticketId,
    this.link,
    required this.isRead,
    this.createdAt,
    this.readAt,
  });

  final int id;
  final int? recipientId;
  final String type;
  final String title;
  final String message;
  final int? ticketId;
  final String? link;
  final bool isRead;
  final String? createdAt;
  final String? readAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawMessage = (json['message'] ?? json['subTitle'] ?? '').toString();
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      recipientId: (json['recipientId'] as num?)?.toInt(),
      type: (json['type'] ?? 'TICKET_CREATED').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: rawMessage,
      ticketId: (json['ticketId'] as num?)?.toInt(),
      link: json['link']?.toString(),
      isRead: json['isRead'] == true || json['read'] == true,
      createdAt: json['createdAt']?.toString(),
      readAt: json['readAt']?.toString(),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
    String? readAt,
  }) {
    return NotificationModel(
      id: id,
      recipientId: recipientId,
      type: type,
      title: title,
      message: message,
      ticketId: ticketId,
      link: link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class NotificationPageModel {
  const NotificationPageModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
  });

  final List<NotificationModel> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;

  bool get hasMore => pageNumber + 1 < totalPages;

  factory NotificationPageModel.fromJson(dynamic data) {
    if (data is List) {
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      return NotificationPageModel(
        content: items,
        totalElements: items.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: items.isEmpty ? 10 : items.length,
      );
    }
    if (data is Map<String, dynamic>) {
      final rawContent = data['content'] as List<dynamic>? ?? const [];
      final items = rawContent
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      return NotificationPageModel(
        content: items,
        totalElements: (data['totalElements'] as num?)?.toInt() ?? items.length,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
        pageNumber: (data['number'] as num?)?.toInt() ?? 0,
        pageSize: (data['size'] as num?)?.toInt() ?? 10,
      );
    }
    return const NotificationPageModel(
      content: [],
      totalElements: 0,
      totalPages: 1,
      pageNumber: 0,
      pageSize: 10,
    );
  }
}
