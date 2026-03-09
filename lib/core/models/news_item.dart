class NewsItem {
  final String id;
  final String title;
  final String imageUrl;
  final String publishedAt;
  final String summary;
  final String content;
  final String category;

  NewsItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.publishedAt,
    required this.summary,
    required this.content,
    required this.category,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['news_id'] ?? '').toString();
    final title =
        (json['title'] ?? json['headline'] ?? json['short_title'] ?? '').toString();
    final imageUrl = (json['imageUrl'] ??
            json['image_url'] ??
            json['thumbnail'] ??
            json['image'] ??
            '')
        .toString();
    final publishedAt =
        (json['publishedAt'] ?? json['published_at'] ?? json['created_at'] ?? '')
            .toString();
    final summary =
        (json['summary'] ?? json['description'] ?? json['excerpt'] ?? '').toString();
    final content =
        (json['content'] ?? json['body'] ?? json['full_text'] ?? summary).toString();
    final category =
        (json['category'] ?? json['news_category'] ?? json['type'] ?? 'General')
            .toString();

    return NewsItem(
      id: id,
      title: title,
      imageUrl: imageUrl,
      publishedAt: publishedAt,
      summary: summary,
      content: content,
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt,
      'summary': summary,
      'content': content,
      'category': category,
    };
  }
}
