import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/draft_detail.dart';
import '../models/draft_section.dart';
import '../models/paginated_response.dart';
import '../models/regulation.dart';
import '../models/regulation_filter.dart';
import '../storage/secure_storage.dart';

class DraftApi {
  DraftApi._();

  static final DraftApi instance = DraftApi._();

  final Dio _dio = Dio();

  String get _baseUrl {
    final fromEnv = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (fromEnv.isNotEmpty &&
        fromEnv.startsWith('http') &&
        !fromEnv.contains('/var/www/')) {
      return fromEnv;
    }
    return 'https://backend.e-consultation.gov.et';
  }

  Future<DraftDetail> fetchDraftDetail(int draftId) async {
    final response = await _getWithFallback(
      paths: [
        '/api/v1/drafts/$draftId',
      ],
    );

    final payload = response.data as Map<String, dynamic>;
    final data = (payload['data'] as Map<String, dynamic>? ?? payload);
    print('Fetched draft detail: $data');
    return DraftDetail.fromJson(data);
  }

  Future<List<DraftSection>> fetchDraftSections(int draftId) async {
    final response = await _getWithFallback(
      paths: [
        '/api/v1/draft/$draftId/draft-sections',
        '/api/v1/drafts/$draftId',
      ],
      
    );

    final root = response.data;
    final payload = root is Map<String, dynamic>
        ? root
        : <String, dynamic>{'data': root};

    final sectionItems = _extractSections(payload);
    return sectionItems
        .whereType<Map<String, dynamic>>()
        .map(DraftSection.fromJson)
        .toList(growable: false);
  }

  Future<PaginatedResponse<Regulation>> fetchDraftRegulations({
    int page = 1,
    int pageSize = 10,
    String? query,
    RegulationFilter? filter,
    bool sortDescending = true,
  }) async {
    // final querySuffix = _querySuffix(query);
    final response = await _getWithFallback(
      paths: [
        '/api/v1/drafts',
      ],
    );

    final root = response.data;
    final payload = root is Map<String, dynamic>
        ? root
        : <String, dynamic>{'data': root};

    final listData = _extractList(payload);
    final mapped = listData
        .whereType<Map<String, dynamic>>()
        .map(_mapDraftItemToRegulation)
        .toList(growable: false);

    final filtered = mapped.where((regulation) {
      if (!_matchesQuery(regulation, query)) {
        return false;
      }
      if (!_matchesFilter(regulation, filter)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a.updatedAt) ?? DateTime(1970);
      final bDate = DateTime.tryParse(b.updatedAt) ?? DateTime(1970);
      return sortDescending ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });

    final totalCount = _extractTotalCount(payload, filtered.length);
    return PaginatedResponse<Regulation>(
      items: filtered,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> postSectionComment({
    required int sectionId,
    required String comment,
  }) async {
    final headers = await _headers();
    final url = '$_baseUrl/api/draft-sections/$sectionId/comments';

    await _dio.post(
      url,
      data: {
        'comment': comment,
        'section_id': sectionId,
      },
      options: Options(headers: headers),
    );
  }

  Future<Response<dynamic>> _getWithFallback({
    required List<String> paths,
  }) async {
    final headers = await _headers();
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
      return {
        'Accept': 'application/json',
      };
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  List<dynamic> _extractList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['items'] ?? data['results'];
      if (nested is List<dynamic>) {
        return nested;
      }
    }
    final items = payload['items'] ?? payload['results'];
    if (items is List<dynamic>) {
      return items;
    }
    return const <dynamic>[];
  }

  List<dynamic> _extractSections(Map<String, dynamic> payload) {
    final directData = payload['data'];
    if (directData is List<dynamic>) {
      return directData;
    }

    if (directData is Map<String, dynamic>) {
      final directSections =
          directData['sections'] ?? directData['draft_sections'] ?? directData['data'];
      if (directSections is List<dynamic>) {
        return directSections;
      }
    }

    final directSections = payload['sections'] ?? payload['draft_sections'];
    if (directSections is List<dynamic>) {
      return directSections;
    }

    return const <dynamic>[];
  }

  int _extractTotalCount(Map<String, dynamic> payload, int fallback) {
    int? readNum(dynamic value) => (value is num) ? value.toInt() : null;

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nested =
          readNum(data['total']) ?? readNum(data['total_count']) ?? readNum(data['count']);
      if (nested != null) {
        return nested;
      }
    }

    final direct =
        readNum(payload['total']) ?? readNum(payload['total_count']) ?? readNum(payload['count']);
    return direct ?? fallback;
  }

