import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountProfileStorage {
  static const String _accountProfileKey = 'account_profile_data';
  static const String _registeredProfilesKey = 'registered_user_profiles';
  static const String _activeUserKey = 'active_user_identifier';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>?> getProfile() async {
    final raw = await _storage.read(key: _accountProfileKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  }

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: _accountProfileKey, value: jsonEncode(profile));
  }

  static Future<void> saveRegisteredProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return;
    }

    final profiles = await _readRegisteredProfiles();
    profiles[normalizedEmail] = {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': normalizedEmail,
      'role': 'Commenter',
    };

    await _storage.write(
      key: _registeredProfilesKey,
      value: jsonEncode(profiles),
    );
  }

  static Future<void> setActiveUserIdentifier(String identifier) async {
    await _storage.write(
      key: _activeUserKey,
      value: identifier.trim().toLowerCase(),
    );
  }

  static Future<String?> getActiveUserIdentifier() async {
    return _storage.read(key: _activeUserKey);
  }

  static Future<Map<String, dynamic>?> getRegisteredProfileForActiveUser() async {
    final active = await getActiveUserIdentifier();
    if (active == null || active.trim().isEmpty) {
      return null;
    }

    final profiles = await _readRegisteredProfiles();
    final profile = profiles[active.trim().toLowerCase()];
    if (profile is Map<String, dynamic>) {
      return profile;
    }
    return null;
  }

  static Future<Map<String, dynamic>> _readRegisteredProfiles() async {
    final raw = await _storage.read(key: _registeredProfilesKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }
    return decoded;
  }
}