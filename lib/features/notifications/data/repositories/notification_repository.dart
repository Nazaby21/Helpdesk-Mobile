import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationPageModel> getNotifications({
    int page = 0,
    int size = 10,
    bool unreadOnly = false,
  });

  Future<int> getUnreadCount();

  Future<NotificationModel> markAsRead(int id);

  Future<int> markAllAsRead();

  Future<void> deleteNotification(int id);

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });

  Future<void> unregisterDeviceToken(String token);
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<NotificationPageModel> getNotifications({
    int page = 0,
    int size = 10,
    bool unreadOnly = false,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': page,
        'size': size,
        'unreadOnly': unreadOnly,
      },
    );
    return NotificationPageModel.fromJson(response.data);
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await apiClient.get(ApiEndpoints.unreadNotificationsCount);
    final data = response.data;
    if (data is num) {
      return data.toInt();
    }
    if (data is Map<String, dynamic>) {
      final count = data['unreadCount'] ?? data['count'];
      if (count is num) {
        return count.toInt();
      }
    }
    return 0;
  }

  @override
  Future<NotificationModel> markAsRead(int id) async {
    final response = await apiClient.patch(
      ApiEndpoints.markNotificationRead(id),
    );
    return NotificationModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await apiClient.patch(
      ApiEndpoints.markAllNotificationsRead,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['updatedCount'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  @override
  Future<void> deleteNotification(int id) async {
    await apiClient.delete(ApiEndpoints.deleteNotification(id));
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await apiClient.post(
      ApiEndpoints.devices,
      data: {
        'token': token,
        'deviceToken': token,
        'platform': platform,
      },
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await apiClient.delete(ApiEndpoints.unregisterDevice(token));
  }
}
