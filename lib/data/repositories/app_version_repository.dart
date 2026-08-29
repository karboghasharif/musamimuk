import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_utils.dart';
import '../models/app_version_models.dart';

sealed class AppVersionResult<T> {}

class AppVersionSuccess<T> extends AppVersionResult<T> {
  AppVersionSuccess(this.data, {this.message});
  final T data;
  final String? message;
}

class AppVersionFailure<T> extends AppVersionResult<T> {
  AppVersionFailure(this.message);
  final String message;
}

/// Outcome of comparing the installed build to the server policy.
class AppVersionGateDecision {
  const AppVersionGateDecision({
    required this.blocked,
    required this.storeUrl,
    required this.message,
    required this.currentBuild,
    required this.minBuild,
  });

  final bool blocked;
  final String storeUrl;
  final String message;
  final int currentBuild;
  final int minBuild;
}

/// Client for `GET /public/app-version` (no auth).
class AppVersionRepository {
  AppVersionRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<AppVersionResult<AppVersionPolicy>> fetchPolicy() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'public/app-version',
      );
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return AppVersionFailure(
          apiExtractMessage(envelope) ?? 'Unable to check app version.',
        );
      }
      final map = apiExtractPayloadMap(envelope) ??
          (envelope['data'] is Map
              ? (envelope['data'] as Map).cast<String, dynamic>()
              : null);
      if (map == null) {
        return AppVersionFailure('Invalid app version response.');
      }
      return AppVersionSuccess(
        AppVersionPolicy.fromJson(map),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return AppVersionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AppVersionFailure('Unable to check app version.');
    }
  }

  /// Fetches policy + local package info and decides whether to block the app.
  ///
  /// On network failure, returns [blocked]=false so offline users are not locked out.
  Future<AppVersionGateDecision> evaluateGate({bool arabic = false}) async {
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;
    final result = await fetchPolicy();
    if (result is AppVersionFailure<AppVersionPolicy>) {
      if (kDebugMode) {
        debugPrint('AppVersionRepository.evaluateGate: ${result.message}');
      }
      return AppVersionGateDecision(
        blocked: false,
        storeUrl: _defaultStoreUrl(),
        message: result.message,
        currentBuild: currentBuild,
        minBuild: 0,
      );
    }

    final policy = (result as AppVersionSuccess<AppVersionPolicy>).data;
    final platform = _isIos ? policy.ios : policy.android;
    final mustUpdate =
        policy.forceUpdate && platform.requiresForceUpdate(currentBuild);
    final storeUrl = platform.storeUrl.trim().isNotEmpty
        ? platform.storeUrl.trim()
        : _defaultStoreUrl();

    return AppVersionGateDecision(
      blocked: mustUpdate,
      storeUrl: storeUrl,
      message: policy.localizedMessage(arabic: arabic),
      currentBuild: currentBuild,
      minBuild: platform.minBuild,
    );
  }

  bool get _isIos {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  String _defaultStoreUrl() {
    if (_isIos) {
      return '';
    }
    return 'https://play.google.com/store/apps/details?id=com.musamimuk.app';
  }
}
