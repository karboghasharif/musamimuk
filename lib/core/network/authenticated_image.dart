import 'package:flutter/widgets.dart';

import 'api_client.dart';
import '../config/online_asset_config.dart';
import '../utils/pref_utils.dart';

/// Headers needed to load [url]: the session bearer token for Musamimuk hosts,
/// or provider-specific headers for third-party online asset hosts.
Map<String, String> musamiAuthenticatedHeadersForUrl(
  String url, {
  String? token,
}) {
  final uri = Uri.tryParse(url);
  if (uri == null) return const {};
  if (!isTrustedMusamimukUri(uri)) {
    return OnlineAssetConfig.headersForHost(uri.host);
  }
  token ??= PrefUtils().getToken();
  if (token == null || token.isEmpty) return const {};
  return {'Authorization': 'Bearer $token'};
}

ImageProvider<Object> musamiAuthenticatedNetworkImage(String url) {
  return NetworkImage(url, headers: musamiAuthenticatedHeadersForUrl(url));
}
