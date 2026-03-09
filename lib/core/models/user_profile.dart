class UserProfile {
  final String id;
  final String fullName;
  final String preferredLanguage;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.preferredLanguage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'preferredLanguage': preferredLanguage,
    };
  }
}
