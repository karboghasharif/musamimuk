import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'api_client.dart';
import '../config/online_asset_config.dart';
import '../utils/pref_utils.dart';

/// Disk + memory cache for Musamimuk / online-asset network images.
///
/// Shared by [musamiAuthenticatedNetworkImage] and [CachedNetworkImage] UIs so
/// editor layers, redesign restore, ads, and asset browsers hit the same store.
class MusamiImageCache {
  MusamiImageCache._();

  static const String cacheKey = 'musami_image_cache_v1';

  /// ~2 weeks on disk; enough for redesign reopen without refetch storms.
  static final CacheManager instance = CacheManager(
    Config(
      cacheKey,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 400,
    ),
  );
}

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

/// Cached network [ImageProvider] with auth / provider headers.
///
/// Prefer this over raw [NetworkImage] / [Image.network] so previews and
/// editor layers reuse disk cache across sessions.
ImageProvider<Object> musamiAuthenticatedNetworkImage(String url) {
  return CachedNetworkImageProvider(
    url,
    headers: musamiAuthenticatedHeadersForUrl(url),
    cacheManager: MusamiImageCache.instance,
  );
}

/// Reads image bytes from [MusamiImageCache] (downloads once if missing).
Future<Uint8List?> musamiCachedNetworkImageBytes(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  try {
    final file = await MusamiImageCache.instance.getSingleFile(
      trimmed,
      headers: musamiAuthenticatedHeadersForUrl(trimmed),
    );
    final bytes = await file.readAsBytes();
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}
