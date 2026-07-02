class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final String reviewerName;
  final String? reviewerAvatar;
  final DateTime createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // `reviewer` is populated by getUserReviews() with { name, avatar }.
    final reviewer = json['reviewer'];
    final reviewerMap = reviewer is Map<String, dynamic> ? reviewer : const <String, dynamic>{};

    return ReviewModel(
      id: (json['_id'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      reviewerName: reviewerMap['name'] as String? ?? 'Anonymous',
      reviewerAvatar: reviewerMap['avatar'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
