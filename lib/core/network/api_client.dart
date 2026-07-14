import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:musamimuk/core/network/api_error_mapper.dart';
import 'package:musamimuk/core/session/session_manager.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';

/// Base URL for the musamimuk API (versioned root). Paths in repositories are
/// relative to this (e.g. `user/login` → `…/api/v1/user/login`).
const String baseUrl = 'https://srv1813447.hstgr.cloud/api/v1/';

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
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
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
    }

    handler.next(mapped);
  }
}

/// Interceptor that logs API request and response (or error).
class _ApiLoggerInterceptor extends Interceptor {
  static const int _maxBodyLength = 2000;

  static String _truncate(dynamic data) {
    if (data == null) return 'null';
    final s = data is String ? data : data.toString();
    if (s.length <= _maxBodyLength) return s;
    return '${s.substring(0, _maxBodyLength)}... [truncated ${s.length - _maxBodyLength} chars]';
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
