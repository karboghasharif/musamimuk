import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/pref_utils.dart';
import 'api_response_cache.dart';

/// Extra flags for callers that need to bypass or force-refresh cache.
abstract final class ApiCacheExtras {
  static const skipCache = 'api_cache_skip';
  static const forceRefresh = 'api_cache_force_refresh';
  static const fromCache = 'api_cache_from_cache';
}

/// Caches successful GET JSON responses for stable catalog / public APIs.
///
/// Policy: short TTL + local disk. Mutating / personal endpoints are excluded.
class ApiCacheInterceptor extends Interceptor {
  ApiCacheInterceptor({ApiResponseCache? cache})
      : _cache = cache ?? ApiResponseCache.instance;

  final ApiResponseCache _cache;

  /// path-prefix → TTL
  static const Map<String, Duration> _ttlByPrefix = {
    'public/designs/featured': Duration(minutes: 5),
    'public/designs/trending': Duration(minutes: 5),
    'public/app-version': Duration(minutes: 15),
    'public/advertisements/placements': Duration(hours: 6),
    'public/advertisements': Duration(minutes: 10),
    'public/contests': Duration(minutes: 3),
    'category/list': Duration(minutes: 30),
    'category/children': Duration(minutes: 30),
    'shape/list': Duration(minutes: 30),
    'fonts': Duration(minutes: 30),
    'asset/types': Duration(minutes: 30),
    'assets/meta': Duration(minutes: 15),
    'assets/categories': Duration(minutes: 30),
    'referrals/settings': Duration(minutes: 10),
  };

  static const List<String> _neverCachePrefixes = [
    'user/',
    'wallet',
    'print/',
    'notifications',
    'admin/',
    'broadcasting',
    'ai/',
    'editor-ai',
    'background-removal',
    'designs/', // user designs CRUD / open by id — personal
    'design/',
    'referrals/me',
    'referrals/apply',
    'referrals/withdraw',
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    Future<void>(() async {
      if (!_shouldConsider(options)) {
        handler.next(options);
        return;
      }
      if (options.extra[ApiCacheExtras.forceRefresh] == true ||
          options.extra[ApiCacheExtras.skipCache] == true) {
        handler.next(options);
        return;
      }

      final key = _cacheKey(options);
      final ttl = _ttlFor(options);
      if (key == null || ttl == null) {
        handler.next(options);
        return;
      }

      final cached = await _cache.read(key);
      if (cached == null) {
        handler.next(options);
        return;
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print('[API][cache] HIT $key');
      }
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          data: cached,
          statusCode: 200,
          statusMessage: 'OK (cache)',
          extra: <String, dynamic>{
            ...options.extra,
            ApiCacheExtras.fromCache: true,
          },
        ),
      );
    });
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    Future<void>(() async {
      final options = response.requestOptions;
      if (!_shouldConsider(options) ||
          options.extra[ApiCacheExtras.skipCache] == true ||
          (response.statusCode != 200 && response.statusCode != 201)) {
        handler.next(response);
        return;
      }
      final data = response.data;
      if (data is! Map) {
        handler.next(response);
        return;
      }

      final key = _cacheKey(options);
      final ttl = _ttlFor(options);
      if (key != null && ttl != null) {
        await _cache.write(
          key,
          data.cast<String, dynamic>(),
          ttl: ttl,
        );
        if (kDebugMode) {
          // ignore: avoid_print
          print('[API][cache] STORE $key ttl=${ttl.inSeconds}s');
        }
      }
      handler.next(response);
    });
  }

  bool _shouldConsider(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    final path = _normalizedPath(options);
    for (final blocked in _neverCachePrefixes) {
      if (path.startsWith(blocked)) return false;
    }
    return _ttlFor(options) != null;
  }

  Duration? _ttlFor(RequestOptions options) {
    final path = _normalizedPath(options);
    for (final entry in _ttlByPrefix.entries) {
      if (path == entry.key || path.startsWith('${entry.key}/')) {
        return entry.value;
      }
    }
    return null;
  }

  String _normalizedPath(RequestOptions options) {
    var path = options.path;
    if (path.startsWith('/')) path = path.substring(1);
    // Strip baseUrl accidental duplication.
    const marker = 'api/v1/';
    final idx = path.indexOf(marker);
    if (idx >= 0) path = path.substring(idx + marker.length);
    if (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  String? _cacheKey(RequestOptions options) {
    final path = _normalizedPath(options);
    final qp = Map<String, dynamic>.from(options.queryParameters);
    final qpKeys = qp.keys.toList()..sort();
    final qpPart = qpKeys
        .map((k) => '$k=${qp[k]}')
        .join('&');
    // Scope by user when a token exists so personal overlays don't leak.
    final token = PrefUtils().getToken();
    final userScope = (token != null && token.isNotEmpty)
        ? '|u:${token.hashCode.toRadixString(16)}'
        : '|anon';
    return '$path?$qpPart$userScope';
  }
}

/// Test helper: builds the same key the interceptor uses (path + query only).
@visibleForTesting
String debugApiCacheKeyForTest({
  required String path,
  Map<String, dynamic>? query,
  String? token,
}) {
  final qp = Map<String, dynamic>.from(query ?? const {});
  final qpKeys = qp.keys.toList()..sort();
  final qpPart = qpKeys.map((k) => '$k=${qp[k]}').join('&');
  final userScope = (token != null && token.isNotEmpty)
      ? '|u:${token.hashCode.toRadixString(16)}'
      : '|anon';
  var p = path;
  if (p.startsWith('/')) p = p.substring(1);
  if (p.endsWith('/') && p.length > 1) p = p.substring(0, p.length - 1);
  return '$p?$qpPart$userScope';
}

/// Tiny JSON size check used by tests.
@visibleForTesting
int debugJsonSize(Object? value) => utf8.encode(jsonEncode(value)).length;
