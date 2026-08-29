import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/online_asset_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_utils.dart';
import '../models/online_asset_models.dart';

/// Aggregates free/public online asset providers used by the Online Assets picker.
class OnlineAssetRepository {
  OnlineAssetRepository({Dio? dio, ApiClient? apiClient})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 25),
              receiveTimeout: const Duration(seconds: 40),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'Musamimuk/1.0 (Flutter; design editor)',
              },
              validateStatus: (code) =>
                  code != null && code >= 200 && code < 500,
            ),
          ),
      _api = apiClient ?? ApiClient();

  final Dio _dio;
  final ApiClient _api;
  final Random _random = Random();

  static const String articBase = 'https://api.artic.edu/api/v1';
  static const String articIiif = 'https://www.artic.edu/iiif/2';
  static const String metBase =
      'https://collectionapi.metmuseum.org/public/collection/v1';
  static const String colormindUrl = 'http://colormind.io/api/';
  static const String colourLoversBase = 'https://www.colourlovers.com/api';
  static const String emojiHubBase = 'https://emojihub.yurace.pro/api';
  static const String dummyImageBase = 'https://dummyimage.com';
  static const String iconHorseBase = 'https://icon.horse/icon';
  static const String icons8Base = 'https://img.icons8.com';
  static const String lordiconCdn = 'https://cdn.lordicon.com';
  static const String phpNoiseBase = 'https://php-noise.com/noise.php';
  static const String iconifyApiBase = 'https://api.iconify.design';

  /// Popular Iconify icons shown when search is empty (prefix:name).
  static const List<String> iconifyPopular = [
    'mdi:home',
    'mdi:heart',
    'mdi:star',
    'mdi:account',
    'mdi:cog',
    'mdi:magnify',
    'mdi:camera',
    'mdi:image',
    'mdi:pencil',
    'mdi:trash-can',
    'mdi:download',
    'mdi:upload',
    'mdi:share-variant',
    'mdi:bell',
    'mdi:lock',
    'mdi:earth',
    'mdi:calendar',
    'mdi:music',
    'mdi:play',
    'mdi:check',
    'mdi:close',
    'mdi:plus',
    'mdi:minus',
    'mdi:menu',
    'tabler:home',
    'tabler:heart',
    'tabler:search',
    'tabler:settings',
    'tabler:user',
    'tabler:photo',
    'ic:baseline-home',
    'ic:baseline-favorite',
    'ri:home-line',
    'ri:heart-line',
    'solar:home-linear',
    'solar:heart-linear',
  ];

  /// Curated free Lordicon CDN ids (verified JSON 200). Paste more ids from
  /// lordicon.com (CDN: https://cdn.lordicon.com/{id}.json). Attribution: Lordicon.
  static const List<({String id, String name})> lordiconCatalog = [
    (id: 'kbtmbyzy', name: 'System check'),
    (id: 'rhvddzym', name: 'Wired confetti'),
    (id: 'lupuorrc', name: 'Like / heart'),
  ];

  static const List<String> icons8Popular = [
    'home',
    'search',
    'heart',
    'star',
    'settings',
    'user',
    'camera',
    'image',
    'edit',
    'trash',
    'download',
    'upload',
    'share',
    'like',
    'chat',
    'bell',
    'lock',
    'globe',
    'calendar',
    'music',
    'play',
    'pause',
    'check',
    'close',
    'plus',
    'minus',
    'arrow',
    'menu',
    'folder',
    'document',
  ];

  static const List<String> iconHorsePopularDomains = [
    'wikipedia.org',
    'github.com',
    'youtube.com',
    'instagram.com',
    'twitter.com',
    'figma.com',
    'apple.com',
    'google.com',
    'spotify.com',
    'netflix.com',
  ];

  Future<OnlineAssetListResult> list({
    required OnlineAssetProvider provider,
    String query = '',
    int page = 1,
    int pageSize = 24,
  }) {
    return switch (provider) {
      OnlineAssetProvider.unsplash => _listUnsplash(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.pexels => _listPexels(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.pixabay => _listPixabay(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.iconify => _listIconify(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.artic => _listArtic(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.metMuseum => _listMet(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.colormind => _listColormind(
        count: pageSize.clamp(4, 12),
      ),
      OnlineAssetProvider.colourLovers => _listColourLovers(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.dummyImage => Future.value(
        _listDummyImage(query: query),
      ),
      OnlineAssetProvider.emojiHub => _listEmojiHub(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.iconHorse => Future.value(
        _listIconHorse(query: query),
      ),
      OnlineAssetProvider.icons8 => Future.value(_listIcons8(query: query)),
      OnlineAssetProvider.lottieLibrary => _listLottieLibrary(
        query: query,
        page: page,
        pageSize: pageSize,
      ),
      OnlineAssetProvider.lordicon => Future.value(_listLordicon(query: query)),
      OnlineAssetProvider.phpNoise => Future.value(_listPhpNoise(query: query)),
    };
  }

  /// Unsplash guideline: ping download_location when the user places a photo.
  Future<void> trackUnsplashDownload(String downloadLocation) async {
    final loc = downloadLocation.trim();
    if (loc.isEmpty) return;
    try {
      await _api.dio.post(
        'online-assets/unsplash/download',
        data: {'download_location': loc},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Unsplash download track: $e');
    }
  }

  // ── Unsplash (via Musamimuk backend proxy) ───────────────────────────────

  Future<OnlineAssetListResult> _listUnsplash({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final res = await _api.dio.get(
        'online-assets/unsplash/search',
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          'page': page,
          'per_page': pageSize.clamp(1, 30),
        },
      );
      final body = res.data;
      if (body is! Map) {
        return OnlineAssetListFailure('Unexpected Unsplash response.');
      }
      if (body['success'] != true) {
        return OnlineAssetListFailure(
          apiParseString(body['message'], fallback: 'Could not load Unsplash.'),
        );
      }
      final data = body['data'];
      final list = data is Map ? data['items'] : null;
      if (list is! List) {
        return OnlineAssetListFailure('Unexpected Unsplash response.');
      }
      final items = <OnlineAssetItem>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final imageUrl = apiParseString(map['image_url']);
        if (imageUrl.isEmpty) continue;
        final id = apiParseString(map['id'], fallback: imageUrl);
        items.add(
          OnlineAssetItem(
            id: 'unsplash_$id',
            title: apiParseString(map['title'], fallback: 'Unsplash photo'),
            provider: OnlineAssetProvider.unsplash,
            applyKind: OnlineAssetApplyKind.image,
            imageUrl: imageUrl,
            thumbUrl: apiParseString(map['thumb_url'], fallback: imageUrl),
            width: map['width'] == null ? null : apiParseInt(map['width']),
            height: map['height'] == null ? null : apiParseInt(map['height']),
            attribution: apiParseString(
              map['attribution'],
              fallback: 'Unsplash',
            ),
            downloadLocation: apiParseString(map['download_location']),
          ),
        );
      }
      final meta = body['meta'];
      final next = meta is Map ? meta['next_page'] : null;
      final totalPages = meta is Map
          ? apiParseInt(meta['total_pages'], fallback: page)
          : page;
      return OnlineAssetListSuccess(
        items,
        hasMore: next != null || page < totalPages,
        nextPage: next is int ? next : (page < totalPages ? page + 1 : null),
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Unsplash: $e');
      return OnlineAssetListFailure('Could not load Unsplash photos.');
    }
  }

  // ── Pexels (via Musamimuk backend proxy) ─────────────────────────────────

  Future<OnlineAssetListResult> _listPexels({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final res = await _api.dio.get(
        'online-assets/pexels/search',
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          'page': page,
          'per_page': pageSize.clamp(1, 80),
        },
      );
      final body = res.data;
      if (body is! Map) {
        return OnlineAssetListFailure('Unexpected Pexels response.');
      }
      if (body['success'] != true) {
        return OnlineAssetListFailure(
          apiParseString(body['message'], fallback: 'Could not load Pexels.'),
        );
      }
      final data = body['data'];
      final list = data is Map ? data['items'] : null;
      if (list is! List) {
        return OnlineAssetListFailure('Unexpected Pexels response.');
      }
      final items = <OnlineAssetItem>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final imageUrl = apiParseString(map['image_url']);
        if (imageUrl.isEmpty) continue;
        final id = apiParseString(map['id'], fallback: imageUrl);
        items.add(
          OnlineAssetItem(
            id: 'pexels_$id',
            title: apiParseString(map['title'], fallback: 'Pexels photo'),
            provider: OnlineAssetProvider.pexels,
            applyKind: OnlineAssetApplyKind.image,
            imageUrl: imageUrl,
            thumbUrl: apiParseString(map['thumb_url'], fallback: imageUrl),
            width: map['width'] == null ? null : apiParseInt(map['width']),
            height: map['height'] == null ? null : apiParseInt(map['height']),
            attribution: apiParseString(map['attribution'], fallback: 'Pexels'),
          ),
        );
      }
      final meta = body['meta'];
      final next = meta is Map ? meta['next_page'] : null;
      final totalPages = meta is Map
          ? apiParseInt(meta['total_pages'], fallback: page)
          : page;
      return OnlineAssetListSuccess(
        items,
        hasMore: next != null || page < totalPages,
        nextPage: next is int ? next : (page < totalPages ? page + 1 : null),
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Pexels: $e');
      return OnlineAssetListFailure('Could not load Pexels photos.');
    }
  }

  // ── Pixabay (via Musamimuk backend proxy) ────────────────────────────────

  Future<OnlineAssetListResult> _listPixabay({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final res = await _api.dio.get(
        'online-assets/pixabay/search',
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          'page': page,
          'per_page': pageSize.clamp(3, 80),
        },
      );
      final body = res.data;
      if (body is! Map) {
        return OnlineAssetListFailure('Unexpected Pixabay response.');
      }
      if (body['success'] != true) {
        return OnlineAssetListFailure(
          apiParseString(body['message'], fallback: 'Could not load Pixabay.'),
        );
      }
      final data = body['data'];
      final list = data is Map ? data['items'] : null;
      if (list is! List) {
        return OnlineAssetListFailure('Unexpected Pixabay response.');
      }
      final items = <OnlineAssetItem>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final imageUrl = apiParseString(map['image_url']);
        if (imageUrl.isEmpty) continue;
        final id = apiParseString(map['id'], fallback: imageUrl);
        items.add(
          OnlineAssetItem(
            id: 'pixabay_$id',
            title: apiParseString(map['title'], fallback: 'Pixabay image'),
            provider: OnlineAssetProvider.pixabay,
            applyKind: OnlineAssetApplyKind.image,
            imageUrl: imageUrl,
            thumbUrl: apiParseString(map['thumb_url'], fallback: imageUrl),
            width: map['width'] == null ? null : apiParseInt(map['width']),
            height: map['height'] == null ? null : apiParseInt(map['height']),
            attribution: apiParseString(
              map['attribution'],
              fallback: 'Pixabay',
            ),
          ),
        );
      }
      final meta = body['meta'];
      final next = meta is Map ? meta['next_page'] : null;
      final totalPages = meta is Map
          ? apiParseInt(meta['total_pages'], fallback: page)
          : page;
      return OnlineAssetListSuccess(
        items,
        hasMore: next != null || page < totalPages,
        nextPage: next is int ? next : (page < totalPages ? page + 1 : null),
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Pixabay: $e');
      return OnlineAssetListFailure('Could not load Pixabay images.');
    }
  }

  // ── Iconify (public API — no key) ────────────────────────────────────────

  /// Builds an Iconify SVG URL for [prefix:name].
  /// Docs: https://iconify.design/docs/api/
  static String iconifySvgUrl(
    String iconId, {
    int height = 128,
    String colorHex = '111111',
  }) {
    final parts = iconId.split(':');
    if (parts.length != 2) {
      return '$iconifyApiBase/${Uri.encodeComponent(iconId)}.svg?height=$height';
    }
    final prefix = Uri.encodeComponent(parts[0]);
    final name = Uri.encodeComponent(parts[1]);
    final color = colorHex.replaceAll('#', '');
    return '$iconifyApiBase/$prefix/$name.svg?height=$height&color=%23$color';
  }

  OnlineAssetItem _iconifyItem(String iconId) {
    final svg = iconifySvgUrl(iconId);
    return OnlineAssetItem(
      id: 'iconify_$iconId',
      title: iconId,
      provider: OnlineAssetProvider.iconify,
      applyKind: OnlineAssetApplyKind.svg,
      svgUrl: svg,
      thumbUrl: svg,
      imageUrl: svg,
      width: 128,
      height: 128,
      attribution: 'Iconify',
    );
  }

  Future<OnlineAssetListResult> _listIconify({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final q = query.trim();
      if (q.isEmpty) {
        final start = ((page - 1) * pageSize).clamp(0, iconifyPopular.length);
        final end = (start + pageSize).clamp(0, iconifyPopular.length);
        final slice = iconifyPopular.sublist(start, end);
        return OnlineAssetListSuccess(
          slice.map(_iconifyItem).toList(),
          hasMore: end < iconifyPopular.length,
          nextPage: end < iconifyPopular.length ? page + 1 : null,
        );
      }

      final res = await _dio.get<Map<String, dynamic>>(
        '$iconifyApiBase/search',
        queryParameters: {'query': q, 'limit': 64},
      );
      if (res.statusCode != 200 || res.data == null) {
        return OnlineAssetListFailure('Could not search Iconify.');
      }
      final icons = res.data!['icons'];
      if (icons is! List || icons.isEmpty) {
        return OnlineAssetListSuccess(const []);
      }
      final ids = icons
          .map((e) => e.toString())
          .where((e) => e.contains(':'))
          .toList();
      final start = ((page - 1) * pageSize).clamp(0, ids.length);
      final end = (start + pageSize).clamp(0, ids.length);
      final slice = ids.sublist(start, end);
      return OnlineAssetListSuccess(
        slice.map(_iconifyItem).toList(),
        hasMore: end < ids.length,
        nextPage: end < ids.length ? page + 1 : null,
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Iconify: $e');
      return OnlineAssetListFailure('Could not load Iconify icons.');
    }
  }

  // ── Art Institute of Chicago ─────────────────────────────────────────────

  Future<OnlineAssetListResult> _listArtic({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final q = query.trim().isEmpty ? 'art' : query.trim();
      final res = await _dio.get<Map<String, dynamic>>(
        '$articBase/artworks/search',
        queryParameters: {
          'q': q,
          'query[term][is_public_domain]': true,
          'limit': pageSize,
          'page': page,
          'fields': 'id,title,image_id,thumbnail,artist_display',
        },
        options: Options(
          headers: OnlineAssetConfig.headersForHost(Uri.parse(articBase).host),
        ),
      );
      if (res.statusCode != 200 || res.data == null) {
        return OnlineAssetListFailure('Could not load Art Institute artworks.');
      }
      final data = res.data!['data'];
      if (data is! List) {
        return OnlineAssetListFailure('Unexpected Art Institute response.');
      }
      final items = <OnlineAssetItem>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final imageId = map['image_id']?.toString();
        if (imageId == null || imageId.isEmpty) continue;
        final id = map['id']?.toString() ?? imageId;
        final title = (map['title']?.toString() ?? 'Artwork').trim();
        final thumb = '$articIiif/$imageId/full/400,/0/default.jpg';
        final full = '$articIiif/$imageId/full/843,/0/default.jpg';
        items.add(
          OnlineAssetItem(
            id: 'artic_$id',
            title: title.isEmpty ? 'Artwork' : title,
            provider: OnlineAssetProvider.artic,
            applyKind: OnlineAssetApplyKind.image,
            imageUrl: full,
            thumbUrl: thumb,
            width: 843,
            height: 843,
            attribution: 'Art Institute of Chicago',
          ),
        );
      }
      final pagination = res.data!['pagination'];
      final totalPages = pagination is Map
          ? (pagination['total_pages'] as num?)?.toInt() ?? page
          : page;
      return OnlineAssetListSuccess(
        items,
        hasMore: page < totalPages,
        nextPage: page + 1,
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Artic: $e');
      return OnlineAssetListFailure('Could not load Art Institute artworks.');
    }
  }

  // ── Met Museum ───────────────────────────────────────────────────────────

  Future<OnlineAssetListResult> _listMet({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final q = query.trim().isEmpty ? 'painting' : query.trim();
      final search = await _dio.get<Map<String, dynamic>>(
        '$metBase/search',
        queryParameters: {'q': q, 'hasImages': true},
      );
      if (search.statusCode != 200 || search.data == null) {
        return OnlineAssetListFailure('Could not search The Met collection.');
      }
      final ids = search.data!['objectIDs'];
      if (ids is! List || ids.isEmpty) {
        return OnlineAssetListSuccess(const []);
      }
      final objectIds = ids.map((e) => e.toString()).toList();
      final start = ((page - 1) * pageSize).clamp(0, objectIds.length);
      final end = (start + pageSize).clamp(0, objectIds.length);
      final slice = objectIds.sublist(start, end);

      final items = <OnlineAssetItem>[];
      // Met asks for reasonable concurrency; keep batches small.
      for (var i = 0; i < slice.length; i += 4) {
        final chunk = slice.sublist(i, (i + 4).clamp(0, slice.length));
        final futures = chunk.map(_fetchMetObject);
        final results = await Future.wait(futures);
        items.addAll(results.whereType<OnlineAssetItem>());
      }

      return OnlineAssetListSuccess(
        items,
        hasMore: end < objectIds.length,
        nextPage: page + 1,
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Met: $e');
      return OnlineAssetListFailure('Could not load The Met collection.');
    }
  }

  Future<OnlineAssetItem?> _fetchMetObject(String objectId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$metBase/objects/$objectId',
      );
      if (res.statusCode != 200 || res.data == null) return null;
      final d = res.data!;
      final image = (d['primaryImageSmall'] ?? d['primaryImage'])?.toString();
      if (image == null || image.isEmpty) return null;
      final title = (d['title']?.toString() ?? 'Met object').trim();
      return OnlineAssetItem(
        id: 'met_$objectId',
        title: title.isEmpty ? 'Met object' : title,
        provider: OnlineAssetProvider.metMuseum,
        applyKind: OnlineAssetApplyKind.image,
        imageUrl: (d['primaryImage']?.toString().isNotEmpty == true)
            ? d['primaryImage'].toString()
            : image,
        thumbUrl: image,
        attribution: 'The Metropolitan Museum of Art',
      );
    } catch (_) {
      return null;
    }
  }

  // ── Colormind ────────────────────────────────────────────────────────────

  Future<OnlineAssetListResult> _listColormind({required int count}) async {
    try {
      final items = <OnlineAssetItem>[];
      for (var i = 0; i < count; i++) {
        final res = await _dio.post<Map<String, dynamic>>(
          colormindUrl,
          data: jsonEncode({'model': 'default'}),
          options: Options(
            contentType: 'application/json',
            responseType: ResponseType.json,
          ),
        );
        if (res.statusCode != 200 || res.data == null) continue;
        final result = res.data!['result'];
        if (result is! List || result.length < 5) continue;
        final colors = <Color>[];
        final hexes = <String>[];
        for (final row in result) {
          if (row is! List || row.length < 3) continue;
          final r = (row[0] as num).toInt().clamp(0, 255);
          final g = (row[1] as num).toInt().clamp(0, 255);
          final b = (row[2] as num).toInt().clamp(0, 255);
          colors.add(Color.fromARGB(255, r, g, b));
          hexes.add(
            '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}',
          );
        }
        if (hexes.length < 5) continue;
        final paletteUrl = colourLoversPaletteImageUrl(hexes);
        items.add(
          OnlineAssetItem(
            id: 'colormind_${hexes.join('_')}_$i',
            title: 'Palette ${i + 1}',
            provider: OnlineAssetProvider.colormind,
            applyKind: OnlineAssetApplyKind.paletteImage,
            imageUrl: paletteUrl,
            thumbUrl: paletteUrl,
            colors: colors,
            width: 600,
            height: 120,
            attribution: 'Colormind',
          ),
        );
      }
      if (items.isEmpty) {
        return OnlineAssetListFailure('Could not load Colormind palettes.');
      }
      return OnlineAssetListSuccess(items);
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Colormind: $e');
      return OnlineAssetListFailure('Could not load Colormind palettes.');
    }
  }

  // ── COLOURlovers ─────────────────────────────────────────────────────────

  Future<OnlineAssetListResult> _listColourLovers({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    final offset = (page - 1) * pageSize;
    try {
      final params = <String, dynamic>{
        'format': 'json',
        'numResults': pageSize,
        'resultOffset': offset,
      };
      if (query.trim().isNotEmpty) {
        params['keywords'] = query.trim();
      }
      final res = await _dio.get<dynamic>(
        '$colourLoversBase/palettes/top',
        queryParameters: params,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'User-Agent':
                'Mozilla/5.0 (compatible; Musamimuk/1.0; +https://musamimuk.com)',
          },
        ),
      );
      if (res.statusCode == 200 && res.data is List) {
        final items = <OnlineAssetItem>[];
        for (final raw in res.data as List) {
          if (raw is! Map) continue;
          final map = Map<String, dynamic>.from(raw);
          final id = map['id']?.toString() ?? '';
          final title = (map['title']?.toString() ?? 'Palette').trim();
          final imageUrl = map['imageUrl']?.toString();
          final colorsRaw = map['colors'];
          final hexes = <String>[];
          if (colorsRaw is List) {
            for (final c in colorsRaw) {
              final h = c.toString().replaceAll('#', '');
              if (h.length == 6) hexes.add(h);
            }
          }
          final url = (imageUrl != null && imageUrl.isNotEmpty)
              ? imageUrl.replaceFirst('http://', 'https://')
              : (hexes.length >= 2 ? colourLoversPaletteImageUrl(hexes) : null);
          if (url == null) continue;
          items.add(
            OnlineAssetItem(
              id: 'cl_$id',
              title: title.isEmpty ? 'Palette' : title,
              provider: OnlineAssetProvider.colourLovers,
              applyKind: OnlineAssetApplyKind.paletteImage,
              imageUrl: url,
              thumbUrl: url,
              colors: hexes
                  .map((h) => Color(int.parse('FF$h', radix: 16)))
                  .toList(),
              attribution: 'COLOURlovers.com',
            ),
          );
        }
        if (items.isNotEmpty) {
          return OnlineAssetListSuccess(
            items,
            hasMore: items.length >= pageSize,
            nextPage: page + 1,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ColourLovers API: $e');
    }

    // Cloudflare often blocks automated clients — fall back to Colormind
    // palettes rendered with COLOURlovers paletteImg URLs (documented image CDN).
    final fallback = await _listColormind(count: pageSize.clamp(4, 10));
    if (fallback is OnlineAssetListSuccess) {
      return OnlineAssetListSuccess(
        fallback.items
            .map(
              (e) => OnlineAssetItem(
                id: e.id.replaceFirst('colormind_', 'cl_fallback_'),
                title: e.title,
                provider: OnlineAssetProvider.colourLovers,
                applyKind: OnlineAssetApplyKind.paletteImage,
                imageUrl: e.imageUrl,
                thumbUrl: e.thumbUrl,
                colors: e.colors,
                width: e.width,
                height: e.height,
                attribution: 'COLOURlovers palette style · Colormind colors',
              ),
            )
            .toList(),
      );
    }
    return OnlineAssetListFailure(
      'COLOURlovers is temporarily unavailable. Try again later.',
    );
  }

  /// Documented COLOURlovers palette PNG CDN pattern.
  static String colourLoversPaletteImageUrl(List<String> hexes) {
    final padded = List<String>.from(hexes.map((h) => h.toUpperCase()));
    while (padded.length < 5) {
      padded.add('FFFFFF');
    }
    final seed = padded.take(5).join('/');
    return 'https://www.colourlovers.com/paletteImg/${padded.first}/$seed.png';
  }

  // ── DummyImage ───────────────────────────────────────────────────────────

  OnlineAssetListResult _listDummyImage({required String query}) {
    final presets = <({int w, int h, String bg, String fg, String label})>[
      (w: 600, h: 400, bg: '000000', fg: 'ffffff', label: '600×400 dark'),
      (w: 1080, h: 1080, bg: 'cccccc', fg: '333333', label: 'Square gray'),
      (w: 1920, h: 1080, bg: '0a7cff', fg: 'ffffff', label: 'HD blue'),
      (w: 800, h: 600, bg: 'ff6b6b', fg: 'ffffff', label: 'Coral'),
      (w: 640, h: 360, bg: '2d3436', fg: 'dfe6e9', label: '16:9 slate'),
      (w: 512, h: 512, bg: '6c5ce7', fg: 'ffffff', label: 'Purple'),
      (w: 300, h: 250, bg: '00b894', fg: 'ffffff', label: 'Med rect'),
      (w: 1200, h: 630, bg: 'fdcb6e', fg: '2d3436', label: 'Social'),
    ];

    final custom = query.trim();
    final items = <OnlineAssetItem>[];
    if (custom.isNotEmpty) {
      // Accept "600x400" or "600x400/ff0000/ffffff"
      final parts = custom.replaceAll(' ', '').split('/');
      final size = parts.first.toLowerCase();
      final sizeMatch = RegExp(r'^(\d+)x(\d+)$').firstMatch(size);
      if (sizeMatch != null) {
        final w = int.parse(sizeMatch.group(1)!);
        final h = int.parse(sizeMatch.group(2)!);
        final bg = parts.length > 1 ? parts[1].replaceAll('#', '') : 'cccccc';
        final fg = parts.length > 2 ? parts[2].replaceAll('#', '') : '000000';
        final url = '$dummyImageBase/${w}x$h/$bg/$fg.png&text=$w×$h';
        items.add(
          OnlineAssetItem(
            id: 'dummy_custom_${w}x$h',
            title: '$w×$h',
            provider: OnlineAssetProvider.dummyImage,
            applyKind: OnlineAssetApplyKind.image,
            imageUrl: url,
            thumbUrl: url,
            width: w,
            height: h,
            attribution: 'DummyImage.com',
          ),
        );
      }
    }

    for (final p in presets) {
      final fg = p.fg.trim();
      final url =
          '$dummyImageBase/${p.w}x${p.h}/${p.bg}/$fg.png&text=${Uri.encodeComponent(p.label)}';
      items.add(
        OnlineAssetItem(
          id: 'dummy_${p.w}x${p.h}_${p.bg}',
          title: p.label,
          provider: OnlineAssetProvider.dummyImage,
          applyKind: OnlineAssetApplyKind.image,
          imageUrl: url,
          thumbUrl: url,
          width: p.w,
          height: p.h,
          attribution: 'DummyImage.com',
        ),
      );
    }
    return OnlineAssetListSuccess(items);
  }

  // ── EmojiHub ─────────────────────────────────────────────────────────────

  Future<OnlineAssetListResult> _listEmojiHub({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final q = query.trim();
      final Response<dynamic> res;
      if (q.isNotEmpty) {
        res = await _dio.get<dynamic>(
          '$emojiHubBase/search',
          queryParameters: {'q': q},
        );
      } else {
        // Prefer a friendly default category for browsing.
        res = await _dio.get<dynamic>(
          '$emojiHubBase/all/category/smileys-and-people',
        );
      }
      if (res.statusCode != 200 || res.data == null) {
        return OnlineAssetListFailure('Could not load emojis.');
      }
      final list = res.data is List ? res.data as List : [res.data];
      final start = ((page - 1) * pageSize).clamp(0, list.length);
      final end = (start + pageSize).clamp(0, list.length);
      final slice = list.sublist(start, end);
      final items = <OnlineAssetItem>[];
      for (final raw in slice) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final name = (map['name']?.toString() ?? 'emoji').trim();
        final emoji = _emojiFromHub(map);
        if (emoji == null || emoji.isEmpty) continue;
        items.add(
          OnlineAssetItem(
            id: 'emoji_${name}_$emoji',
            title: name,
            provider: OnlineAssetProvider.emojiHub,
            applyKind: OnlineAssetApplyKind.emojiText,
            emoji: emoji,
            attribution: 'EmojiHub',
          ),
        );
      }
      return OnlineAssetListSuccess(
        items,
        hasMore: end < list.length,
        nextPage: page + 1,
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('EmojiHub: $e');
      return OnlineAssetListFailure('Could not load emojis.');
    }
  }

  String? _emojiFromHub(Map<String, dynamic> map) {
    final unicode = map['unicode'];
    if (unicode is List && unicode.isNotEmpty) {
      final buf = StringBuffer();
      for (final u in unicode) {
        final s = u.toString().toUpperCase().replaceAll('U+', '');
        final code = int.tryParse(s, radix: 16);
        if (code != null) buf.writeCharCode(code);
      }
      final out = buf.toString();
      if (out.isNotEmpty) return out;
    }
    final html = map['htmlCode'];
    if (html is List && html.isNotEmpty) {
      final raw = html.first.toString();
      final m = RegExp(r'&#(\d+);').firstMatch(raw);
      if (m != null) {
        final code = int.tryParse(m.group(1)!);
        if (code != null) return String.fromCharCode(code);
      }
    }
    return null;
  }

  // ── Icon Horse ───────────────────────────────────────────────────────────

  OnlineAssetListResult _listIconHorse({required String query}) {
    final domains = <String>[];
    final typed = query.trim().toLowerCase().replaceFirst(
      RegExp(r'^https?://'),
      '',
    );
    final host = typed.split('/').first.replaceFirst(RegExp(r'^www\.'), '');
    if (host.contains('.') && !host.contains(' ')) {
      domains.add(host);
    }
    domains.addAll(iconHorsePopularDomains);
    final seen = <String>{};
    final items = <OnlineAssetItem>[];
    for (final d in domains) {
      if (!seen.add(d)) continue;
      final url = '$iconHorseBase/$d';
      items.add(
        OnlineAssetItem(
          id: 'iconhorse_$d',
          title: d,
          provider: OnlineAssetProvider.iconHorse,
          applyKind: OnlineAssetApplyKind.image,
          imageUrl: url,
          thumbUrl: url,
          width: 256,
          height: 256,
          attribution: 'Icon Horse',
        ),
      );
    }
    return OnlineAssetListSuccess(items);
  }

  // ── Icons8 ───────────────────────────────────────────────────────────────

  OnlineAssetListResult _listIcons8({required String query}) {
    final names = <String>[];
    final q = query.trim().toLowerCase().replaceAll(' ', '-');
    if (q.isNotEmpty) names.add(q);
    names.addAll(icons8Popular);
    final seen = <String>{};
    final items = <OnlineAssetItem>[];
    for (final name in names) {
      final key = name.replaceAll('_', '-');
      if (!seen.add(key)) continue;
      final url = '$icons8Base/color/96/$key.png';
      items.add(
        OnlineAssetItem(
          id: 'icons8_$key',
          title: key.replaceAll('-', ' '),
          provider: OnlineAssetProvider.icons8,
          applyKind: OnlineAssetApplyKind.image,
          imageUrl: url,
          thumbUrl: url,
          width: 96,
          height: 96,
          attribution: 'Icons8',
        ),
      );
    }
    return OnlineAssetListSuccess(items);
  }

  // ── Musamimuk curated Lottie library ────────────────────────────────────

  Future<OnlineAssetListResult> _listLottieLibrary({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _api.dio.get(
        'assets',
        queryParameters: {
          'type': 'lottie',
          'status': 'published',
          'is_active': true,
          if (query.trim().isNotEmpty) 'search': query.trim(),
          'sort': 'sort_order',
          'page': page,
          'per_page': pageSize.clamp(1, 100),
        },
      );
      final body = response.data;
      if (body is! Map || body['success'] != true) {
        return OnlineAssetListFailure(
          body is Map
              ? apiParseString(
                  body['message'],
                  fallback: 'Could not load Lottie animations.',
                )
              : 'Unexpected Lottie library response.',
        );
      }

      final list = body['data'];
      if (list is! List) {
        return OnlineAssetListFailure('Unexpected Lottie library response.');
      }

      final items = <OnlineAssetItem>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final fileUrl = apiParseString(map['file_url']);
        if (fileUrl.isEmpty) continue;

        final metadata = map['metadata'];
        final author = metadata is Map
            ? apiParseString(metadata['author'])
            : '';
        final license = metadata is Map
            ? apiParseString(metadata['license'])
            : '';
        final attribution = [
          if (author.isNotEmpty) author,
          if (license.isNotEmpty) license,
        ].join(' · ');

        items.add(
          OnlineAssetItem(
            id: 'lottie_${apiParseString(map['id'], fallback: fileUrl)}',
            title: apiParseString(map['name'], fallback: 'Lottie animation'),
            provider: OnlineAssetProvider.lottieLibrary,
            applyKind: OnlineAssetApplyKind.lottie,
            lottieUrl: fileUrl,
            width: map['width'] == null ? null : apiParseInt(map['width']),
            height: map['height'] == null ? null : apiParseInt(map['height']),
            attribution: attribution.isEmpty
                ? 'Musamimuk Lottie Library'
                : attribution,
          ),
        );
      }

      final meta = body['meta'];
      final nextPage = meta is Map ? meta['next_page'] : null;
      return OnlineAssetListSuccess(
        items,
        hasMore: nextPage is int,
        nextPage: nextPage is int ? nextPage : null,
      );
    } on DioException catch (e) {
      return OnlineAssetListFailure(_dioMessage(e));
    } catch (e) {
      if (kDebugMode) debugPrint('Lottie library: $e');
      return OnlineAssetListFailure('Could not load Lottie animations.');
    }
  }

  // ── Lordicon ─────────────────────────────────────────────────────────────

  OnlineAssetListResult _listLordicon({required String query}) {
    final q = query.trim().toLowerCase();
    final items = <OnlineAssetItem>[];
    for (final entry in lordiconCatalog) {
      if (q.isNotEmpty &&
          !entry.name.toLowerCase().contains(q) &&
          !entry.id.contains(q)) {
        continue;
      }
      final url = '$lordiconCdn/${entry.id}.json';
      items.add(
        OnlineAssetItem(
          id: 'lordicon_${entry.id}',
          title: entry.name,
          provider: OnlineAssetProvider.lordicon,
          applyKind: OnlineAssetApplyKind.lottie,
          lottieUrl: url,
          attribution: 'Lordicon',
        ),
      );
    }
    // Allow pasting a raw Lordicon id.
    if (q.isNotEmpty && RegExp(r'^[a-z0-9]{6,12}$').hasMatch(q)) {
      if (!items.any((e) => e.id == 'lordicon_$q')) {
        items.insert(
          0,
          OnlineAssetItem(
            id: 'lordicon_$q',
            title: q,
            provider: OnlineAssetProvider.lordicon,
            applyKind: OnlineAssetApplyKind.lottie,
            lottieUrl: '$lordiconCdn/$q.json',
            attribution: 'Lordicon',
          ),
        );
      }
    }
    return OnlineAssetListSuccess(items);
  }

  // ── PHP Noise ────────────────────────────────────────────────────────────

  OnlineAssetListResult _listPhpNoise({required String query}) {
    final hexes = <String>[
      '4a90d9',
      'e17055',
      '00b894',
      '6c5ce7',
      '2d3436',
      'fdcb6e',
      'ff7675',
      '74b9ff',
      'a29bfe',
      '55efc4',
    ];
    final typed = query.trim().replaceAll('#', '').toLowerCase();
    if (RegExp(r'^[0-9a-f]{6}$').hasMatch(typed)) {
      hexes.insert(0, typed);
    }
    final items = <OnlineAssetItem>[];
    for (final hex in hexes.toSet()) {
      final url =
          '$phpNoiseBase?hex=$hex&tiles=${12 + _random.nextInt(20)}&tileSize=8';
      items.add(
        OnlineAssetItem(
          id: 'noise_$hex',
          title: '#${hex.toUpperCase()}',
          provider: OnlineAssetProvider.phpNoise,
          applyKind: OnlineAssetApplyKind.image,
          imageUrl: url,
          thumbUrl: url,
          width: 400,
          height: 400,
          attribution: 'PHP-Noise',
        ),
      );
    }
    return OnlineAssetListSuccess(items);
  }

  String _dioMessage(DioException e) {
    final code = e.response?.statusCode;
    if (code == 429) return 'Rate limit reached. Try again shortly.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Check your connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Network error. Check your connection.';
    }
    return e.message?.trim().isNotEmpty == true
        ? e.message!
        : 'Could not load assets.';
  }
}
