import 'package:flutter/foundation.dart';
import 'package:helpdesk_mobile/app/constants/api_endpoints.dart';
import 'package:helpdesk_mobile/core/network/api_client.dart';
import 'package:helpdesk_mobile/core/network/api_error.dart';
import 'package:helpdesk_mobile/core/services/push_notification_service.dart';
import 'package:helpdesk_mobile/core/storage/secure_storage.dart';
import '../../data/auth_state.dart';
import '../../domain/user_role.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.storage,
    required this.apiClient,
    this.pushNotificationService,
  });

  final SecureStorage storage;
  final ApiClient apiClient;
  final PushNotificationService? pushNotificationService;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  /// Initializes auth state on app launch from SecureStorage.
  Future<void> initialize() async {
    final token = await storage.getAccessToken();
    final refreshToken = await storage.getRefreshToken();
    final roleString = await storage.getUserRole();
    final userId = await storage.getUserId();
    final email = await storage.getUserEmail();

    if (token != null && token.isNotEmpty) {
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: token,
        refreshToken: refreshToken,
        role: UserRole.fromString(roleString),
        userId: userId,
        email: email,
      );
      notifyListeners();
      await pushNotificationService?.onUserAuthenticated();
    } else {
      _state = _state.copyWith(status: AuthStatus.unauthenticated);
      notifyListeners();
    }
  }

  /// Performs user sign-in against the backend.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final roleString = data['role'] as String?;
      final role = UserRole.fromString(roleString);

      // Save credentials into secure hardware storage
      await storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      if (roleString != null) {
        await storage.saveUserRole(roleString);
      }
      await storage.saveUserEmail(email);

      // Reconciled requirement: Fetch GET /users/me if needed.
      int? resolvedUserId = (data['id'] as num?)?.toInt();
      if (resolvedUserId != null) {
        await storage.saveUserId(resolvedUserId);
      } else {
        try {
          final meResponse = await apiClient.get(ApiEndpoints.userMe);
          if (meResponse.data is Map<String, dynamic>) {
            final meData = meResponse.data as Map<String, dynamic>;
            resolvedUserId = meData['id'] as int?;
            if (resolvedUserId != null) {
              await storage.saveUserId(resolvedUserId);
            }
          }
        } catch (_) {
          // Non-blocking: proceed with login even if /users/me fails
        }
      }

      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role,
        userId: resolvedUserId,
        email: email,
        isLoading: false,
      );
      notifyListeners();

      // Register FCM device token and refresh unread notifications
      await pushNotificationService?.onUserAuthenticated();

      return true;
    } on ApiError catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected login error occurred.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Gracefully signs out by unregistering device token, notifying the backend, and wiping local tokens.
  Future<void> logout() async {
    // Unregister FCM device token via DELETE /api/devices/{token} before revoking auth
    await pushNotificationService?.onUserLogout();

    final storedRefreshToken =
        _state.refreshToken ?? await storage.getRefreshToken();

    if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
      try {
        await apiClient.post(
          ApiEndpoints.logout,
          data: {'refreshToken': storedRefreshToken},
        );
      } catch (_) {
        // Ignore network errors on logout
      }
    }

    await storage.clearAuthData();
    _state = const AuthState(status: AuthStatus.unauthenticated);
    notifyListeners();
  }

  /// Invoked by AuthInterceptor when 401 refresh fails.
  void handleSessionExpired() {
    storage.clearAuthData();
    _state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Your session has expired. Please sign in again.',
    );
    notifyListeners();
  }
}
