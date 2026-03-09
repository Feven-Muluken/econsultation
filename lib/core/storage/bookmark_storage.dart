import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BookmarkStorage {
  static const String _bookmarkKey = 'bookmarked_regulations';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Set<String>> getBookmarks() async {
    final raw = await _storage.read(key: _bookmarkKey);
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }
    return raw.split(',').where((id) => id.isNotEmpty).toSet();
  }

  static Future<bool> isBookmarked(String id) async {
    final bookmarks = await getBookmarks();
    return bookmarks.contains(id);
  }

  static Future<void> toggleBookmark(String id) async {
    final bookmarks = await getBookmarks();
    if (bookmarks.contains(id)) {
      bookmarks.remove(id);
    } else {
      bookmarks.add(id);
    }
    await _storage.write(key: _bookmarkKey, value: bookmarks.join(','));
  }
}
