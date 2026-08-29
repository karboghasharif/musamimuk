import 'package:musamimuk/core/network/api_utils.dart';

/// Public advertisement payload from `GET /public/advertisements`.
class Advertisement {
  const Advertisement({
    required this.id,
    required this.title,
    this.description,
    required this.placement,
    required this.mediaType,
    this.mediaUrl,
    this.videoUrl,
    this.linkUrl,
    this.advertiserName,
    this.sortOrder = 0,
    this.targetPlatform,
  });

  final int id;
  final String title;
  final String? description;
  final String placement;
  final String mediaType;
  final String? mediaUrl;
  final String? videoUrl;
  final String? linkUrl;
  final String? advertiserName;
  final int sortOrder;
  final String? targetPlatform;

  bool get isImage => mediaType.toLowerCase() == 'image';

  bool get hasDisplayableImage {
    final url = mediaUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  String? get displayImageUrl {
    final url = mediaUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return normalizePublicStorageUrl(url);
    }
    return null;
  }

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: apiParseInt(json['id']),
      title: apiParseString(json['title'], fallback: 'Ad'),
      description: _nullableString(json['description']),
      placement: apiParseString(json['placement']),
      mediaType: apiParseString(json['media_type'], fallback: 'image'),
      mediaUrl: _nullableString(json['media_url']),
      videoUrl: _nullableString(json['video_url']),
      linkUrl: _nullableString(json['link_url']),
      advertiserName: _nullableString(json['advertiser_name']),
      sortOrder: apiParseInt(json['sort_order']),
      targetPlatform: _nullableString(json['target_platform']),
    );
  }

  /// Parses `POST/GET` envelope:
  /// `response.data['data']['advertisements']` — never treat top-level `data` as a list.
  static List<Advertisement> parseListFromResponseBody(
    Map<String, dynamic> body,
  ) {
    final data = body['data'];
    if (data is! Map) return const [];
    final rows = data['advertisements'];
    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map((row) => Advertisement.fromJson(Map<String, dynamic>.from(row)))
        .where((ad) => ad.hasDisplayableImage)
        .toList(growable: false);
  }

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// Placement options from `GET /public/advertisements/placements`.
class AdvertisementPlacements {
  const AdvertisementPlacements({
    required this.placements,
    required this.platforms,
  });

  final List<String> placements;
  final List<String> platforms;

  factory AdvertisementPlacements.fromJson(Map<String, dynamic> json) {
    List<String> readList(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).toList(growable: false);
    }

    return AdvertisementPlacements(
      placements: readList(json['placements']),
      platforms: readList(json['platforms']),
    );
  }
}
