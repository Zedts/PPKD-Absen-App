import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Wrapper around [FlutterSecureStorage] for typed access to secure session data.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── Token ──────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // ── User Session ───────────────────────────────────────────────────────

  Future<void> saveUserInfo({
    required int id,
    required String name,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.userIdKey, value: id.toString()),
      _storage.write(key: AppConstants.userNameKey, value: name),
      _storage.write(key: AppConstants.userEmailKey, value: email),
    ]);
  }

  Future<String?> getUserName() async {
    return _storage.read(key: AppConstants.userNameKey);
  }

  Future<String?> getUserEmail() async {
    return _storage.read(key: AppConstants.userEmailKey);
  }

  // ── Clear All ──────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
