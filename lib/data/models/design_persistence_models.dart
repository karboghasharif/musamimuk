import 'dart:convert';
import 'dart:typed_data';

import 'editor_ai_api_models.dart';

class DesignSaveRequest {
  const DesignSaveRequest({
    required this.fileBytes,
    required this.categoryId,
    required this.name,
    required this.tags,
    required this.filename,
    this.subCategoryId,
    this.width,
    this.height,
    this.visibility = 'public',
    this.designData,
    this.assetIds = const [],
  });

  final Uint8List fileBytes;
  final int categoryId;
  final String name;
  final String tags;
  final String filename;
  final int? subCategoryId;
  final int? width;
  final int? height;
  final String visibility;
  final String? designData;
  final List<String> assetIds;
}

class DesignUpdateRequest {
  const DesignUpdateRequest({
    required this.id,
    this.fileBytes,
    this.filename,
    this.categoryId,
    this.name,
    this.tags,
    this.subCategoryId,
    this.width,
    this.height,
    this.visibility,
    this.designData,
    this.clearDesignData = false,
    this.assetIds,
  });

  final int id;
  final Uint8List? fileBytes;
  final String? filename;
  final int? categoryId;
  final String? name;
  final String? tags;
  final int? subCategoryId;
  final int? width;
  final int? height;
  final String? visibility;
  final String? designData;
  final bool clearDesignData;

  /// `null` omits `asset_ids[]`; a non-null list replaces attachments.
  final List<String>? assetIds;
}

class SavedDesign {
  const SavedDesign({
    required this.id,
    required this.name,
    required this.fileUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.visibility,
    this.hasDesignData = false,
    this.designDataVersion,
    this.createdAt,
    this.sourceDesignId,
  });

  final int id;
  final String name;
  final String fileUrl;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final String? visibility;
  final bool hasDesignData;
  final String? designDataVersion;
  final String? createdAt;
  final int? sourceDesignId;

  factory SavedDesign.fromJson(Map<String, dynamic> json) {
    return SavedDesign(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      thumbnailUrl: _nullableString(json['thumbnail_url']),
      width: _nullableInt(json['width']),
      height: _nullableInt(json['height']),
      visibility: _nullableString(json['visibility']),
      hasDesignData: _parseBool(json['has_design_data']),
      designDataVersion: _nullableString(json['design_data_version']),
      createdAt: _nullableString(json['created_at']),
      sourceDesignId: _nullableInt(json['source_design_id']),
    );
  }
}

class RedesignDesign {
  const RedesignDesign({
    required this.id,
    required this.name,
    required this.fileUrl,
    required this.visibility,
    required this.hasDesignData,
    required this.generatedAssets,
    this.width,
    this.height,
    this.designDataJson,
  });

  final int id;
  final String name;
  final String fileUrl;
  final String visibility;
  final bool hasDesignData;
  final int? width;
  final int? height;
  final String? designDataJson;
  final List<GeneratedAiAsset> generatedAssets;

  factory RedesignDesign.fromJson(Map<String, dynamic> json) {
    final rawDesignData = json['design_data'];
    final rawAssets = json['generated_assets'];
    return RedesignDesign(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? 'private',
      hasDesignData: _parseBool(json['has_design_data']),
      width: _nullableInt(json['width']),
      height: _nullableInt(json['height']),
      designDataJson: rawDesignData == null
          ? null
          : rawDesignData is String
          ? rawDesignData
          : jsonEncode(rawDesignData),
      generatedAssets: rawAssets is List
          ? rawAssets
                .whereType<Map>()
                .map(
                  (asset) => GeneratedAiAsset.fromJson(
                    Map<String, dynamic>.from(asset),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  return _parseInt(value);
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
