import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_error_mapper.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/session/session_manager.dart';
import 'package:musamimuk/data/models/login_request.dart';
import 'package:musamimuk/data/models/login_response.dart';
import 'package:musamimuk/data/models/register_response.dart';
import 'package:musamimuk/data/models/user_session.dart';

/// Result of login: success with [LoginResponse] or error message.
sealed class LoginResult {}

class LoginSuccess extends LoginResult {
  final LoginResponse data;
  LoginSuccess(this.data);
}

class LoginFailure extends LoginResult {
  final String message;
  LoginFailure(this.message);
}

/// Result of register: success with [RegisterResponse] or error message.
sealed class RegisterResult {}

class RegisterSuccess extends RegisterResult {
  final RegisterResponse data;
  RegisterSuccess(this.data);
}

class RegisterFailure extends RegisterResult {
  final String message;
  RegisterFailure(this.message);
}

/// Result of a password-reset request.
sealed class ForgotPasswordResult {}

class ForgotPasswordSuccess extends ForgotPasswordResult {
  final String message;
  ForgotPasswordSuccess(this.message);
}

class ForgotPasswordFailure extends ForgotPasswordResult {
  final String message;
  ForgotPasswordFailure(this.message);
}

sealed class ProfileResult {}

class ProfileSuccess extends ProfileResult {
  final UserSession user;
  final String? message;
  ProfileSuccess({required this.user, this.message});
}

class ProfileFailure extends ProfileResult {
  final String message;
  ProfileFailure(this.message);
}

sealed class ChangePasswordResult {}

class ChangePasswordSuccess extends ChangePasswordResult {
  final String? message;
  ChangePasswordSuccess({this.message});
}

class ChangePasswordFailure extends ChangePasswordResult {
  final String message;
  ChangePasswordFailure(this.message);
}

/// Handles auth API calls (login, register, etc.).
class AuthRepository {
  AuthRepository() : _api = ApiClient();

  final ApiClient _api;

