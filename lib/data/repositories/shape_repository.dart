import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/data/models/shape_item.dart';

/// Fetches shape list from GET shape/list.
class ShapeRepository {
  ShapeRepository() : _api = ApiClient();

  final ApiClient _api;

  /// GET shape/list. Returns dbData list or empty on failure.
  Future<List<ShapeItem>> getShapeList() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('shape/list');
      final data = response.data;
      if (data == null) return [];
      final dbData = data['dbData'];
      if (dbData is! List) return [];
      return dbData
          .map((e) => ShapeItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
