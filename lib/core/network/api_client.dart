import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../storage/secure_storage.dart';
import 'api_error.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    EnvConfig? config,
    SecureStorage? storage,
    SessionExpiredCallback? onSessionExpired,
    Dio? dio,
  })  : config = config ?? EnvConfig.fromEnvironment(),
        storage = storage ?? FlutterSecureStorageImpl() {
    final effectiveConfig = this.config;
    this.dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: effectiveConfig.apiBaseUrl,
            connectTimeout: effectiveConfig.connectTimeout,
            receiveTimeout: effectiveConfig.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    this.dio.interceptors.add(
          AuthInterceptor(
            storage: this.storage,
            dio: this.dio,
            refreshBaseUrl: this.config.apiBaseUrl,
            onSessionExpired: onSessionExpired,
          ),
        );
  }

  final EnvConfig config;
  final SecureStorage storage;
  late final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }
}
