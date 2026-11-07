abstract final class AppRoutes {
  static const String signIn = '/auth/sign-in';
  static const String dashboard = '/';
  static const String myTickets = '/user/tickets';
  static const String allTickets = '/tickets';
  static const String ticketDetail = '/tickets/:id';
  static const String editTicket = '/tickets/:id/edit';
  static const String incidentCatalog = '/incident-catalog';
  static const String createTicket = '/incident-catalog/:subCategoryId/create';
  static const String ticketHistory = '/user/history';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // Admin & Technician management routes
  static const String categories = '/categories';
  static const String departments = '/departments';
  static const String users = '/users';
  static const String addUser = '/users/add';
  static const String editUser = '/users/:id/edit';

  static String ticketDetailPath(int id) => '/tickets/$id';
  static String editTicketPath(int id) => '/tickets/$id/edit';
  static String createTicketPath(int subCategoryId) => '/incident-catalog/$subCategoryId/create';
  static String editUserPath(int id) => '/users/$id/edit';
}
