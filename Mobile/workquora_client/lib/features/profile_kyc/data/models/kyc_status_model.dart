class KycStatusModel {
  const KycStatusModel({
    this.status = 'pending',
    this.mobileVerified = false,
    this.panVerified = false,
    this.aadhaarVerified = false,
    this.bankVerified = false,
    this.selfieVerified = false,
  });

  final String status; // 'pending' | 'verified' | 'rejected'
  final bool mobileVerified;
  final bool panVerified;
  final bool aadhaarVerified;
  final bool bankVerified;
  final bool selfieVerified;

  bool get isFullyVerified => mobileVerified && panVerified && aadhaarVerified && bankVerified && selfieVerified;

  /// What `createJob` actually checks server-side — Aadhaar + PAN only.
  /// The other steps matter for withdrawals/full trust but not job posting.
  bool get canPostJobs => aadhaarVerified && panVerified;

  factory KycStatusModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const KycStatusModel();
    return KycStatusModel(
      status: json['status'] as String? ?? 'pending',
      mobileVerified: json['mobileVerified'] as bool? ?? false,
      panVerified: json['panVerified'] as bool? ?? false,
      aadhaarVerified: json['aadhaarVerified'] as bool? ?? false,
      bankVerified: json['bankVerified'] as bool? ?? false,
      selfieVerified: json['selfieVerified'] as bool? ?? false,
    );
  }
}
