import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:musamimuk/core/network/api_error_mapper.dart';
import 'package:musamimuk/core/session/session_manager.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';
import 'package:musamimuk/data/models/wallet_models.dart';

/// Base URL for the musamimuk API (versioned root). Paths in repositories are
/// relative to this (e.g. `user/login` → `…/api/v1/user/login`).
const String baseUrl = 'https://srv1813447.hstgr.cloud/api/v1/';

bool isTrustedMusamimukUri(Uri uri) {
  final apiUri = Uri.parse(baseUrl);
  int effectivePort(Uri value) {
    if (value.hasPort) return value.port;
    return value.scheme == 'https' ? 443 : 80;
  }

  return uri.scheme == apiUri.scheme &&
      uri.host == apiUri.host &&
      effectivePort(uri) == effectivePort(apiUri);
}

/// Dio-based API client with interceptors for auth, session expiry, and logging.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(_AuthSessionInterceptor());
    _dio.interceptors.add(_ApiLoggerInterceptor());
  }

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;
}

/// Attaches Bearer tokens and handles global 401 / auth-related 403 responses.
class _AuthSessionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = PrefUtils().getToken();
    final isTrustedOrigin = isTrustedMusamimukUri(options.uri);
    if (token != null && token.isNotEmpty && isTrustedOrigin) {
      options.headers['Authorization'] = 'Bearer $token';
    } else if (!isTrustedOrigin) {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final friendly = ApiErrorMapper.messageFromDio(err);
    final mapped = err.copyWith(message: friendly);

    if (ApiErrorMapper.shouldExpireSession(err)) {
      unawaited(
        SessionManager.instance.handleSessionExpired(message: friendly),
      );
    } else if (ApiErrorMapper.isGuestForbidden(err)) {
      SessionManager.instance.handleGuestForbidden(message: friendly);
    } else if (ApiErrorMapper.isInsufficientCoins(err)) {
      SessionManager.instance.handleInsufficientCoins(
        InsufficientCoinsInfo.fromResponse(
          body: err.response?.data,
          fallbackMessage: friendly,
        ),
      );
    }

    handler.next(mapped);
  }
}

/// Interceptor that logs API request and response (or error).
class _ApiLoggerInterceptor extends Interceptor {
  static const int _maxBodyLength = 2000;
  static const Set<String> _sensitiveKeys = {
    'authorization',
    'token',
    'access_token',
    'refresh_token',
    'password',
    'password_confirmation',
    'prompt',
    'messages',
    'contents',
    'b64_json',
    'design_data',
  };

  static String _truncate(dynamic data) {
    if (data == null) return 'null';
    final safeData = _redact(data);
    final s = safeData is String ? safeData : safeData.toString();
    if (s.length <= _maxBodyLength) return s;
    return '${s.substring(0, _maxBodyLength)}... [truncated ${s.length - _maxBodyLength} chars]';
  }

  static dynamic _redact(dynamic value, {String? key}) {
    if (key != null && _sensitiveKeys.contains(key.toLowerCase())) {
      return '<redacted>';
    }
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _redact(entry.value, key: entry.key.toString()),
      };
    }
    if (value is Iterable) {
      return value.map((entry) => _redact(entry)).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _safeHeaders(RequestOptions options) {
    final map = Map<String, dynamic>.from(options.headers);
    if (map.containsKey('Authorization')) {
      map['Authorization'] = 'Bearer ***';
    }
    return map;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌── API Request ──');
      debugPrint('│ ${options.method} ${options.uri}');
      debugPrint('│ Headers: ${_safeHeaders(options)}');
      if (options.data != null) {
        if (options.data is FormData) {
          final fd = options.data! as FormData;
          final fields = fd.fields.map((e) => e.key).toList();
          final files = fd.files.map((e) => e.key).toList();
          debugPrint(
            '│ Body: FormData fields=[${fields.join(', ')}] files=[${files.join(', ')}]',
          );
        } else {
          debugPrint('│ Body: ${_truncate(options.data)}');
        }
      }
      debugPrint('└────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌── API Response ──');
      debugPrint(
        '│ ${response.requestOptions.method} ${response.requestOptions.uri}',
      );
      debugPrint('│ Status: ${response.statusCode}');
      if (response.data != null) {
        debugPrint('│ Body: ${_truncate(response.data)}');
      }
      debugPrint('└─────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌── API Error ──');
      debugPrint('│ ${err.requestOptions.method} ${err.requestOptions.uri}');
      debugPrint('│ Message: ${err.message}');
      debugPrint('│ Type: ${err.type}');
      if (err.response != null) {
        debugPrint('│ Status: ${err.response?.statusCode}');
        if (err.response?.data != null) {
          debugPrint('│ Body: ${_truncate(err.response?.data)}');
        }
      }
      debugPrint('└───────────────');
    }
    handler.next(err);
  }
}
