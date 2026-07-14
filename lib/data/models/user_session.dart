import 'package:musamimuk/core/network/api_utils.dart';

/// Stored user session (from login, register, guest-login, or session refresh).
class UserSession {
  final int id;
  final String? name;
  final String? email;
  final String? image;
  final String? country;
  final String? bio;
  final int? roleId;
  final String? role;
  final String? roleLabel;
  final bool isGuest;
  final bool canAccessAdminPortal;
  final String? subscriptionPlan;

  const UserSession({
    required this.id,
    this.name,
    this.email,
    this.image,
    this.country,
    this.bio,
    this.roleId,
    this.role,
    this.roleLabel,
    this.isGuest = false,
    this.canAccessAdminPortal = false,
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
        'role': role,
        'role_label': roleLabel,
        'is_guest': isGuest,
        'can_access_admin_portal': canAccessAdminPortal,
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
      roleId: (json['role_id'] is int)
          ? json['role_id'] as int
          : int.tryParse(json['role_id']?.toString() ?? ''),
      role: json['role'] as String?,
      roleLabel: json['role_label'] as String?,
      isGuest: _resolveIsGuest(json),
      canAccessAdminPortal:
          apiParseBool(json['can_access_admin_portal']) ?? false,
      subscriptionPlan: json['subscription_plan'] as String?,
    );
  }

  /// Prefer explicit `is_guest`; fall back to guest role id (4) or `role` slug.
  static bool _resolveIsGuest(Map<String, dynamic> json) {
    final explicit = apiParseBool(json['is_guest']);
    if (explicit != null) return explicit;
    final roleId = (json['role_id'] is int)
        ? json['role_id'] as int
        : int.tryParse(json['role_id']?.toString() ?? '');
    if (roleId == 4) return true;
    return (json['role']?.toString().toLowerCase() == 'guest');
  }

  static String? _normOpt(String? u) {
    if (u == null || u.trim().isEmpty) return u;
    return normalizePublicStorageUrl(u);
  }
}
