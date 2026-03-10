import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> writeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> writeUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<String?> readUserId() async {
    return _storage.read(key: _userIdKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> clearUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
    ]);
  }
}
