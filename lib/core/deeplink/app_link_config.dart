import '../network/api_client.dart';

/// Deep-link hosts, custom scheme, and store fallbacks.
abstract final class AppLinkConfig {
  /// Custom URL scheme used when App Links are unavailable.
  static const String customScheme = 'musamimuk';

  /// Android / Play package id (unchanged; Play listing already live).
  static const String androidPackageId = 'com.musamimuk.app';

  /// iOS App Store bundle id (`com.musamimuk.app` was unavailable on Apple).
  static const String iosBundleId = 'com.musamimuk.ios.app';

  /// Apple Developer Team ID for `apple-app-site-association` (`appID`).
  static const String iosTeamId = '3FZZ5UHWCA';

  /// Numeric App Store Connect app id (`id1234567890`). Fill after first listing.
  static const String iosAppStoreId = '';

  /// Play Store listing used when the Android app is not installed.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// App Store listing (or search fallback until [iosAppStoreId] is set).
  static String get appStoreUrl {
    final id = iosAppStoreId.trim();
    if (id.isEmpty) {
      return 'https://apps.apple.com/search?term=Musamimuk';
    }
    return 'https://apps.apple.com/app/id$id';
  }

  /// Store URL for the current mobile platform.
  static String storeUrl({required bool isIos}) =>
      isIos ? appStoreUrl : playStoreUrl;

  /// AASA `appID` value: `TEAMID.bundleId`.
  static String get iosAasaAppId => '$iosTeamId.$iosBundleId';

  /// HTTPS hosts that may open the app (must host Digital Asset Links / AASA).
  static Set<String> get httpsHosts {
    final hosts = <String>{
      'srv1813447.hstgr.cloud',
      'musamimuk.app',
      'www.musamimuk.app',
    };
    try {
      final apiHost = Uri.parse(baseUrl).host.trim().toLowerCase();
      if (apiHost.isNotEmpty) hosts.add(apiHost);
    } catch (_) {}
    return hosts;
  }

  /// Public https base used when the app builds shareable open links.
  static String get publicHttpsBase {
    final host = httpsHosts.first;
    return 'https://$host';
  }
}
