import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/feedback_entry.dart';

class FeedbackStorage {
  static const String _feedbackKey = 'submitted_feedbacks';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<List<FeedbackEntry>> getFeedbacks() async {
    final raw = await _storage.read(key: _feedbackKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => FeedbackEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addFeedback(FeedbackEntry entry) async {
    final items = await getFeedbacks();
    items.insert(0, entry);
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _storage.write(key: _feedbackKey, value: encoded);
  }
}
