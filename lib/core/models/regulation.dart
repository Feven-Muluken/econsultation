class Regulation {
  final String id;
  final String title;
  final String category;
  final String lawCategory;
  final String region;
  final String institution;
  final String status;
  final String? commentOpeningDate;
  final String? commentClosingDate;
  final bool commentClosed;
  final String description;
  final String documentUrl;
  final String updatedAt;
  final String summary;
  
  final List<RegulationSection> sections;

  String get agency => institution;
  bool get isOpenForComment => status.trim().toLowerCase() == 'open';

  Regulation({
    required this.id,
    required this.title,
    required this.category,
    String? lawCategory,
    required this.region,
    required this.institution,
    required this.status,
    this.commentOpeningDate,
    this.commentClosingDate,
    this.commentClosed = false,
    required this.description,
    required this.documentUrl,
    required this.updatedAt,
    required this.summary,
    this.sections = const <RegulationSection>[],
  }) : lawCategory = (lawCategory == null || lawCategory.trim().isEmpty)
            ? category
            : lawCategory;

  factory Regulation.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? const <dynamic>[];
    final institutionMap = _asMap(json['institution']);
    final lawCategoryMap = _asMap(json['law_category']);
    final draftStatusMap = _asMap(json['draft_status']);

    final id = _asString(json['id']);
    final title = _firstNonEmpty([
      _asString(json['short_title']),
      _asString(json['title']),
    ]);
    final category = _firstNonEmpty([
      _asString(lawCategoryMap?['name']),
      _asString(json['category']),
      _asString(json['lawCategory']),
    ]);
    final lawCategory = _firstNonEmpty([
      _asString(lawCategoryMap?['name']),
      _asString(json['lawCategory']),
      _asString(json['category']),
    ]);
    final institution = _firstNonEmpty([
      _asString(institutionMap?['name']),
      _asString(json['institution']),
      _asString(json['agency']),
    ]);
    final status = _firstNonEmpty([
      _asString(draftStatusMap?['name']),
      _asString(json['status']),
    ]);
    final commentOpeningDate = _firstNonEmpty([
      _asString(json['comment_opening_date']),
      _asString(json['commentOpeningDate']),
    ]);
    final commentClosingDate = _firstNonEmpty([
      _asString(json['comment_closing_date']),
      _asString(json['commentClosingDate']),
    ]);
    final commentClosed = _asBool(
      json.containsKey('comment_closed')
          ? json['comment_closed']
          : json['commentClosed'],
    );
    final summary = _firstNonEmpty([
      _asString(json['comment_summary']),
      _asString(json['summary']),
      _asString(json['comment_request_description']),
      _asString(json['description']),
    ]);
    final description = _firstNonEmpty([
      _asString(json['comment_request_description']),
      _asString(json['comment_summary']),
      _asString(json['summary']),
      _asString(json['description']),
    ]);
    final documentUrl = _firstNonEmpty([
      _asString(json['file']),
      _asString(json['documentUrl']),
    ]);
    final updatedAt = _firstNonEmpty([
      _asString(json['updated_at']),
      _asString(json['updatedAt']),
      _asString(json['created_at']),
    ]);
    final region = _firstNonEmpty([
      _asString(json['region']),
      _asString(institutionMap?['region']),
    ]);

    return Regulation(
      id: id,
      title: title,
      category: category,
      lawCategory: lawCategory,
      region: region,
      institution: institution,
      status: status,
        commentOpeningDate:
          commentOpeningDate.isEmpty ? null : commentOpeningDate,
      commentClosingDate:
          commentClosingDate.isEmpty ? null : commentClosingDate,
        commentClosed: commentClosed,
      description: description,
      documentUrl: documentUrl,
      updatedAt: updatedAt,
      summary: summary,
      sections: rawSections
          .map((item) => RegulationSection.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  static String _asString(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    return '$value';
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = _asString(value).trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'lawCategory': lawCategory,
      'region': region,
      'institution': institution,
      'agency': institution,
      'status': status,
      'commentOpeningDate': commentOpeningDate,
      'commentClosingDate': commentClosingDate,
      'commentClosed': commentClosed,
      'comment_opening_date': commentOpeningDate,
      'comment_closing_date': commentClosingDate,
      'comment_closed': commentClosed ? '1' : '0',
      'description': description,
      'documentUrl': documentUrl,
      'updatedAt': updatedAt,
      'summary': summary,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }
}

class RegulationSection {
  final String sectionTitle;
  final List<String> articles;

  const RegulationSection({
    required this.sectionTitle,
    required this.articles,
  });

  factory RegulationSection.fromJson(Map<String, dynamic> json) {
    final articleList = (json['articles'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => '$item')
        .toList(growable: false);

    return RegulationSection(
      sectionTitle: (json['sectionTitle'] ?? json['title'] ?? '') as String,
      articles: articleList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionTitle': sectionTitle,
      'articles': articles,
    };
  }
}
