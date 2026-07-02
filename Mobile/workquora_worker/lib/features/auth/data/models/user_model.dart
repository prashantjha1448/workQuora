/// Mirrors backend `User.js`. Only fields the client app needs — keep this
/// lean; bloated models cost memory across every cached list of users.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.mobileNumber,
    this.role = 'CLIENT',
    this.avatar,
    this.isVerified = false,
    this.isMobileVerified = false,
    this.kycVerified = false,
  });

  final String id;
  final String name;
  final String email;
  final String? username;
  final String? mobileNumber;
  final String role;
  final String? avatar;
  final bool isVerified;
  final bool isMobileVerified;
  final bool kycVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      role: json['role'] as String? ?? 'CLIENT',
      avatar: json['avatar'] as String? ?? json['profilePic'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isMobileVerified: json['isMobileVerified'] as bool? ?? false,
      kycVerified: json['kycVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'username': username,
        'mobileNumber': mobileNumber,
        'role': role,
        'avatar': avatar,
        'isVerified': isVerified,
        'isMobileVerified': isMobileVerified,
        'kycVerified': kycVerified,
      };

  bool get isClient => role == 'CLIENT';
}
