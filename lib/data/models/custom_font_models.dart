import 'package:flutter/material.dart';

import '../../core/network/api_utils.dart';

/// Active custom font from `GET /fonts` (admin-uploaded TTF/OTF/WOFF2).
class CustomFontItem {
  const CustomFontItem({
    required this.id,
    required this.uuid,
    required this.name,
    required this.family,
    required this.language,
    required this.weight,
    required this.style,
    required this.fileUrl,
    required this.fileFormat,
    this.fileSize = 0,
    this.checksumSha256 = '',
    this.previewText = '',
    this.previewImageUrl,
    this.isPremium = false,
    this.sortOrder = 0,
    this.updatedAt,
  });

  final int id;
  final String uuid;
  final String name;

  /// CSS/Flutter font-family id used with [TextStyle.fontFamily].
  final String family;

  /// `arabic` | `english` | `both`
  final String language;
  final int weight;

  /// `normal` | `italic`
  final String style;
  final String fileUrl;
  final String fileFormat;
  final int fileSize;
  final String checksumSha256;
  final String previewText;
  final String? previewImageUrl;
  final bool isPremium;
  final int sortOrder;
  final DateTime? updatedAt;

  bool get isArabicCapable =>
      language == 'arabic' || language == 'both' || language.isEmpty;

  bool get isEnglishCapable =>
      language == 'english' || language == 'both' || language.isEmpty;

  /// Flutter [FontLoader] supports TTF/OTF reliably; WOFF2 is skipped.
  bool get isFlutterLoadable {
    final fmt = fileFormat.trim().toLowerCase();
    return fmt == 'ttf' ||
        fmt == 'otf' ||
        fileUrl.toLowerCase().endsWith('.ttf') ||
        fileUrl.toLowerCase().endsWith('.otf');
  }

  FontWeight get fontWeight {
    final w = weight.clamp(100, 900);
    return FontWeight.values.firstWhere(
      (v) => v.value == w,
      orElse: () => FontWeight.w400,
    );
  }

  FontStyle get fontStyle =>
      style.toLowerCase() == 'italic' ? FontStyle.italic : FontStyle.normal;

  factory CustomFontItem.fromJson(Map<String, dynamic> json) {
    final fileUrl = apiResolveDesignFileUrl({
      'file_url': json['file_url'],
      'file_path': json['file_path'],
      'url': json['url'],
    });
    final previewImage = json['preview_image_url']?.toString().trim();
    return CustomFontItem(
      id: apiParseInt(json['id']),
      uuid: apiParseString(json['uuid']),
      name: apiParseString(json['name'], fallback: 'Font'),
      family: apiParseString(
        json['family'],
        fallback: apiParseString(json['name'], fallback: 'CustomFont'),
      ),
      language: apiParseString(json['language'], fallback: 'both').toLowerCase(),
      weight: apiParseInt(json['weight'], fallback: 400),
      style: apiParseString(json['style'], fallback: 'normal').toLowerCase(),
      fileUrl: fileUrl,
      fileFormat: apiParseString(
        json['file_format'],
        fallback: _guessFormat(fileUrl),
      ).toLowerCase(),
      fileSize: apiParseInt(json['file_size']),
      checksumSha256: apiParseString(json['checksum_sha256']),
      previewText: apiParseString(
        json['preview_text'],
        fallback: 'Aa أب',
      ),
      previewImageUrl:
          (previewImage != null && previewImage.isNotEmpty) ? previewImage : null,
      isPremium: apiParseBool(json['is_premium']) ?? false,
      sortOrder: apiParseInt(json['sort_order']),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  static String _guessFormat(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.otf')) return 'otf';
    if (lower.endsWith('.woff2')) return 'woff2';
    if (lower.endsWith('.woff')) return 'woff';
    return 'ttf';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'family': family,
        'language': language,
        'weight': weight,
        'style': style,
        'file_url': fileUrl,
        'file_format': fileFormat,
        'file_size': fileSize,
        'checksum_sha256': checksumSha256,
        'preview_text': previewText,
        'preview_image_url': previewImageUrl,
        'is_premium': isPremium,
        'sort_order': sortOrder,
        'updated_at': updatedAt?.toIso8601String(),
      };
}

/// Paginated list result from `GET /fonts`.
class CustomFontListPage {
  const CustomFontListPage({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 50,
  });

  final List<CustomFontItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  bool get hasMore => currentPage < lastPage;
}
