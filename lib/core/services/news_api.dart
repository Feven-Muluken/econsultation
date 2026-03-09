import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/news_item.dart';
import '../models/paginated_response.dart';
import '../storage/secure_storage.dart';
import 'mock_content_api.dart';

class NewsApi {
  NewsApi._();

  static final NewsApi instance = NewsApi._();

  final Dio _dio = Dio();
  final MockContentApi _mockApi = MockContentApi.instance;

  String get _baseUrl {
    final fromEnv = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (fromEnv.isNotEmpty && fromEnv.startsWith('http')) {
      return fromEnv;
    }
    return 'https://backend.e-consultation.gov.et';
  }

  Future<PaginatedResponse<NewsItem>> fetchNewsPage({
    int page = 1,
    int pageSize = 10,
    String? query,
  }) async {
    try {
      final headers = await _headers();
      final response = await _getWithFallback(
        paths: [
          '/api/news?page=$page&per_page=$pageSize${_querySuffix(query)}',
          '/api/news?page=$page&limit=$pageSize${_querySuffix(query)}',
          '/news?page=$page&per_page=$pageSize${_querySuffix(query)}',
        ],
        headers: headers,
      );

      final payload = response.data as Map<String, dynamic>;
      final data = payload['data'];

      if (data is List<dynamic>) {
        final items = data
            .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
            .toList(growable: false);
        final total = (payload['total'] as num?)?.toInt() ?? items.length;
        return PaginatedResponse<NewsItem>(
          items: items,
          totalCount: total,
          page: page,
          pageSize: pageSize,
        );
      }

      if (data is Map<String, dynamic>) {
        final itemsRaw = (data['data'] ?? data['items'] ?? data['results']) as List<dynamic>? ?? const [];
        final items = itemsRaw
            .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
            .toList(growable: false);
        final total = ((data['total'] as num?)?.toInt()) ??
            ((data['total_count'] as num?)?.toInt()) ??
            items.length;

        return PaginatedResponse<NewsItem>(
          items: items,
          totalCount: total,
          page: page,
          pageSize: pageSize,
        );
      }

      throw Exception('Unexpected news response shape');
    } catch (_) {
      return _mockApi.fetchNewsPage(page: page, pageSize: pageSize);
    }
  }

  Future<NewsItem?> fetchNewsById(String id) async {
    try {
      final headers = await _headers();
      final response = await _getWithFallback(
        paths: [
          '/api/news/$id',
          '/news/$id',
        ],
        headers: headers,
      );

      final payload = response.data as Map<String, dynamic>;
      final data = (payload['data'] as Map<String, dynamic>? ?? payload);
      return NewsItem.fromJson(data);
    } catch (_) {
      final all = await _mockApi.fetchNews();
      for (final item in all) {
        if (item.id == id) {
          return item;
        }
      }
      return null;
    }
  }

  Future<Response<dynamic>> _getWithFallback({
    required List<String> paths,
    required Map<String, String> headers,
  }) async {
    DioException? lastError;
    for (final path in paths) {
      try {
        return await _dio.get(
          '$_baseUrl$path',
          options: Options(headers: headers),
        );
      } on DioException catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? Exception('Request failed');
  }

  Future<Map<String, String>> _headers() async {
    final token = await SecureStorage.readToken();
    if (token == null || token.trim().isEmpty) {
      return {'Accept': 'application/json'};
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _querySuffix(String? query) {
    final trimmed = query?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    return '&q=${Uri.encodeQueryComponent(trimmed)}';
  }
}
