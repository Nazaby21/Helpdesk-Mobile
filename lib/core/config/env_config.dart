import 'package:flutter/foundation.dart';

enum Environment {
  dev,
  lan;

  static Environment fromString(String value) {
    return switch (value.toLowerCase().trim()) {
      'lan' || 'device' => Environment.lan,
      _ => Environment.dev,
    };
  }
}

class EnvConfig {
  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
  });

  final Environment environment;
  final String apiBaseUrl;
  final String wsBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  bool get isDev => environment == Environment.dev;

  /// Creates environment configuration for local development.
  ///
  /// The `/api/v1` prefix is configured centrally here so all endpoint
  /// constants in `ApiEndpoints` remain relative (e.g. `/auth/login`).
  factory EnvConfig.fromEnvironment() {
    const defineBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');
    const defineWsUrl = String.fromEnvironment('WS_URL', defaultValue: '');

    if (defineBaseUrl.isNotEmpty) {
      final normalizedBase = _ensureApiV1Prefix(defineBaseUrl);
      final rawHostOrigin = defineBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
      return EnvConfig(
        environment: Environment.lan,
        apiBaseUrl: normalizedBase,
        wsBaseUrl: defineWsUrl.isNotEmpty
            ? defineWsUrl
            : '${rawHostOrigin.replaceFirst('http', 'ws')}/ws-chat',
      );
    }

    return _devConfig();
  }

  static String _ensureApiV1Prefix(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api/v1')) {
      return trimmed;
    }
    return '$trimmed/api/v1';
  }

  static EnvConfig _devConfig() {
    // Android emulator routes to host loopback via 10.0.2.2.
    // iOS simulator, desktop, and web connect directly to localhost.
    final isAndroidDevice = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final host = isAndroidDevice ? '10.0.2.2' : 'localhost';

    return EnvConfig(
      environment: Environment.dev,
      apiBaseUrl: 'http://$host:8080/api/v1',
      wsBaseUrl: 'ws://$host:8080/ws-chat',
    );
  }

  EnvConfig copyWith({
    Environment? environment,
    String? apiBaseUrl,
    String? wsBaseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    return EnvConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      wsBaseUrl: wsBaseUrl ?? this.wsBaseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    );
  }
}
