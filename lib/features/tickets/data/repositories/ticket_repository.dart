import 'package:dio/dio.dart';
import 'package:helpdesk_mobile/app/constants/api_endpoints.dart';
import 'package:helpdesk_mobile/core/network/api_client.dart';
import '../../../dashboard/domain/models/dashboard_stats_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/models/ticket_model.dart';

abstract class TicketRepository {
  Future<List<TicketModel>> getMyTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? priority,
    String? search,
  });
  Future<List<TicketModel>> getAllTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? priority,
    String? search,
  });
  Future<List<TicketModel>> getTicketHistory({
    int page = 0,
    int size = 20,
    String? priority,
    String? search,
  });
  Future<TicketModel> getTicketById(int id);
  Future<TicketModel> createTicket({
    required String ticketTitle,
    required String description,
    required String priority,
    required int categoryId,
    int? subCategoryId,
    int? assignedTo,
    List<String> imageUrls = const [],
  });
  Future<TicketModel> updateTicket(
    int id, {
    required String ticketTitle,
    required String description,
    required String priority,
    int? categoryId,
    int? subCategoryId,
    int? assignedTo,
    List<String> imageUrls = const [],
  });
  Future<TicketModel> updateTicketStatus(
    int id, {
    required String status,
    String? remark,
  });
  Future<void> deleteTicket(int id);
  Future<DashboardStatsModel> getDashboardStats();
  Future<MonthlyStatsModel> getMonthlyStats({int? year});
  Future<List<ActivityNotificationModel>> getActivityFeed({int page = 0, int size = 20});
  Future<List<ChatMessageModel>> getTicketMessages(int ticketId);
  Future<ChatMessageModel> sendTicketMessage(
    int ticketId, {
    required String content,
    String? sender,
    int? senderId,
  });
  Future<List<TicketStatusLogModel>> getTicketStatusLogs(int ticketId);
  Future<List<TicketAuditHistoryModel>> getTicketAuditHistory(int ticketId);
  Future<String> uploadImage(List<int> bytes, String filename);
}

class TicketRepositoryImpl implements TicketRepository {
  const TicketRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<TicketModel>> getMyTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? priority,
    String? search,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.myTickets,
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        if (priority != null && priority.isNotEmpty && priority != 'ALL') 'priority': priority,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      return data
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<TicketModel>> getAllTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? priority,
    String? search,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.tickets,
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        if (priority != null && priority.isNotEmpty && priority != 'ALL') 'priority': priority,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<TicketModel>> getTicketHistory({
    int page = 0,
    int size = 20,
    String? priority,
    String? search,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.ticketHistory,
      queryParameters: {
        'page': page,
        'size': size,
        if (priority != null && priority.isNotEmpty && priority != 'ALL') 'priority': priority,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<TicketModel> getTicketById(int id) async {
    final response = await apiClient.get(ApiEndpoints.ticketById(id));
    return TicketModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TicketModel> createTicket({
    required String ticketTitle,
    required String description,
    required String priority,
    required int categoryId,
    int? subCategoryId,
    int? assignedTo,
    List<String> imageUrls = const [],
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.tickets,
      data: {
        'ticketTitle': ticketTitle.trim(),
        'description': description.trim(),
        'priority': priority,
        'categoryId': categoryId,
        'subCategoryId': ?subCategoryId,
        'assignedTo': ?assignedTo,
        'imageUrls': imageUrls,
      },
    );
    return TicketModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TicketModel> updateTicket(
    int id, {
    required String ticketTitle,
    required String description,
    required String priority,
    int? categoryId,
    int? subCategoryId,
    int? assignedTo,
    List<String> imageUrls = const [],
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.ticketById(id),
      data: {
        'ticketTitle': ticketTitle.trim(),
        'description': description.trim(),
        'priority': priority,
        'categoryId': ?categoryId,
        'subCategoryId': ?subCategoryId,
        'assignedTo': ?assignedTo,
        'imageUrls': imageUrls,
      },
    );
    return TicketModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TicketModel> updateTicketStatus(
    int id, {
    required String status,
    String? remark,
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.ticketStatus(id),
      data: {
        'status': status,
        'remark': ?(remark != null && remark.isNotEmpty ? remark.trim() : null),
      },
    );
    return TicketModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTicket(int id) async {
    await apiClient.delete(ApiEndpoints.ticketById(id));
  }

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    final response = await apiClient.get(ApiEndpoints.ticketStats);
    return DashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MonthlyStatsModel> getMonthlyStats({int? year}) async {
    final response = await apiClient.get(
      ApiEndpoints.monthlyStats,
      queryParameters: {
        'year': ?year,
      },
    );
    return MonthlyStatsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ActivityNotificationModel>> getActivityFeed({
    int page = 0,
    int size = 20,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.ticketActivity,
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => ActivityNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      return data
          .map((item) => ActivityNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ChatMessageModel>> getTicketMessages(int ticketId) async {
    final response = await apiClient.get(ApiEndpoints.ticketMessages(ticketId));
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<ChatMessageModel> sendTicketMessage(
    int ticketId, {
    required String content,
    String? sender,
    int? senderId,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.ticketMessages(ticketId),
      data: {
        'ticketId': ticketId,
        'content': content.trim(),
        if (sender != null && sender.isNotEmpty) 'sender': sender,
        'senderId': ?senderId,
      },
    );
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<TicketStatusLogModel>> getTicketStatusLogs(int ticketId) async {
    final response = await apiClient.get(ApiEndpoints.ticketStatusLogs(ticketId));
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => TicketStatusLogModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => TicketStatusLogModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<TicketAuditHistoryModel>> getTicketAuditHistory(int ticketId) async {
    final response = await apiClient.get(ApiEndpoints.ticketAuditHistory(ticketId));
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => TicketAuditHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<String> uploadImage(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await apiClient.post(
      ApiEndpoints.uploadImage,
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String? ?? '';
  }
}
