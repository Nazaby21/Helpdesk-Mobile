import '../domain/user_role.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.email,
    this.role,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final int? userId;
  final String? email;
  final UserRole? role;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && accessToken != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isInitial => status == AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    int? userId,
    String? email,
    UserRole? role,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
