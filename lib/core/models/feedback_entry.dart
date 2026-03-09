class FeedbackEntry {
  final String id;
  final String regulationId;
  final String regulationTitle;
  final String message;
  final String createdAt;

  FeedbackEntry({
    required this.id,
    required this.regulationId,
    required this.regulationTitle,
    required this.message,
    required this.createdAt,
  });

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: json['id'] as String,
      regulationId: json['regulationId'] as String,
      regulationTitle: json['regulationTitle'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regulationId': regulationId,
      'regulationTitle': regulationTitle,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
