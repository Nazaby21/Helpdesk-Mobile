/// Relative API endpoint paths.
/// The `/api/v1` prefix is configured in `EnvConfig.apiBaseUrl` (single source of truth).
abstract final class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String userMe = '/users/me';
  static const String users = '/users';
  static String userById(int id) => '/users/$id';

  // Tickets
  static const String tickets = '/tickets';
  static const String myTickets = '/tickets/my';
  static const String ticketHistory = '/tickets/history';
  static const String ticketStats = '/tickets/stats';
  static const String monthlyStats = '/tickets/stats/monthly';
  static const String ticketActivity = '/tickets/activity';
  static String ticketById(int id) => '/tickets/$id';
  static String ticketStatus(int id) => '/tickets/$id/status';
  static String ticketMessages(int ticketId) => '/tickets/$ticketId/messages';
  static String ticketStatusLogs(int ticketId) => '/tickets/$ticketId/status-logs';
  static String ticketAuditHistory(int ticketId) => '/history/ticket/$ticketId';

  // Categories
  static const String categories = '/categories';
  static String categoryById(int id) => '/categories/$id';

  // Departments
  static const String departments = '/departments';
  static String departmentById(int id) => '/departments/$id';

  // Images
  static const String uploadImage = '/images/upload';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadNotificationsCount = '/notifications/unread-count';
  static String markNotificationRead(int id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String deleteNotification(int id) => '/notifications/$id';

  // Device Tokens (FCM)
  static const String devices = '/devices';
  static String unregisterDevice(String token) =>
      '/devices/${Uri.encodeComponent(token)}';
  static const String deviceToken = '/notifications/device-token';

  // WebSocket / STOMP
  static const String wsChatPath = '/ws-chat';
  static const String stompSendDestination = '/app/chat';
  static String stompSubscribeTopic(int ticketId) => '/topic/ticket/$ticketId';
}
