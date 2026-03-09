import 'section_comment.dart';

class DraftSection {
  final int id;
  final String title;
  final String body;
  final int draftId;
  final int? parentId;
  final List<SectionComment> comments;
  final List<DraftSection> children;

  DraftSection({
    required this.id,
    required this.title,
    required this.body,
    required this.draftId,
    required this.parentId,
    required this.comments,
    required this.children,
  });

  factory DraftSection.fromJson(Map<String, dynamic> json) {
    final commentsRaw = (json['comments'] as List<dynamic>? ?? const []);
    final childrenRaw = (json['children'] as List<dynamic>? ?? const []);

    return DraftSection(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['section_title'] ?? '') as String,
      body: (json['section_body'] ?? '') as String,
      draftId: (json['draft_id'] as num?)?.toInt() ?? 0,
      parentId: (json['parent_id'] as num?)?.toInt(),
      comments: commentsRaw
          .map((item) => SectionComment.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      children: childrenRaw
          .map((item) => DraftSection.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
