/// Maps the `data` object from `GET /profile/user/:userId`
/// (profileController.getPublicProfile). Field names mirror the backend
/// exactly — see DESIGN.md memory note: field-name mismatches between
/// frontend/backend were a recurring bug source in this codebase, so this
/// model is intentionally defensive about null/missing keys.
class TalentProfileModel {
  const TalentProfileModel({
    required this.id,
    required this.name,
    this.title = '',
    this.bio = '',
    this.profilePic,
    this.skills = const [],
    this.hourlyRate = 0,
    this.averageRating = 0,
    this.totalJobsCompleted = 0,
    this.experienceYears = 0,
    this.jobSuccessRate = 95,
    this.responseTimeMinutes = 30,
    this.isVerified = false,
    this.kycVerified = false,
    this.isActive = false,
    this.availabilityStatus = 'AVAILABLE',
    this.city,
    this.activeProjects = 0,
    this.completedProjects = 0,
    this.totalProposals = 0,
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  final String id;
  final String name;
  final String title;
  final String bio;
  final String? profilePic;
  final List<String> skills;
  final num hourlyRate;
  final num averageRating;
  final int totalJobsCompleted;
  final int experienceYears;
  final num jobSuccessRate;
  final int responseTimeMinutes;
  final bool isVerified;
  final bool kycVerified;
  final bool isActive;
  final String availabilityStatus;
  final String? city;
  final int activeProjects;
  final int completedProjects;
  final int totalProposals;
  final bool emailVerified;
  final bool phoneVerified;

  factory TalentProfileModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final verifications = json['verifications'] as Map<String, dynamic>? ?? const {};
    final location = json['location'] as Map<String, dynamic>?;

    return TalentProfileModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profilePic: json['profilePic'] as String? ?? json['avatar'] as String?,
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      hourlyRate: json['hourlyRate'] as num? ?? 0,
      averageRating: json['averageRating'] as num? ?? 0,
      totalJobsCompleted: json['totalJobsCompleted'] as int? ?? 0,
      experienceYears: json['experienceYears'] as int? ?? 0,
      jobSuccessRate: json['jobSuccessRate'] as num? ?? 95,
      responseTimeMinutes: json['responseTimeMinutes'] as int? ?? 30,
      isVerified: json['isVerified'] as bool? ?? false,
      kycVerified: json['kycVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'AVAILABLE',
      city: location?['city'] as String?,
      activeProjects: (stats['activeProjects'] as num?)?.toInt() ?? 0,
      completedProjects: (stats['completedProjects'] as num?)?.toInt() ?? 0,
      totalProposals: (stats['totalProposals'] as num?)?.toInt() ?? 0,
      emailVerified: verifications['email'] as bool? ?? false,
      phoneVerified: verifications['phone'] as bool? ?? false,
    );
  }
}
