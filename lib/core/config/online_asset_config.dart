/// Config for third-party "Online Assets" providers.
///
/// Only hosts that need special request handling are listed here; everything
/// else is a plain public URL.
class OnlineAssetConfig {
  OnlineAssetConfig._();

  /// Art Institute of Chicago blocks generic clients on both their API and
  /// their IIIF image server with HTTP 403 unless a descriptive
  /// [articUserAgentHeader] is sent, so every artic.edu request needs it.
  static const String articHost = 'artic.edu';
  static const String articUserAgentHeader = 'AIC-User-Agent';
  static const String articUserAgentValue =
      'Musamimuk (support@musamimuk.com)';

  /// Headers required by a third-party asset host, or empty when none.
  static Map<String, String> headersForHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == articHost || normalized.endsWith('.$articHost')) {
      return const {articUserAgentHeader: articUserAgentValue};
    }
    return const {};
  }
}
