import 'package:dio/dio.dart';

enum ApiErrorKind {
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  server,
  network,
  timeout,
  cancelled,
  unknown,
}

/// Unified error model representing backend errors and network failures.
class ApiError implements Exception {
  const ApiError({
    required this.message,
    required this.kind,
    this.statusCode,
    this.validationErrors = const {},
    this.timestamp,
    this.rawResponse,
  });

  final String message;
  final ApiErrorKind kind;
  final int? statusCode;
  final Map<String, String> validationErrors;
  final String? timestamp;
  final dynamic rawResponse;

  bool get isValidation => kind == ApiErrorKind.validation || validationErrors.isNotEmpty;
  bool get isUnauthorized => kind == ApiErrorKind.unauthorized || statusCode == 401;
  bool get isForbidden => kind == ApiErrorKind.forbidden || statusCode == 403;
  bool get isNotFound => kind == ApiErrorKind.notFound || statusCode == 404;
  bool get isConflict => kind == ApiErrorKind.conflict || statusCode == 409;
  bool get isServer => kind == ApiErrorKind.server || (statusCode != null && statusCode! >= 500);
  bool get isNetwork => kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  /// Parses error responses from Spring Boot or Dio exceptions.
  ///
  /// Supports:
  /// - Format 1 (`ErrorResponse`): `{"status": 404, "message": "...", "timestamp": "..."}`
  /// - Format 2 (Validation Error Map): `{"status": 400, "message": "Validation failed", "errors": {"field": "..."}}`
  /// - Format 3 (Ad-hoc Map): `{"error": "File is missing"}`
  /// - Generic fallback strings & Dio network exceptions
  factory ApiError.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiError(
          message: 'Connection timed out. Please check your internet connection.',
          kind: ApiErrorKind.timeout,
          statusCode: dioException.response?.statusCode,
          rawResponse: dioException.response?.data,
        );

      case DioExceptionType.connectionError:
        return ApiError(
          message: 'Unable to connect to the server. Please verify the backend is running.',
          kind: ApiErrorKind.network,
          statusCode: dioException.response?.statusCode,
          rawResponse: dioException.response?.data,
        );

      case DioExceptionType.cancel:
        return const ApiError(
          message: 'Request was cancelled.',
          kind: ApiErrorKind.cancelled,
        );

      case DioExceptionType.badResponse:
        final response = dioException.response;
        return ApiError.fromResponseData(
          statusCode: response?.statusCode,
          data: response?.data,
        );

      case DioExceptionType.badCertificate:
        return ApiError(
          message: 'Security certificate error.',
          kind: ApiErrorKind.network,
          statusCode: dioException.response?.statusCode,
          rawResponse: dioException.response?.data,
        );

      case DioExceptionType.unknown:
        return ApiError(
          message: dioException.message ?? 'An unexpected network error occurred.',
          kind: ApiErrorKind.unknown,
          statusCode: dioException.response?.statusCode,
          rawResponse: dioException.response?.data,
        );
    }
  }

  /// Parses a backend response body and status code.
  factory ApiError.fromResponseData({
    int? statusCode,
    dynamic data,
  }) {
    String message = 'An unexpected error occurred.';
    String? timestamp;
    final Map<String, String> validationErrors = {};

    if (data is Map<String, dynamic>) {
      // Format 2: Validation errors map
      if (data['errors'] is Map) {
        final errorsMap = data['errors'] as Map;
        errorsMap.forEach((key, value) {
          validationErrors[key.toString()] = value.toString();
        });
      }

      // Format 1: Standard ErrorResponse { "status": 400, "message": "..." }
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        message = data['message'] as String;
      }
      // Format 3: ImageController error { "error": "..." }
      else if (data['error'] is String && (data['error'] as String).isNotEmpty) {
        message = data['error'] as String;
      }

      if (data['timestamp'] is String) {
        timestamp = data['timestamp'] as String;
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    final kind = _resolveKind(statusCode, validationErrors);

    return ApiError(
      message: message,
      kind: kind,
      statusCode: statusCode,
      validationErrors: validationErrors,
      timestamp: timestamp,
      rawResponse: data,
    );
  }

  static ApiErrorKind _resolveKind(int? statusCode, Map<String, String> errors) {
    if (errors.isNotEmpty || statusCode == 400) {
      return ApiErrorKind.validation;
    }
    if (statusCode == null) {
      return ApiErrorKind.unknown;
    }
    return switch (statusCode) {
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      409 => ApiErrorKind.conflict,
      >= 500 && < 600 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };
  }

  @override
  String toString() {
    if (validationErrors.isNotEmpty) {
      final errorDetails = validationErrors.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return '$message ($errorDetails)';
    }
    return message;
  }
}
