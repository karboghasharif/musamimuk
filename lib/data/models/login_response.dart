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

  LoginUser({required this.id, this.name, this.email});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}
