import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/categories/domain/models/category_model.dart';
import '../../features/categories/presentation/screens/category_management_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/departments/presentation/screens/department_management_screen.dart';
import '../../features/incident_catalog/presentation/screens/incident_catalog_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/domain/models/user_profile_model.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/tickets/presentation/screens/create_ticket_screen.dart';
import '../../features/tickets/presentation/screens/edit_ticket_screen.dart';
import '../../features/tickets/presentation/screens/my_tickets_screen.dart';
import '../../features/tickets/presentation/screens/ticket_detail_screen.dart';
import '../../features/tickets/presentation/screens/ticket_history_screen.dart';
import '../../features/tickets/presentation/screens/ticket_list_screen.dart';
import '../../features/users/presentation/screens/user_form_screen.dart';
import '../../features/users/presentation/screens/user_management_screen.dart';
import 'app_routes.dart';
import 'auth_guard.dart';

GoRouter createAppRouter(AuthController authController) {
  return GoRouter(
    initialLocation: AppRoutes.signIn,
    refreshListenable: authController,
    redirect: (context, state) => authGuardRedirect(context, state, authController.state),
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => LoginScreen(authController: authController),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => DashboardScreen(
          authController: authController,
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.myTickets,
        builder: (context, state) => MyTicketsScreen(
          authController: authController,
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.allTickets,
        builder: (context, state) => TicketListScreen(
          authController: authController,
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.ticketDetail,
        builder: (context, state) {
          final ticketId = state.pathParameters['id'] ?? '';
          return TicketDetailScreen(
            ticketId: ticketId,
            authController: authController,
            apiClient: authController.apiClient,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editTicket,
        builder: (context, state) {
          final ticketId = state.pathParameters['id'] ?? '';
          return EditTicketScreen(
            ticketId: ticketId,
            authController: authController,
            apiClient: authController.apiClient,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.incidentCatalog,
        builder: (context, state) => IncidentCatalogScreen(
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.createTicket,
        builder: (context, state) {
          final subCategoryId = state.pathParameters['subCategoryId'];
          final extra = state.extra as Map<String, dynamic>?;
          return CreateTicketScreen(
            subCategoryId: subCategoryId,
            category: extra?['category'] as CategoryModel?,
            subCategory: extra?['subCategory'] as CategoryModel?,
            apiClient: authController.apiClient,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ticketHistory,
        builder: (context, state) => TicketHistoryScreen(
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => ProfileScreen(
          authController: authController,
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => NotificationsScreen(
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => CategoryManagementScreen(
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.departments,
        builder: (context, state) => DepartmentManagementScreen(
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.users,
        builder: (context, state) => UserManagementScreen(
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.addUser,
        builder: (context, state) => UserFormScreen(
          apiClient: authController.apiClient,
        ),
      ),
      GoRoute(
        path: AppRoutes.editUser,
        builder: (context, state) {
          final user = state.extra as UserProfileModel?;
          return UserFormScreen(
            editingUser: user,
            apiClient: authController.apiClient,
          );
        },
      ),
    ],
  );
}
