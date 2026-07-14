import 'package:musamimuk/core/network/api_utils.dart';

/// Response from POST `user/register` (multipart).
class RegisterResponse {
  final bool status;
  final String message;
  final RegisterData? data;

  RegisterResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      status: json['status'] is bool
          ? json['status'] as bool
          : (json['status']?.toString().toLowerCase() == 'true'),
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? RegisterData.fromJson(json['data'] as Map<String, dynamic>)
          : (json['dbData'] != null
              ? RegisterData.fromJson(json['dbData'] as Map<String, dynamic>)
              : null),
    );
  }
}

class RegisterData {
  final String token;
  final RegisterUser? user;

  RegisterData({required this.token, this.user});

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    return RegisterData(
      token: json['token'] as String? ?? '',
      user: json['user'] != null
          ? RegisterUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RegisterUser {
  final int id;
  final String? name;
  final String? email;
  final int? roleId;
  final String? role;
  final String? roleLabel;
  final bool isGuest;
  final bool canAccessAdminPortal;
  final String? subscriptionPlan;
  final String? country;
  final String? image;
  final String? updatedAt;
  final String? createdAt;

  RegisterUser({
    required this.id,
    this.name,
    this.email,
    this.roleId,
    this.role,
    this.roleLabel,
    this.isGuest = false,
    this.canAccessAdminPortal = false,
    this.subscriptionPlan,
    this.country,
    this.image,
    this.updatedAt,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role_id': roleId,
        'role': role,
        'role_label': roleLabel,
        'is_guest': isGuest,
        'can_access_admin_portal': canAccessAdminPortal,
        'subscription_plan': subscriptionPlan,
        'country': country,
        'image': image,
      };

  factory RegisterUser.fromJson(Map<String, dynamic> json) {
    return RegisterUser(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
      roleId: (json['role_id'] is int)
          ? json['role_id'] as int
          : int.tryParse(json['role_id']?.toString() ?? ''),
      role: json['role'] as String?,
      roleLabel: json['role_label'] as String?,
      isGuest: json['is_guest'] == true ||
          json['is_guest']?.toString().toLowerCase() == 'true',
      canAccessAdminPortal: json['can_access_admin_portal'] == true ||
          json['can_access_admin_portal']?.toString() == 'true',
      subscriptionPlan: json['subscription_plan'] as String?,
      country: json['country'] as String?,
      image: _normUserImage(json['image'] as String?),
      updatedAt: json['updated_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  static String? _normUserImage(String? u) {
    if (u == null || u.trim().isEmpty) return u;
    return normalizePublicStorageUrl(u);
  }
}
