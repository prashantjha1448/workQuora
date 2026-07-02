/// Maps a single object from `getNearbyFreelancers` (geoController.js).
/// Deliberately lean — this object gets cached/duplicated across the
/// Discover list, so every extra field has a real memory cost at scale.
class TalentModel {
  const TalentModel({
    required this.id,
    required this.name,
    this.title = '',
    this.avatar,
    this.skills = const [],
    this.hourlyRate = 0,
    this.averageRating = 0,
    this.totalJobsCompleted = 0,
    this.distance = 0,
    this.isVerified = false,
    this.isAvailable = true,
    this.availabilityStatus = 'AVAILABLE',
  });

  final String id;
  final String name;
  final String title;
  final String? avatar;
  final List<String> skills;
  final num hourlyRate;
  final num averageRating;
  final int totalJobsCompleted;
  final num distance;
  final bool isVerified;
  final bool isAvailable;
  final String availabilityStatus;

  factory TalentModel.fromJson(Map<String, dynamic> json) {
    return TalentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      avatar: json['avatar'] as String? ?? json['profilePic'] as String?,
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      hourlyRate: json['hourlyRate'] as num? ?? 0,
      averageRating: json['averageRating'] as num? ?? 0,
      totalJobsCompleted: json['totalJobsCompleted'] as int? ?? 0,
      distance: json['distance'] as num? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'AVAILABLE',
    );
  }
}