  /// POST user/login with JSON body { email, password }.
  Future<LoginResult> login(LoginRequest request) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'user/login',
        data: request.toJson(),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final parsed = LoginResponse.fromJson(data);
        if (parsed.token.trim().isNotEmpty) return LoginSuccess(parsed);
        return LoginFailure(apiExtractMessage(data) ?? 'Login failed');
      }
      return LoginFailure(apiExtractMessage(data) ?? 'Login failed');
    } on DioException catch (e) {
      return LoginFailure(apiMessageFromDioException(e));
    } catch (e) {
      return LoginFailure('Something went wrong. Please try again.');
    }
  }

  /// POST `user/google-login` with Google ID token and/or access token.
  /// Returns the same token/user shape as [login].
  Future<LoginResult> googleLogin({
    String? idToken,
    String? accessToken,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (idToken != null && idToken.trim().isNotEmpty)
          'id_token': idToken.trim(),
        if (accessToken != null && accessToken.trim().isNotEmpty)
          'access_token': accessToken.trim(),
      };
      final response = await _api.dio.post<Map<String, dynamic>>(
        'user/google-login',
        data: payload,
        options: Options(
          extra: const {ApiErrorMapper.skipSessionHandlingKey: true},
        ),
      );
      final data = response.data;
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && data != null) {
        final parsed = LoginResponse.fromJson(data);
        if (parsed.token.trim().isNotEmpty) return LoginSuccess(parsed);
        return LoginFailure(apiExtractMessage(data) ?? 'Google sign-in failed');
      }
      return LoginFailure(apiExtractMessage(data) ?? 'Google sign-in failed');
    } on DioException catch (e) {
      return LoginFailure(apiMessageFromDioException(e));
    } catch (_) {
      return LoginFailure('Something went wrong. Please try again.');
    }
  }

  /// POST `user/guest-login` with `{ device_id }` — starts or resumes the
  /// per-device guest session. Returns the same token/user shape as [login];
  /// the resulting `user.is_guest` is `true`.
  Future<LoginResult> guestLogin(String deviceId) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'user/guest-login',
        data: {'device_id': deviceId},
        options: Options(
          // A guest session start must never trigger session-expiry handling.
          extra: const {ApiErrorMapper.skipSessionHandlingKey: true},
        ),
      );
      final data = response.data;
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && data != null) {
        final parsed = LoginResponse.fromJson(data);
        if (parsed.token.trim().isNotEmpty) return LoginSuccess(parsed);
        return LoginFailure(
          apiExtractMessage(data) ?? 'Could not start guest session',
        );
      }
      return LoginFailure(
        apiExtractMessage(data) ?? 'Could not start guest session',
      );
    } on DioException catch (e) {
      return LoginFailure(apiMessageFromDioException(e));
    } catch (_) {
      return LoginFailure('Something went wrong. Please try again.');
    }
  }

  /// POST `user/upgrade` (multipart) with the **guest** bearer token — converts
  /// the guest into a full registered account. Returns a fresh token; the old
  /// guest token is revoked server-side.
  Future<RegisterResult> upgradeGuest({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String country = '',
    String? imagePath,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('name', name),
        MapEntry('email', email),
        MapEntry('password', password),
        MapEntry('password_confirmation', passwordConfirmation),
        if (country.isNotEmpty) MapEntry('country', country),
      ]);
      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath),
        ));
      }
      final response = await _api.dio.post<Map<String, dynamic>>(
        'user/upgrade',
        data: formData,
        options: Options(
          // 403 here means "not a guest" — surface it, don't force logout.
          extra: const {ApiErrorMapper.skipSessionHandlingKey: true},
        ),
      );
      final data = response.data;
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && data != null) {
        final reg = RegisterResponse.fromJson(data);
        if (reg.data != null && reg.data!.token.isNotEmpty) {
          return RegisterSuccess(reg);
        }
        return RegisterFailure(
          reg.message.isNotEmpty ? reg.message : 'Could not create account',
        );
      }
      return RegisterFailure(
        apiExtractMessage(data) ?? 'Could not create account',
      );
    } on DioException catch (e) {
      return RegisterFailure(apiMessageFromDioException(e));
    } catch (_) {
      return RegisterFailure('Something went wrong. Please try again.');
    }
  }

  /// POST user/register with multipart/form-data: name, email, password,
  /// password_confirmation, optional [country] (empty when omitted from the app),
  /// and optional [imagePath].
  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String country = '',
    String? imagePath,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('name', name),
        MapEntry('email', email),
        MapEntry('password', password),
        MapEntry('password_confirmation', passwordConfirmation),
        MapEntry('country', country),
      ]);
      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath),
        ));
      }
      final response = await _api.dio.post<Map<String, dynamic>>(
        'user/register',
        data: formData,
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final reg = RegisterResponse.fromJson(data);
        if (reg.status == true && reg.data != null && reg.data!.token.isNotEmpty) {
          return RegisterSuccess(reg);
        }
        return RegisterFailure(
          reg.message.isNotEmpty ? reg.message : 'Registration failed',
        );
      }
      return RegisterFailure(apiExtractMessage(data) ?? 'Registration failed');
    } on DioException catch (e) {
      final message = apiExtractMessage(e.response?.data);
      return RegisterFailure(
        message ?? e.message ?? 'Network error. Please try again.',
      );
    } catch (e) {
      return RegisterFailure('Something went wrong. Please try again.');
    }
  }

  /// POST `user/forgot-password` with `{ "email": "..." }` (Laravel-style).
  ///
  /// If your server uses a different path or shape, adjust here once confirmed.
  Future<ForgotPasswordResult> requestPasswordReset(String email) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        // Postman v1 collection: POST /forgot-password
        'forgot-password',
        data: {'email': email.trim()},
      );
      final data = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final msg = apiExtractMessage(data) ??
            'If an account exists for this email, you will receive reset instructions.';
        return ForgotPasswordSuccess(msg);
      }
      return ForgotPasswordFailure(
        apiExtractMessage(data) ?? 'Could not send reset email.',
      );
    } on DioException catch (e) {
      final message = apiExtractMessage(e.response?.data);
      return ForgotPasswordFailure(
        message ?? e.message ?? 'Network error. Please try again.',
      );
    } catch (e) {
      return ForgotPasswordFailure('Something went wrong. Please try again.');
    }
  }

  /// GET user/logout (best-effort).
  Future<String?> logout() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'user/logout',
        options: Options(
          extra: const {
            ApiErrorMapper.skipSessionHandlingKey: true,
          },
        ),
      );
      return apiExtractMessage(response.data) ?? 'Logged out';
    } on DioException catch (e) {
      return apiMessageFromDioException(e);
    } catch (_) {
      return null;
    }
  }

  /// GET `user/session` — refresh stored user after app launch or login.
  Future<ProfileResult> refreshSession() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('user/session');
      final data = response.data;
      if (data == null) return ProfileFailure('Empty response');
      final db = apiExtractDbData(data);
      if (db is! Map) {
        return ProfileFailure(apiExtractMessage(data) ?? 'Invalid response');
      }
      return ProfileSuccess(
        user: UserSession.fromJson(db.cast<String, dynamic>()),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      if (ApiErrorMapper.shouldExpireSession(e)) {
        await SessionManager.instance.handleSessionExpired(
          message: apiMessageFromDioException(e),
        );
      }
      return ProfileFailure(apiMessageFromDioException(e));
    } catch (_) {
      return ProfileFailure('Something went wrong');
    }
  }

  /// POST `reset-password` after user receives email token.
  Future<ForgotPasswordResult> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'reset-password',
        data: <String, dynamic>{
          'email': email.trim(),
          'token': token.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      final data = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return ForgotPasswordSuccess(
          apiExtractMessage(data) ?? 'Password updated successfully.',
        );
      }
      return ForgotPasswordFailure(
        apiExtractMessage(data) ?? 'Could not reset password.',
      );
    } on DioException catch (e) {
      return ForgotPasswordFailure(apiMessageFromDioException(e));
    } catch (_) {
      return ForgotPasswordFailure('Something went wrong');
    }
  }

  /// GET `profile` (requires Bearer token).
  Future<ProfileResult> profile() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('profile');
      final data = response.data;
      if (data == null) return ProfileFailure('Empty response');
      final db = apiExtractDbData(data);
      if (db is! Map) {
        return ProfileFailure(apiExtractMessage(data) ?? 'Invalid response');
      }
      return ProfileSuccess(
        user: UserSession.fromJson(db.cast<String, dynamic>()),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return ProfileFailure(apiMessageFromDioException(e));
    } catch (_) {
      return ProfileFailure('Something went wrong');
    }
  }

  /// POST `profile-update` (multipart). Sends provided fields only.
  Future<ProfileResult> updateProfile({
    String? name,
    String? email,
    String? country,
    String? bio,
    String? imagePath,
  }) async {
    try {
      final form = FormData();
      if (name != null) form.fields.add(MapEntry('name', name));
      if (email != null) form.fields.add(MapEntry('email', email));
      if (country != null) form.fields.add(MapEntry('country', country));
      if (bio != null) form.fields.add(MapEntry('bio', bio));
      if (imagePath != null && imagePath.isNotEmpty) {
        form.files.add(
          MapEntry('image', await MultipartFile.fromFile(imagePath)),
        );
      }

      // Postman v1 collection: PUT /profile-update
      final response = await _api.dio.put<Map<String, dynamic>>(
        'profile-update',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return ProfileFailure('Empty response');
      final db = apiExtractDbData(data);
      if (db is! Map) {
        return ProfileFailure(apiExtractMessage(data) ?? 'Invalid response');
      }
      return ProfileSuccess(
        user: UserSession.fromJson(db.cast<String, dynamic>()),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return ProfileFailure(apiMessageFromDioException(e));
    } catch (_) {
      return ProfileFailure('Something went wrong');
    }
  }

  /// POST `profile/password`.
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Postman v1 collection: PUT /profile/password
      final response = await _api.dio.put<Map<String, dynamic>>(
        'profile/password',
        data: <String, dynamic>{
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      final data = response.data;
      final msg = apiExtractMessage(data);
      return ChangePasswordSuccess(message: msg);
    } on DioException catch (e) {
      return ChangePasswordFailure(apiMessageFromDioException(e));
    } catch (_) {
      return ChangePasswordFailure('Something went wrong');
    }
  }
}
