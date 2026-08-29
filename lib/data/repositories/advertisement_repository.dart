import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/advertisement_platform.dart';
import 'package:musamimuk/data/models/advertisement.dart';

sealed class AdvertisementResult<T> {}

class AdvertisementSuccess<T> extends AdvertisementResult<T> {
  AdvertisementSuccess(this.data, {this.message});
  final T data;
  final String? message;
}

class AdvertisementFailure<T> extends AdvertisementResult<T> {
  AdvertisementFailure(this.message);
  final String message;
}

/// Public advertisement endpoints (no auth required).
class AdvertisementRepository {
  AdvertisementRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  static final Map<String, List<Advertisement>> _adsCache = {};
  static final Map<String, Future<AdvertisementResult<List<Advertisement>>>>
  _adsInFlight = {};

  static String _adsCacheKey({
    required String placement,
    String? platform,
    required int limit,
  }) => '$placement|${platform ?? ''}|$limit';

  /// Returns cached ads when already fetched this session (no network).
  static List<Advertisement>? peekCachedAds({
    required String placement,
    String? platform,
    required int limit,
  }) {
    return _adsCache[_adsCacheKey(
      placement: placement,
      platform: platform,
      limit: limit,
    )];
  }

  static List<Advertisement>? peekCachedAdsForCurrentPlatform({
    required String placement,
    int limit = 10,
  }) {
    return peekCachedAds(
      placement: placement,
      platform: advertisementPlatformParam(),
      limit: limit,
    );
  }

  /// Clears in-memory ads cache (empty responses are never retained).
  static void clearAdsCache({String? placement}) {
    if (placement == null) {
      _adsCache.clear();
      return;
    }
    _adsCache.removeWhere((key, _) => key.startsWith('$placement|'));
  }

  @visibleForTesting
  static void debugResetCache() {
    _adsCache.clear();
    _adsInFlight.clear();
  }

  Future<AdvertisementResult<AdvertisementPlacements>> fetchPlacements() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'public/advertisements/placements',
      );
      final data = response.data;
      if (data == null) return AdvertisementFailure('Empty response');
      if (!apiResponseIsSuccess(data)) {
        return AdvertisementFailure(
          apiExtractMessage(data) ?? 'Could not load placements',
        );
      }
      final inner = apiExtractPayloadMap(data);
      if (inner == null) return AdvertisementFailure('Invalid response');
      return AdvertisementSuccess(
        AdvertisementPlacements.fromJson(inner),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdvertisementFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdvertisementFailure('Something went wrong');
    }
  }

  Future<AdvertisementResult<List<Advertisement>>> fetchAds({
    required String placement,
    String? platform,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final key = _adsCacheKey(
      placement: placement,
      platform: platform,
      limit: limit,
    );

    if (!forceRefresh) {
      final cached = _adsCache[key];
      if (cached != null) {
        return AdvertisementSuccess(List<Advertisement>.from(cached));
      }
    }

    final inFlight = _adsInFlight[key];
    if (inFlight != null) return inFlight;

    final future = _fetchAdsFromNetwork(
      placement: placement,
      platform: platform,
      limit: limit,
    );
    _adsInFlight[key] = future;

    try {
      final result = await future;
      if (result is AdvertisementSuccess<List<Advertisement>>) {
        // Never cache an empty list permanently — revisit should refetch.
        if (result.data.isNotEmpty) {
          _adsCache[key] = List<Advertisement>.from(result.data);
        } else {
          _adsCache.remove(key);
        }
      }
      return result;
    } finally {
      _adsInFlight.remove(key);
    }
  }

  Future<AdvertisementResult<List<Advertisement>>> _fetchAdsFromNetwork({
    required String placement,
    String? platform,
    int limit = 10,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ads] GET public/advertisements '
          'placement=$placement platform=${platform ?? '-'} limit=$limit',
        );
      }
      final response = await _dio.get<Map<String, dynamic>>(
        'public/advertisements',
        queryParameters: <String, dynamic>{
          'placement': placement,
          if (platform != null && platform.isNotEmpty) 'platform': platform,
          'limit': limit.clamp(1, 50).toString(),
        },
      );
      final body = response.data;
      if (body == null) return AdvertisementFailure('Empty response');
      if (!apiResponseIsSuccess(body)) {
        return AdvertisementFailure(
          apiExtractMessage(body) ?? 'Could not load advertisements',
        );
      }

      // Nested: data.advertisements — never parse top-level data as a list.
      final list = Advertisement.parseListFromResponseBody(body);
      if (kDebugMode) {
        debugPrint('[ads] parsed ${list.length} advertisement(s)');
      }
      return AdvertisementSuccess(list, message: apiExtractMessage(body));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[ads] request failed status=${e.response?.statusCode}');
      }
      return AdvertisementFailure(apiMessageFromDioException(e));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ads] parse/unknown error: $e');
      }
      return AdvertisementFailure('Something went wrong');
    }
  }

  Future<AdvertisementResult<List<Advertisement>>> fetchAdsForCurrentPlatform({
    required String placement,
    int limit = 10,
    bool forceRefresh = false,
  }) {
    return fetchAds(
      placement: placement,
      platform: advertisementPlatformParam(),
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> recordImpression(int adId) async {
    try {
      await _dio.post<void>('public/advertisements/$adId/impression');
    } catch (_) {}
  }

  Future<String?> recordClick(int adId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'public/advertisements/$adId/click',
      );
      final data = response.data;
      if (data == null) return null;
      final inner = apiExtractPayloadMap(data);
      final link = inner?['link_url']?.toString().trim();
      if (link == null || link.isEmpty) return null;
      return link;
    } catch (_) {
      return null;
    }
  }
}
