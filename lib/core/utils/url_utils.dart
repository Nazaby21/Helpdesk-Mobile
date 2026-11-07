import 'package:flutter/foundation.dart';

/// Utility to normalize image and asset URLs returned by the backend
/// so that Android emulators (10.0.2.2) and local Wi-Fi devices can load them.
class UrlUtils {
  UrlUtils._();

  /// Resolves [url] against the configured [apiBaseUrl].
  ///
  /// Replaces any `localhost` or `127.0.0.1` hostnames with the host of [apiBaseUrl].
  static String resolveImageUrl(String? url, {String? apiBaseUrl}) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }

    final trimmed = url.trim();

    // Already a remote/cloud URL that doesn't target loopback
    if (trimmed.startsWith('https://') &&
        !trimmed.contains('localhost') &&
        !trimmed.contains('127.0.0.1')) {
      return trimmed;
    }

    // Extract target host and port from apiBaseUrl if available
    String targetHost = '10.0.2.2';
    String targetPort = '8080';

    if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
      try {
        final baseUri = Uri.parse(apiBaseUrl);
        targetHost = baseUri.host.isNotEmpty ? baseUri.host : targetHost;
        if (baseUri.hasPort) {
          targetPort = baseUri.port.toString();
        }
      } catch (_) {}
    } else if (kIsWeb) {
      targetHost = 'localhost';
    }

    // Handle relative URLs like /uploads/photo.jpg
    if (trimmed.startsWith('/')) {
      return 'http://$targetHost:$targetPort$trimmed';
    }

    // Replace localhost or 127.0.0.1
    return trimmed
        .replaceFirst('://localhost:', '://$targetHost:')
        .replaceFirst('://127.0.0.1:', '://$targetHost:')
        .replaceFirst('://localhost/', '://$targetHost:$targetPort/')
        .replaceFirst('://127.0.0.1/', '://$targetHost:$targetPort/');
  }
}
