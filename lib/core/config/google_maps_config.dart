import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Google Maps / Places / Geocoding key.
///
/// Resolution order:
/// 1. `--dart-define=GOOGLE_MAPS_API_KEY=…` (build-time)
/// 2. Native iOS `GMSApiKey` / Android meta-data via method channel (runtime)
///
/// Native Android/iOS SDKs still read their own key from local.properties / xcconfig.
abstract final class GoogleMapsConfig {
  static const String _dartDefineKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const MethodChannel _channel =
      MethodChannel('com.musamimuk/google_maps');

  /// Bias autocomplete toward Saudi Arabia for Print KYC.
  static const String country = 'sa';

  static String? _runtimeKey;
  static bool _loaded = false;

  /// Effective key for Dart Places / Geocoding HTTP calls.
  static String get apiKey {
    if (_dartDefineKey.isNotEmpty) return _dartDefineKey;
    return _runtimeKey ?? '';
  }

  /// True when a non-empty key is available (after [ensureLoaded]).
  static bool get isConfigured => apiKey.isNotEmpty;

  /// Load native key once (safe to call repeatedly). No-op on web.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    if (_dartDefineKey.isNotEmpty) {
      _loaded = true;
      return;
    }
    if (kIsWeb) {
      _loaded = true;
      return;
    }
    try {
      final value = await _channel.invokeMethod<String>('getApiKey');
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        _runtimeKey = trimmed;
      }
    } on MissingPluginException {
      // Channel not registered (older build) — treat as unconfigured.
    } on PlatformException {
      // Native error — leave empty; UI shows fallback.
    }
    _loaded = true;
  }
}
