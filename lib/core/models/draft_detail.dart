class DraftDetail {
  final int id;
  final String shortTitle;
  final String category;
  final String status;
  final String institutionName;
  final String fileUrl;
  final String? commentOpeningDate;
  final String? commentClosingDate;
  final String? commentRequestDescription;
  final String? summary;
  final String? updatedAt;
  final bool commentClosed;

  DraftDetail({
    required this.id,
    required this.shortTitle,
    required this.category,
    required this.status,
    required this.institutionName,
    required this.fileUrl,
    required this.commentOpeningDate,
    required this.commentClosingDate,
    required this.commentRequestDescription,
    required this.summary,
    required this.updatedAt,
    required this.commentClosed,
  });

  factory DraftDetail.fromJson(Map<String, dynamic> json) {
    return DraftDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shortTitle: (json['short_title'] ?? '') as String,
      category: ((json['law_category'] as Map<String, dynamic>?)?['name'] ?? '')
          as String,
      status:
          ((json['draft_status'] as Map<String, dynamic>?)?['name'] ?? '') as String,
      institutionName:
          ((json['institution'] as Map<String, dynamic>?)?['name'] ?? '') as String,
      fileUrl: (json['file'] ?? '') as String,
      commentOpeningDate: json['comment_opening_date'] as String?,
      commentClosingDate: json['comment_closing_date'] as String?,
      commentRequestDescription: json['comment_request_description'] as String?,
      summary: json['summary'] as String?,
      updatedAt: json['updated_at'] as String?,
      commentClosed: '${json['comment_closed'] ?? ''}' == '1',
    );
  }
}
