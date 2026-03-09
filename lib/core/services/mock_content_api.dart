import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/news_item.dart';
import '../models/paginated_response.dart';
import '../models/regulation.dart';
import '../models/regulation_filter.dart';
import '../models/user_profile.dart';

class MockContentApi {
  MockContentApi._();

  static final MockContentApi instance = MockContentApi._();

  List<NewsItem>? _newsCache;
  List<Regulation>? _regulationCache;
  UserProfile? _userCache;

  Future<UserProfile> fetchUserProfile() async {
    if (_userCache != null) {
      return _userCache!;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    final payload = await rootBundle.loadString('assets/mock/user.json');
    final Map<String, dynamic> jsonMap = jsonDecode(payload) as Map<String, dynamic>;
    _userCache = UserProfile.fromJson(jsonMap);
    return _userCache!;
  }

  Future<List<NewsItem>> fetchNews() async {
    if (_newsCache != null) {
      return _newsCache!;
    }
    await Future.delayed(const Duration(milliseconds: 600));
    final payload = await rootBundle.loadString('assets/mock/news.json');
    final List<dynamic> jsonList = jsonDecode(payload) as List<dynamic>;
    _newsCache = jsonList
        .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return _newsCache!;
  }

  Future<PaginatedResponse<NewsItem>> fetchNewsPage({
    int page = 1,
    int pageSize = 10,
  }) async {
    final data = await fetchNews();
    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    final slice = start >= data.length
        ? <NewsItem>[]
        : data.sublist(start, end > data.length ? data.length : end);

    return PaginatedResponse<NewsItem>(
      items: slice,
      totalCount: data.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<PaginatedResponse<Regulation>> fetchRegulations({
    int page = 1,
    int pageSize = 10,
    String? query,
    RegulationFilter? filter,
    bool sortDescending = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final data = await _loadRegulations();
    final normalizedQuery = _normalize(query);

    final filtered = <Regulation>[];
    for (final regulation in data) {
      if (!_matchesQuery(regulation, normalizedQuery)) {
        continue;
      }
      if (!_matchesFilter(regulation, filter)) {
        continue;
      }
      filtered.add(regulation);
    }

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a.updatedAt) ?? DateTime(1970);
      final bDate = DateTime.tryParse(b.updatedAt) ?? DateTime(1970);
      return sortDescending ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });

    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    final slice = start >= filtered.length
        ? <Regulation>[]
        : filtered.sublist(start, end > filtered.length ? filtered.length : end);

    return PaginatedResponse<Regulation>(
      items: slice,
      totalCount: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  bool _matchesQuery(Regulation regulation, String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return _normalize(regulation.title).contains(normalizedQuery) ||
        _normalize(regulation.description).contains(normalizedQuery) ||
      _normalize(regulation.category).contains(normalizedQuery) ||
      _normalize(regulation.lawCategory).contains(normalizedQuery) ||
        _normalize(regulation.region).contains(normalizedQuery) ||
        _normalize(regulation.institution).contains(normalizedQuery) ||
      _normalize(regulation.status).contains(normalizedQuery) ||
      _normalize(regulation.commentClosingDate).contains(normalizedQuery);
  }

  bool _matchesFilter(Regulation regulation, RegulationFilter? filter) {
    if (filter == null || filter.isEmpty) {
      return true;
    }

    if (filter.status != null &&
        _normalize(regulation.status) != _normalize(filter.status)) {
      return false;
    }
    if (filter.category != null &&
        _normalize(regulation.category) != _normalize(filter.category)) {
      return false;
    }
    if (filter.region != null &&
        _normalize(regulation.region) != _normalize(filter.region)) {
      return false;
    }
    if (filter.institution != null &&
        _normalize(regulation.institution) != _normalize(filter.institution)) {
      return false;
    }

    return true;
  }

  String _normalize(String? value) => value?.trim().toLowerCase() ?? '';

  Future<Regulation?> fetchRegulationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final data = await _loadRegulations();
    try {
      return data.firstWhere((regulation) => regulation.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Regulation>> _loadRegulations() async {
    if (_regulationCache != null) {
      return _regulationCache!;
    }
    final payload = await rootBundle.loadString('assets/mock/regulations.json');
    final List<dynamic> jsonList = jsonDecode(payload) as List<dynamic>;
    _regulationCache = jsonList
        .map((item) => Regulation.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return _regulationCache!;
  }
}
