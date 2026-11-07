import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_state.dart';
import '../../features/auth/domain/user_role.dart';
import 'app_routes.dart';

/// Evaluates route transition against the current authentication state and user role.
String? authGuardRedirect(BuildContext context, GoRouterState state, AuthState authState) {
  return authGuardRedirectPath(state.matchedLocation, authState);
}

/// Evaluates route transition based purely on matched location path and auth state.
String? authGuardRedirectPath(String currentPath, AuthState authState) {
  final isSigningIn = currentPath == AppRoutes.signIn;

  // Unauthenticated guard
  if (authState.isUnauthenticated) {
    return isSigningIn ? null : AppRoutes.signIn;
  }

  // Authenticated guard
  if (authState.isAuthenticated) {
    final role = authState.role ?? UserRole.user;

    // Prevent staying on sign-in screen if logged in
    if (isSigningIn) {
      return role.isUser ? AppRoutes.myTickets : AppRoutes.dashboard;
    }

    // Regular users cannot access Admin/Technician dashboard, org queue, or categories
    if (role.isUser &&
        (currentPath == AppRoutes.dashboard ||
            currentPath == AppRoutes.allTickets ||
            currentPath.startsWith(AppRoutes.categories))) {
      return AppRoutes.myTickets;
    }

    // Only Admin can access User Management and Department Management
    if (!role.isAdmin &&
        (currentPath.startsWith(AppRoutes.users) ||
            currentPath.startsWith(AppRoutes.departments))) {
      return role.isUser ? AppRoutes.myTickets : AppRoutes.dashboard;
    }
  }

  return null;
}
