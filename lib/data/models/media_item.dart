import 'dart:convert';

import 'package:musamimuk/core/network/api_utils.dart';

class MediaCategoryRef {
  final int id;
  final String name;

  const MediaCategoryRef({required this.id, required this.name});

  factory MediaCategoryRef.fromJson(Map<String, dynamic> json) {
    return MediaCategoryRef(
      id: apiParseInt(json['id']),
      name: apiParseString(json['name']),
    );
  }
}

class MediaItem {
  final int id;
  final String name;
  final int? categoryId;
  final String fileUrl;
  final String? tags;
  final MediaCategoryRef? category;
  final int? userId;
  final String? createdAt;
  /// From API: typically `"public"` or `"private"` (see design add/list).
  final String? visibility;

  final int? subCategoryId;
  final MediaCategoryRef? subCategory;
  final String? tier;
  final bool? isFeatured;
  final String? status;
  final bool? isAdminDesign;
  final bool? isActive;
  final int? width;
  final int? height;
  final String? designDataRaw;
  final int? viewsCount;
  final int? downloadsCount;
  final int? likesCount;
  final int? trendingScore;
  final String? updatedAt;
  final String? lastDownloadedAt;
  final int? favoritesCount;
  final bool? isDuplicateCandidate;
  final String? duplicateGroupKey;
  final String? creatorName;
  final String? creatorEmail;

  const MediaItem({
    required this.id,
    required this.name,
    this.categoryId,
    required this.fileUrl,
    this.tags,
    this.category,
    this.userId,
    this.createdAt,
    this.visibility,
    this.subCategoryId,
    this.subCategory,
    this.tier,
    this.isFeatured,
    this.status,
    this.isAdminDesign,
    this.isActive,
    this.width,
    this.height,
    this.designDataRaw,
    this.viewsCount,
    this.downloadsCount,
    this.likesCount,
    this.trendingScore,
    this.updatedAt,
    this.lastDownloadedAt,
    this.favoritesCount,
    this.isDuplicateCandidate,
    this.duplicateGroupKey,
    this.creatorName,
    this.creatorEmail,
  });

  /// True when this design is saved as private (`visibility == 'private'`).
  bool get isPrivateDesign =>
      visibility != null && visibility!.toLowerCase().trim() == 'private';

