import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for secure key-value storage.
abstract class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();

  // Storage key constants
  static const String keyAccessToken = 'auth_access_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyUserRole = 'auth_user_role';
  static const String keyUserId = 'auth_user_id';
  static const String keyUserEmail = 'auth_user_email';

  // Convenience methods
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await write(keyAccessToken, accessToken);
    await write(keyRefreshToken, refreshToken);
  }

  Future<String?> getAccessToken() => read(keyAccessToken);
  Future<String?> getRefreshToken() => read(keyRefreshToken);

  Future<void> saveUserRole(String role) => write(keyUserRole, role);
  Future<String?> getUserRole() => read(keyUserRole);

  Future<void> saveUserId(int id) => write(keyUserId, id.toString());
  Future<int?> getUserId() async {
    final value = await read(keyUserId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> saveUserEmail(String email) => write(keyUserEmail, email);
  Future<String?> getUserEmail() => read(keyUserEmail);

  Future<void> clearAuthData() async {
    await delete(keyAccessToken);
    await delete(keyRefreshToken);
    await delete(keyUserRole);
    await delete(keyUserId);
    await delete(keyUserEmail);
  }
}

/// Production implementation backed by FlutterSecureStorage
/// (Android hardware-backed KeyStore cipher and iOS Keychain).
class FlutterSecureStorageImpl extends SecureStorage {
  FlutterSecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions.defaultOptions,
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
