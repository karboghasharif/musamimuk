import 'package:musamimuk/core/network/api_utils.dart';

class CategoryItem {
  final int id;
  final String type;
  final String name;
  final int? parentId;

  const CategoryItem({
    required this.id,
    required this.type,
    required this.name,
    this.parentId,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: apiParseInt(json['id']),
      type: apiParseString(json['type'] ?? json['slug']),
      name: apiParseString(json['name']),
      parentId: json['parent_id'] == null ? null : apiParseInt(json['parent_id']),
    );
  }
}

