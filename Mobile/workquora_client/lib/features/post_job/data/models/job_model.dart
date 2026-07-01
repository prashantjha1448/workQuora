/// Mirrors `Job.js` + the shape `createJob` accepts/returns. Kept minimal —
/// only fields the Post Job flow reads or writes.
class JobModel {
  const JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.skillsRequired = const [],
    this.minBudget,
    this.maxBudget,
    this.budget = 0,
    this.isUrgent = false,
    this.status = 'open',
    this.address,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> skillsRequired;
  final num? minBudget;
  final num? maxBudget;
  final num budget;
  final bool isUrgent;
  final String status;
  final String? address;

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final budgetRange = json['budgetRange'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    return JobModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      skillsRequired: (json['skillsRequired'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      minBudget: budgetRange?['min'] as num?,
      maxBudget: budgetRange?['max'] as num?,
      budget: json['budget'] as num? ?? 0,
      isUrgent: json['isUrgent'] as bool? ?? false,
      status: json['status'] as String? ?? 'open',
      address: location?['address'] as String?,
    );
  }
}
