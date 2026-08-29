import 'package:musamimuk/core/network/api_utils.dart';

/// Payload from `GET /public/app-version`.
class AppVersionPolicy {
  const AppVersionPolicy({
    required this.forceUpdate,
    required this.message,
    required this.messageAr,
    required this.android,
    required this.ios,
  });

  final bool forceUpdate;
  final String message;
  final String messageAr;
  final AppPlatformVersionPolicy android;
  final AppPlatformVersionPolicy ios;

  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    final androidRaw = json['android'];
    final iosRaw = json['ios'];
    return AppVersionPolicy(
      forceUpdate: apiParseBool(json['force_update']) ?? true,
      message: apiParseString(
        json['message'],
        fallback:
            'A new version of Musamimuk is required. Please update to continue.',
      ),
      messageAr: apiParseString(
        json['message_ar'],
        fallback: 'يتوفر إصدار جديد من مصمّمك. يرجى التحديث للمتابعة.',
      ),
      android: AppPlatformVersionPolicy.fromJson(
        androidRaw is Map
            ? androidRaw.cast<String, dynamic>()
            : const <String, dynamic>{},
      ),
      ios: AppPlatformVersionPolicy.fromJson(
        iosRaw is Map
            ? iosRaw.cast<String, dynamic>()
            : const <String, dynamic>{},
      ),
    );
  }

  String localizedMessage({required bool arabic}) =>
      arabic && messageAr.trim().isNotEmpty ? messageAr : message;
}

class AppPlatformVersionPolicy {
  const AppPlatformVersionPolicy({
    required this.minBuild,
    required this.latestBuild,
    required this.minVersion,
    required this.storeUrl,
  });

  final int minBuild;
  final int latestBuild;
  final String minVersion;
  final String storeUrl;

  factory AppPlatformVersionPolicy.fromJson(Map<String, dynamic> json) {
    return AppPlatformVersionPolicy(
      minBuild: apiParseInt(json['min_build']),
      latestBuild: apiParseInt(json['latest_build']),
      minVersion: apiParseString(json['min_version']),
      storeUrl: apiParseString(json['store_url']),
    );
  }

  /// True when installed [buildNumber] is below the required minimum.
  bool requiresForceUpdate(int buildNumber) =>
      minBuild > 0 && buildNumber < minBuild;
}
