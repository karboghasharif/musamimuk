/// Response from POST `user/login`.
///
/// Backend responses seen:
/// - `{ status: true, message: "...", data: { token, user } }`
/// - legacy shapes: `{ token, user }` or `{ status, message, dbData: { token, user } }`
class LoginResponse {
  final String token;
  final String? tokenType;
  final LoginUser? user;

  LoginResponse({
    required this.token,
    this.tokenType,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final dbData = json['dbData'] as Map<String, dynamic>?;
    final token =
        (data?['token'] ?? json['token'] ?? dbData?['token']) as String? ?? '';
    final userJson = data?['user'] ?? json['user'] ?? dbData?['user'];
    final user = userJson != null
        ? LoginUser.fromJson(userJson as Map<String, dynamic>)
        : null;
    return LoginResponse(
      token: token,
      tokenType: json['token_type'] as String?,
      user: user,
    );
  }
}

class LoginUser {
  final int id;
  final String? name;
  final String? email;
  final int? roleId;
  final String? role;
  final String? roleLabel;
  final bool isGuest;
  final bool canAccessAdminPortal;
  final String? subscriptionPlan;
  final String? image;
  final String? country;

  LoginUser({
    required this.id,
    this.name,
    this.email,
    this.roleId,
    this.role,
    this.roleLabel,
    this.isGuest = false,
    this.canAccessAdminPortal = false,
    this.subscriptionPlan,
    this.image,
    this.country,
  });

  /// Serialized shape persisted to prefs; keeps role / guest flags so the app
  /// can gate account-only actions after a cold start.
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
        'image': image,
        'country': country,
      };

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    final roleId = (json['id'] is int)
        ? json['role_id'] as int?
        : int.tryParse(json['role_id']?.toString() ?? '');
    bool resolveGuest() {
      if (json['is_guest'] is bool) return json['is_guest'] as bool;
      final parsed = json['is_guest'];
      if (parsed != null) {
        final s = parsed.toString().toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      if (roleId == 4) return true;
      return json['role']?.toString().toLowerCase() == 'guest';
    }

    return LoginUser(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
      roleId: roleId,
      role: json['role'] as String?,
      roleLabel: json['role_label'] as String?,
      isGuest: resolveGuest(),
      canAccessAdminPortal:
          json['can_access_admin_portal'] == true ||
              json['can_access_admin_portal']?.toString() == 'true',
      subscriptionPlan: json['subscription_plan'] as String?,
      image: json['image'] as String?,
      country: json['country'] as String?,
    );
  }
}
