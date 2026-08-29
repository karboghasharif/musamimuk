import '../network/api_client.dart';

/// Deep-link hosts, custom scheme, and Play Store fallback.
abstract final class AppLinkConfig {
  /// Custom URL scheme used when App Links are unavailable.
  static const String customScheme = 'musamimuk';

  /// Android / Play package id.
  static const String androidPackageId = 'com.musamimuk.app';

  /// Play Store listing used when the app is not installed.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// HTTPS hosts that may open the app (must host Digital Asset Links).
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
