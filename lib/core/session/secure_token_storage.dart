import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform-backed storage for the Musamimuk authentication token.
class SecureTokenStorage {
  SecureTokenStorage._();

  static final SecureTokenStorage instance = SecureTokenStorage._();

  static const String tokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: tokenKey);

  Future<void> writeToken(String token) {
    return _storage.write(key: tokenKey, value: token);
  }

  Future<void> deleteToken() => _storage.delete(key: tokenKey);
}