  /// Human-readable lines for design detail sheets (admin catalog + rich payloads).
  String formatAdminDesignDetails() {
    void add(String label, String? value, List<String> lines) {
      if (value == null) return;
      final t = value.trim();
      if (t.isEmpty) return;
      lines.add('$label: $t');
    }

    void addInt(String label, int? value, List<String> lines) {
      if (value == null) return;
      lines.add('$label: $value');
    }

    void addBool(String label, bool? value, List<String> lines) {
      if (value == null) return;
      lines.add('$label: ${value ? 'Yes' : 'No'}');
    }

    final lines = <String>[];
    addInt('ID', id, lines);
    add('Name', name, lines);
    addInt('Category ID', categoryId, lines);
    if (category != null) {
      add('Category', category!.name, lines);
    }
    addInt('Sub-category ID', subCategoryId, lines);
    if (subCategory != null) {
      add('Sub-category', subCategory!.name, lines);
    }
    add('Tags', tags, lines);
    if (width != null && height != null) {
      lines.add('Size: ${width}x$height');
    }
    add('Visibility', visibility, lines);
    addInt('Created by (user id)', userId, lines);
    if (creatorName != null || creatorEmail != null) {
      final parts = <String>[];
      if (creatorName != null && creatorName!.trim().isNotEmpty) {
        parts.add(creatorName!.trim());
      }
      if (creatorEmail != null && creatorEmail!.trim().isNotEmpty) {
        parts.add(creatorEmail!.trim());
      }
      if (parts.isNotEmpty) {
        lines.add('Creator: ${parts.join(' · ')}');
      }
    }
    addBool('Admin design', isAdminDesign, lines);
    addBool('Active', isActive, lines);
    add('Status', status, lines);
    addBool('Featured', isFeatured, lines);
    add('Tier', tier, lines);
    add('Created at', createdAt, lines);
    add('Updated at', updatedAt, lines);
    addInt('Views', viewsCount, lines);
    addInt('Downloads', downloadsCount, lines);
    addInt('Likes', likesCount, lines);
    addInt('Favorites', favoritesCount, lines);
    addInt('Trending score', trendingScore, lines);
    add('Last downloaded at', lastDownloadedAt, lines);
    addBool('Duplicate candidate', isDuplicateCandidate, lines);
    add('Duplicate group', duplicateGroupKey, lines);
    if (designDataRaw != null && designDataRaw!.trim().isNotEmpty) {
      final raw = designDataRaw!.trim();
      if (raw.length > 400) {
        lines.add('Design data: ${raw.substring(0, 400)}…');
      } else {
        lines.add('Design data: $raw');
      }
    }
    return lines.join('\n');
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final sub = json['sub_category'];
    final creator = json['creator'];
    String? creatorName;
    String? creatorEmail;
    if (creator is Map) {
      final m = creator.cast<String, dynamic>();
      final n = apiParseString(m['name']).trim();
      final em = apiParseString(m['email']).trim();
      creatorName = n.isEmpty ? null : n;
      creatorEmail = em.isEmpty ? null : em;
    }

    final userIdRaw = json['user_id'] ?? json['created_by'];

    return MediaItem(
      id: apiParseInt(json['id']),
      name: apiParseString(json['name']),
      categoryId: json['category_id'] == null ? null : apiParseInt(json['category_id']),
      fileUrl: apiResolveDesignFileUrl(json),
      tags: json['tags']?.toString(),
      category: cat is Map ? MediaCategoryRef.fromJson(cat.cast<String, dynamic>()) : null,
      userId: userIdRaw == null ? null : apiParseInt(userIdRaw),
      createdAt: json['created_at']?.toString(),
      visibility: _parseVisibility(json),
      subCategoryId:
          json['sub_category_id'] == null ? null : apiParseInt(json['sub_category_id']),
      subCategory: sub is Map ? MediaCategoryRef.fromJson(sub.cast<String, dynamic>()) : null,
      tier: _nullableString(json['tier']),
      isFeatured: apiParseBool(json['is_featured']),
      status: _nullableString(json['status']),
      isAdminDesign: apiParseBool(json['is_admin_design']),
      isActive: apiParseBool(json['is_active']),
      width: json['width'] == null ? null : apiParseInt(json['width']),
      height: json['height'] == null ? null : apiParseInt(json['height']),
      designDataRaw: _stringifyDesignData(json['design_data']),
      viewsCount: json['views_count'] == null ? null : apiParseInt(json['views_count']),
      downloadsCount:
          json['downloads_count'] == null ? null : apiParseInt(json['downloads_count']),
      likesCount: json['likes_count'] == null ? null : apiParseInt(json['likes_count']),
      trendingScore:
          json['trending_score'] == null ? null : apiParseInt(json['trending_score']),
      updatedAt: json['updated_at']?.toString(),
      lastDownloadedAt: json['last_downloaded_at']?.toString(),
      favoritesCount:
          json['favorites_count'] == null ? null : apiParseInt(json['favorites_count']),
      isDuplicateCandidate: apiParseBool(json['is_duplicate_candidate']),
      duplicateGroupKey: _nullableString(json['duplicate_group_key']),
      creatorName: creatorName,
      creatorEmail: creatorEmail,
    );
  }

  static String? _stringifyDesignData(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    try {
      return jsonEncode(v);
    } catch (_) {
      return v.toString();
    }
  }

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? _parseVisibility(Map<String, dynamic> json) {
    final raw = json['visibility'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim().toLowerCase();
    }
    final isPublic = json['is_public'];
    if (isPublic is bool) return isPublic ? 'public' : 'private';
    if (isPublic is num) return isPublic != 0 ? 'public' : 'private';
    return null;
  }
}
