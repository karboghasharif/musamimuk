import 'package:musamimuk/core/network/api_utils.dart';

/// One shape from GET /api/shape/list (dbData item).
class ShapeItem {
  final int id;
  final String name;
  final String type;
  final int? categoryId;
  final String fileUrl;
  final ShapeCategory? category;

  ShapeItem({
    required this.id,
    required this.name,
    required this.type,
    this.categoryId,
    required this.fileUrl,
    this.category,
  });

  factory ShapeItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    return ShapeItem(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'shape',
      categoryId: json['category_id'] is int ? json['category_id'] as int : int.tryParse(json['category_id']?.toString() ?? ''),
      fileUrl: normalizePublicStorageUrl(
        json['file_url']?.toString() ?? '',
      ),
      category: cat != null ? ShapeCategory.fromJson(cat as Map<String, dynamic>) : null,
    );
  }
}

class ShapeCategory {
  final int id;
  final String name;

  ShapeCategory({required this.id, required this.name});

  factory ShapeCategory.fromJson(Map<String, dynamic> json) {
    return ShapeCategory(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}
