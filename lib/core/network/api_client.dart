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
    // Logger outermost so every request/response/error is printed (incl. after auth).
    _dio.interceptors.add(_ApiLoggerInterceptor());
    _dio.interceptors.add(_AuthSessionInterceptor());
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

/// Interceptor that logs every API request / response / error in debug builds.
///
/// Uses [print] (not [debugPrint]) so Android logcat does not throttle/drop traces
/// when Purchases and other noisy plugins flood the console. Filter: `[API]`.
class _ApiLoggerInterceptor extends Interceptor {
  static const int _maxBodyLength = 4000;
  static const String _extraStartedAt = 'api_log_started_at';
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

  /// Unthrottled console output for bug tracing.
  static void _log(String line) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print(line);
  }

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
    if (value is Iterable && value is! String) {
      return value.map((entry) => _redact(entry)).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) {
    final map = Map<String, dynamic>.from(headers);
    for (final key in map.keys.toList()) {
      if (key.toLowerCase() == 'authorization') {
        map[key] = 'Bearer ***';
      }
    }
    return map;
  }

  static String _describeBody(dynamic data) {
    if (data == null) return 'null';
    if (data is FormData) {
      final fields = data.fields
          .map((e) {
            final value = _sensitiveKeys.contains(e.key.toLowerCase())
                ? '<redacted>'
                : e.value;
            return '${e.key}=$value';
          })
          .join(', ');
      final files = data.files.map((e) {
        final file = e.value;
        final name = file.filename ?? '(no-name)';
        final len = file.length;
        final lenLabel = len >= 0 ? '${len}B' : 'stream';
        return '${e.key}:$name($lenLabel)';
      }).join(', ');
      return 'FormData fields={$fields} files={$files}';
    }
    return _truncate(data);
  }

  static String _elapsed(RequestOptions options) {
    final started = options.extra[_extraStartedAt];
    if (started is DateTime) {
      return '${DateTime.now().difference(started).inMilliseconds}ms';
    }
    return '?';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_extraStartedAt] = DateTime.now();
    // Auth runs after this interceptor; re-read token for the log line.
    final token = PrefUtils().getToken();
    final headers = _safeHeaders(Map<String, dynamic>.from(options.headers));
    if (token != null &&
        token.isNotEmpty &&
        isTrustedMusamimukUri(options.uri)) {
      headers['Authorization'] = 'Bearer ***';
    }
    _log('[API] ── REQUEST ─────────────────────────────');
    _log('[API] ${options.method} ${options.uri}');
    if (options.queryParameters.isNotEmpty) {
      _log('[API] Query: ${options.queryParameters}');
    }
    _log('[API] Headers: $headers');
    if (options.data != null) {
      _log('[API] Body: ${_describeBody(options.data)}');
    }
    _log('[API] ────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final req = response.requestOptions;
    _log('[API] ── RESPONSE ────────────────────────────');
    _log('[API] ${req.method} ${req.uri}');
    _log('[API] Status: ${response.statusCode}  (${_elapsed(req)})');
    if (response.data != null) {
      _log('[API] Body: ${_truncate(response.data)}');
    }
    _log('[API] ────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    _log('[API] ── ERROR ───────────────────────────────');
    _log('[API] ${req.method} ${req.uri}');
    _log('[API] Type: ${err.type}  (${_elapsed(req)})');
    _log('[API] Message: ${err.message}');
    if (err.response != null) {
      _log('[API] Status: ${err.response?.statusCode}');
      if (err.response?.data != null) {
        _log('[API] Body: ${_truncate(err.response?.data)}');
      }
    } else if (err.error != null) {
      _log('[API] Cause: ${err.error}');
    }
    _log('[API] ────────────────────────────────────────');
    handler.next(err);
  }
}