  Regulation _mapDraftItemToRegulation(Map<String, dynamic> item) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final value = item[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    String readNestedName(String key) {
      final nested = item[key];
      if (nested is Map<String, dynamic>) {
        final value = nested['name'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    final id = item['id'];
    final idString = id == null ? '' : id.toString();
    final category = readNestedName('law_category').isNotEmpty
        ? readNestedName('law_category')
        : readString(['category']);
    final status = readNestedName('draft_status').isNotEmpty
        ? readNestedName('draft_status')
        : readString(['status']);
    final institution = readNestedName('institution');
    final title = readString(['short_title', 'title', 'name']);
    final summary = readString([
      'summary',
      'comment_request_description',
      'description',
    ]);
    final updatedAtRaw = readString(['updated_at', 'updatedAt']);
    final updatedAt =
        updatedAtRaw.length >= 10 ? updatedAtRaw.substring(0, 10) : updatedAtRaw;
    final commentClosingDate = readString(['comment_closing_date', 'commentClosingDate']);
    final commentOpeningDate = readString(['comment_opening_date', 'commentOpeningDate']);
    final commentClosedRaw = item['comment_closed'] ?? item['commentClosed'];
    final commentClosed = '$commentClosedRaw'.trim() == '1' ||
      '$commentClosedRaw'.trim().toLowerCase() == 'true';
    final documentUrl = readString(['file', 'document_url', 'documentUrl', 'url']);

    return Regulation(
      id: idString,
      title: title,
      category: category,
      region: readNestedName('region'),
      institution: institution,
      status: status,
        commentOpeningDate:
          commentOpeningDate.isEmpty ? null : commentOpeningDate,
      commentClosingDate:
          commentClosingDate.isEmpty ? null : commentClosingDate,
        commentClosed: commentClosed,
      description: summary,
      documentUrl: documentUrl,
      updatedAt: updatedAt,
      summary: summary,
    );
  }

  bool _matchesQuery(Regulation regulation, String? query) {
    final normalized = (query ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return regulation.title.toLowerCase().contains(normalized) ||
        regulation.description.toLowerCase().contains(normalized) ||
        regulation.category.toLowerCase().contains(normalized) ||
        regulation.lawCategory.toLowerCase().contains(normalized) ||
        regulation.region.toLowerCase().contains(normalized) ||
        regulation.institution.toLowerCase().contains(normalized) ||
        regulation.status.toLowerCase().contains(normalized) ||
        (regulation.commentClosingDate ?? '').toLowerCase().contains(normalized);
  }
  bool _matchesFilter(Regulation regulation, RegulationFilter? filter) {
    if (filter == null || filter.isEmpty) {
      return true;
    }

    String normalize(String? value) => value?.trim().toLowerCase() ?? '';

    if (filter.status != null &&
        filter.status!.trim().isNotEmpty &&
        normalize(regulation.status) != normalize(filter.status)) {
      return false;
    }
    if (filter.category != null &&
        normalize(regulation.category) != normalize(filter.category)) {
      return false;
    }
    if (filter.region != null &&
        normalize(regulation.region) != normalize(filter.region)) {
      return false;
    }
    if (filter.institution != null &&
        normalize(regulation.institution) != normalize(filter.institution)) {
      return false;
    }

    return true;
  }
}
