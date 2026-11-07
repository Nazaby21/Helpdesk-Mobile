import 'package:dio/dio.dart';
import '../../app/constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

typedef SessionExpiredCallback = void Function();

/// Dio QueuedInterceptor managing automatic Bearer token injection
/// and synchronized 401 token refresh queue.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.storage,
    required this.dio,
    required this.refreshBaseUrl,
    this.onSessionExpired,
    Dio? refreshClient,
  }) : _refreshClient = refreshClient ??
            Dio(
              BaseOptions(
                baseUrl: refreshBaseUrl,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final SecureStorage storage;
  final Dio dio;
  final String refreshBaseUrl;
  final SessionExpiredCallback? onSessionExpired;
  final Dio _refreshClient;

  static const String headerRequiresAuth = 'requiresAuth';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra[headerRequiresAuth] as bool? ?? true;
    final isPublicAuthPath = options.path.contains(ApiEndpoints.login) ||
        options.path.contains(ApiEndpoints.refresh);

    if (!requiresAuth || isPublicAuthPath) {
      return handler.next(options);
    }

    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final is401 = statusCode == 401;
    final isAuthEndpoint = err.requestOptions.path.contains(ApiEndpoints.login) ||
        err.requestOptions.path.contains(ApiEndpoints.refresh);

    if (!is401 || isAuthEndpoint) {
      return handler.next(err);
    }

    // Attempt token refresh
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _handleSessionExpired();
      return handler.reject(err);
    }

    try {
      final response = await _refreshClient.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storage.write(SecureStorage.keyAccessToken, newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await storage.write(SecureStorage.keyRefreshToken, newRefreshToken);
          }

          // Retry the paused original request
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        }
      }

      await _handleSessionExpired();
      return handler.reject(err);
    } catch (_) {
      await _handleSessionExpired();
      return handler.reject(err);
    }
  }

  Future<void> _handleSessionExpired() async {
    await storage.clearAuthData();
    onSessionExpired?.call();
  }
}
