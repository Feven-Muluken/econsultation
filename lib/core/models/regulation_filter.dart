class RegulationFilter {
  final String? status;
  final String? category;
  final String? region;
  final String? institution;

  const RegulationFilter({
    this.status,
    this.category,
    this.region,
    this.institution,
  });

  RegulationFilter copyWith({
    String? status,
    String? category,
    String? region,
    String? institution,
  }) {
    return RegulationFilter(
      status: status ?? this.status,
      category: category ?? this.category,
      region: region ?? this.region,
      institution: institution ?? this.institution,
    );
  }

  bool get isEmpty =>
      status == null &&
      category == null &&
      region == null &&
      institution == null;

  Map<String, String?> toJson() {
    return {
      'status': status,
      'category': category,
      'region': region,
      'institution': institution,
    };
  }
}
