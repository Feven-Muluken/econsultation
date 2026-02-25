import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const String _tokenKey = 'auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> writeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
