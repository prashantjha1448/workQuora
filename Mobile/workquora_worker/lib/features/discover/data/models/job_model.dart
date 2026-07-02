/// A single gig/job as returned by GET /geo/nearby-jobs (geoController).
/// Backend sends: title, description, category, skillsRequired[], budget,
/// budgetRange, location, distance, and enriched client info.
class JobModel {
  const JobModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = '',
    this.skillsRequired = const [],
    this.budget = 0,
    this.distance = 0,
    this.clientName = '',
    this.clientAvatar,
    this.status = 'open',
    this.locationName = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> skillsRequired;
  final num budget;
  final num distance; // km
  final String clientName;
  final String? clientAvatar;
  final String status;
  final String locationName;
  final DateTime? createdAt;

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] is Map ? json['client'] as Map<String, dynamic> : null;
    return JobModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      skillsRequired:
          (json['skillsRequired'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      budget: json['budget'] as num? ?? 0,
      distance: json['distance'] as num? ?? 0,
      clientName: client?['name'] as String? ?? json['clientName'] as String? ?? 'Client',
      clientAvatar: client?['avatar'] as String? ?? client?['profilePic'] as String?,
      status: json['status'] as String? ?? 'open',
      locationName: json['locationName'] as String? ?? json['address'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  /// How many of the worker's skills match this job's required skills
  /// (case-insensitive). Used by the ranking algorithm.
  int skillOverlap(List<String> workerSkills) {
    if (skillsRequired.isEmpty || workerSkills.isEmpty) return 0;
    final ws = workerSkills.map((e) => e.toLowerCase().trim()).toSet();
    return skillsRequired.where((s) => ws.contains(s.toLowerCase().trim())).length;
  }
}
