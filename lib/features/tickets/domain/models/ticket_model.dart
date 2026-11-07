class TicketStatusLogModel {
  const TicketStatusLogModel({
    this.id,
    this.ticketId,
    this.fromStatus,
    this.toStatus,
    this.changedById,
    this.changedByName,
    this.remark,
    this.changedAt,
  });

  final int? id;
  final int? ticketId;
  final String? fromStatus;
  final String? toStatus;
  final int? changedById;
  final String? changedByName;
  final String? remark;
  final String? changedAt;

  factory TicketStatusLogModel.fromJson(Map<String, dynamic> json) {
    return TicketStatusLogModel(
      id: json['id'] as int?,
      ticketId: json['ticketId'] as int?,
      fromStatus: (json['oldStatus'] ?? json['fromStatus']) as String?,
      toStatus: (json['newStatus'] ?? json['toStatus']) as String?,
      changedById: json['changedById'] as int?,
      changedByName: (json['changedBy'] ?? json['changedByName']) as String?,
      remark: json['remark'] as String?,
      changedAt: json['changedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'oldStatus': fromStatus,
      'newStatus': toStatus,
      'changedById': changedById,
      'changedBy': changedByName,
      'remark': remark,
      'changedAt': changedAt,
    };
  }
}

class TicketAuditHistoryModel {
  const TicketAuditHistoryModel({
    required this.id,
    required this.action,
    required this.comment,
    this.performAt,
    this.ticketId,
  });

  final int id;
  final String action;
  final String comment;
  final String? performAt;
  final int? ticketId;

  factory TicketAuditHistoryModel.fromJson(Map<String, dynamic> json) {
    return TicketAuditHistoryModel(
      id: json['id'] as int? ?? 0,
      action: json['action'] as String? ?? 'UPDATE',
      comment: json['comment'] as String? ?? '',
      performAt: json['performAt'] as String?,
      ticketId: json['ticketId'] as int?,
    );
  }
}

class ActivityNotificationModel {
  const ActivityNotificationModel({
    required this.id,
    required this.title,
    required this.subTitle,
    this.image,
    this.createdAt,
  });

  final int id;
  final String title;
  final String subTitle;
  final String? image;
  final String? createdAt;

  factory ActivityNotificationModel.fromJson(Map<String, dynamic> json) {
    return ActivityNotificationModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      subTitle: json['subTitle'] as String? ?? '',
      image: json['image'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class TicketModel {
  const TicketModel({
    required this.id,
    required this.ticketTitle,
    required this.description,
    required this.priority,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.assignedTo,
    this.assignedName,
    this.logs = const [],
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.completedAt,
    this.imageUrls = const [],
  });

  final int id;
  final String ticketTitle;
  final String description;
  final String priority;
  final String status;
  final int? categoryId;
  final String? categoryName;
  final int? subCategoryId;
  final String? subCategoryName;
  final int? assignedTo;
  final String? assignedName;
  final List<TicketStatusLogModel> logs;
  final int? createdBy;
  final String? createdByName;
  final String? createdAt;
  final String? completedAt;
  final List<String> imageUrls;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final urls = <String>[];
    if (json['imageUrls'] is List) {
      urls.addAll((json['imageUrls'] as List).map((e) => e.toString()));
    } else if (json['imageUrl'] is String && (json['imageUrl'] as String).isNotEmpty) {
      urls.add(json['imageUrl'] as String);
    }

    return TicketModel(
      id: json['id'] as int,
      ticketTitle: json['ticketTitle'] as String? ?? 'Untitled Ticket',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'PENDING',
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      subCategoryId: json['subCategoryId'] as int?,
      subCategoryName: json['subCategoryName'] as String?,
      assignedTo: json['assignedTo'] as int?,
      assignedName: json['assignedName'] as String?,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((item) => TicketStatusLogModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      createdBy: json['createdBy'] as int?,
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as String?,
      completedAt: json['completedAt'] as String?,
      imageUrls: urls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketTitle': ticketTitle,
      'description': description,
      'priority': priority,
      'status': status,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subCategoryId': subCategoryId,
      'subCategoryName': subCategoryName,
      'assignedTo': assignedTo,
      'assignedName': assignedName,
      'logs': logs.map((e) => e.toJson()).toList(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'imageUrls': imageUrls,
    };
  }

  TicketModel copyWith({
    int? id,
    String? ticketTitle,
    String? description,
    String? priority,
    String? status,
    int? categoryId,
    String? categoryName,
    int? subCategoryId,
    String? subCategoryName,
    int? assignedTo,
    String? assignedName,
    List<TicketStatusLogModel>? logs,
    int? createdBy,
    String? createdByName,
    String? createdAt,
    String? completedAt,
    List<String>? imageUrls,
  }) {
    return TicketModel(
      id: id ?? this.id,
      ticketTitle: ticketTitle ?? this.ticketTitle,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedName: assignedName ?? this.assignedName,
      logs: logs ?? this.logs,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
