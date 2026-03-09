class SectionComment {
  final int id;
  final String body;
  final String? author;
  final String? createdAt;

  SectionComment({
    required this.id,
    required this.body,
    this.author,
    this.createdAt,
  });

  factory SectionComment.fromJson(Map<String, dynamic> json) {
    final body = (json['comment'] ??
        json['section_comment'] ??
            json['body'] ??
            json['message'] ??
            json['content'] ??
            '')
        .toString();

    final commenter = json['commenter'];
    String? commenterName;
    if (commenter is Map<String, dynamic>) {
      final firstName = commenter['first_name']?.toString().trim() ?? '';
      final middleName = commenter['middle_name']?.toString().trim() ?? '';
      final lastName = commenter['last_name']?.toString().trim() ?? '';
      final fullName = [firstName, middleName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
      commenterName = fullName.isEmpty
        ? commenter['email']?.toString()
        : fullName;
    }

    final author = (json['user_name'] ??
            json['author_name'] ??
            json['author'] ??
        json['created_by'] ??
        commenterName)
        ?.toString();

    return SectionComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      body: body,
      author: author,
      createdAt: json['created_at']?.toString(),
    );
  }
}
