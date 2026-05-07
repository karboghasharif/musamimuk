import 'package:musamimuk/core/network/api_utils.dart';

/// Stored user session (from login or register).
class UserSession {
  final int id;
  final String? name;
  final String? email;
  final String? image;
  final String? country;
  final String? bio;
  final int? roleId;
  final String? subscriptionPlan;

  const UserSession({
    required this.id,
    this.name,
    this.email,
    this.image,
    this.country,
    this.bio,
    this.roleId,
    this.subscriptionPlan,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'image': image,
        'country': country,
        'bio': bio,
        'role_id': roleId,
        'subscription_plan': subscriptionPlan,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
      image: _normOpt(json['image'] as String?),
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      roleId: json['role_id'] as int?,
      subscriptionPlan: json['subscription_plan'] as String?,
    );
  }

  static String? _normOpt(String? u) {
    if (u == null || u.trim().isEmpty) return u;
    return normalizePublicStorageUrl(u);
  }
}
