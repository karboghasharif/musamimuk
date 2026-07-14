import 'package:dio/dio.dart';

import '../session/session_manager.dart';
import '../utils/pref_utils.dart';
import 'api_utils.dart';

/// Session-aware helpers on top of [apiMessageFromDioException].
class ApiErrorMapper {
  ApiErrorMapper._();

  /// Extra key: set `true` on a request to skip session-expiry handling.
  static const String skipSessionHandlingKey = 'skipSessionHandling';

  static String messageFromDio(DioException e) => apiMessageFromDioException(e);

  /// Whether this error should force a global session reset.
  static bool shouldExpireSession(DioException e) {
    final skip = e.requestOptions.extra[skipSessionHandlingKey] == true;
    if (skip) return false;

    final path = e.requestOptions.path;
    if (SessionManager.instance.isAuthEndpoint(path)) return false;

    final hadAuthHeader =
        (e.requestOptions.headers['Authorization']?.toString() ?? '')
            .isNotEmpty;
    if (!hadAuthHeader) return false;

    if (_isInvalidSessionRefresh(e)) return true;

    final status = e.response?.statusCode;
    if (status == 401) return true;

    // Guests legitimately receive 403 on account-only actions — never treat
    // those as an expired session (handled by [isGuestForbidden] instead).
    if (status == 403 && PrefUtils().isGuestAccount()) return false;

    // Some backends return 403 for invalid/expired tokens.
    if (status == 403) {
      final body = (apiExtractMessage(e.response?.data) ?? '').toLowerCase();
      const markers = [
        'unauthenticated',
        'unauthorized',
        'token',
        'session',
        'expired',
        'invalid jwt',
        'jwt',
        'login again',
        'not logged in',
      ];
      for (final marker in markers) {
        if (body.contains(marker)) return true;
      }
    }
    return false;
  }

  /// `GET user/session` returning a generic server error means the stored
  /// session is no longer valid on the backend.
  static bool _isInvalidSessionRefresh(DioException e) {
    final path = e.requestOptions.path.toLowerCase();
    if (!path.contains('user/session')) return false;

    final status = e.response?.statusCode;
    if (status == 401) return true;

    final message = (apiExtractMessage(e.response?.data) ?? '').toLowerCase();
    if (status == 500 && message.contains('something went wrong')) {
      return true;
    }

    final data = e.response?.data;
    if (data is Map) {
      final statusField = data['status'];
      final isFailure = statusField == false ||
          statusField?.toString().toLowerCase() == 'false' ||
          statusField?.toString().toLowerCase() == 'error';
      if (isFailure &&
          status == 500 &&
          message.contains('something went wrong')) {
        return true;
      }
    }

    return false;
  }

  /// A guest hit an account-only action (HTTP 403) → prompt them to upgrade
  /// instead of showing a raw error or logging them out.
  static bool isGuestForbidden(DioException e) {
    if (e.requestOptions.extra[skipSessionHandlingKey] == true) return false;
    if (e.response?.statusCode != 403) return false;
    final path = e.requestOptions.path;
    if (SessionManager.instance.isAuthEndpoint(path)) return false;
    return PrefUtils().isGuestAccount();
  }
}
