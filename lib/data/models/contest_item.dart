import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

class ContestItem {
  final int id;
  final String name;
  final int? categoryId;
  final String fileUrl;
  final String? startDate;
  final String? endDate;
  final MediaCategoryRef? category;
  /// From admin list: `upcoming` | `active` | `ended` | `completed` (optional).
  final String? status;
  final bool? isActive;
  final bool? isCompleted;

  const ContestItem({
    required this.id,
    required this.name,
    this.categoryId,
    required this.fileUrl,
    this.startDate,
    this.endDate,
    this.category,
    this.status,
    this.isActive,
    this.isCompleted,
  });

  factory ContestItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final fileUrlRaw = apiParseString(json['file_url']);
    final resolvedUrl = fileUrlRaw.isNotEmpty
        ? normalizePublicStorageUrl(fileUrlRaw)
        : apiResolveDesignFileUrl(json);
    return ContestItem(
      id: apiParseInt(json['id']),
      name: apiParseString(json['name']),
      categoryId: json['category_id'] == null ? null : apiParseInt(json['category_id']),
      fileUrl: resolvedUrl,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      category: cat is Map ? MediaCategoryRef.fromJson(cat.cast<String, dynamic>()) : null,
      status: () {
        final st = json['status']?.toString().trim();
        if (st == null || st.isEmpty) return null;
        return st;
      }(),
      isActive: apiParseBool(json['is_active']),
      isCompleted: apiParseBool(json['is_completed']),
    );
  }

  /// For [Navigator] arguments (from [GET /api/contest/list] items).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (categoryId != null) 'category_id': categoryId,
        'file_url': fileUrl,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (status != null) 'status': status,
        if (isActive != null) 'is_active': isActive,
        if (isCompleted != null) 'is_completed': isCompleted,
      };
}

