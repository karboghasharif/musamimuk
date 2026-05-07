import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/category_item.dart';

sealed class CategoryResult {}

class CategorySuccess extends CategoryResult {
  final String? message;
  final CategoryItem? item;
  final List<CategoryItem>? items;
  CategorySuccess({this.message, this.item, this.items});
}

class CategoryFailure extends CategoryResult {
  final String message;
  CategoryFailure(this.message);
}

class CategoryRepository {
  CategoryRepository() : _api = ApiClient();

  final ApiClient _api;

  Future<CategoryResult> list() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('category/list');
      final data = response.data;
      if (data == null) return CategoryFailure('Empty response');
      final list = apiExtractDbDataList(data).map(CategoryItem.fromJson).toList();
      return CategorySuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return CategoryFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return CategoryFailure('Something went wrong');
    }
  }

  Future<CategoryResult> children(int parentId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'category/children/$parentId',
      );
      final data = response.data;
      if (data == null) return CategoryFailure('Empty response');
      final list = apiExtractDbDataList(data).map(CategoryItem.fromJson).toList();
      return CategorySuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return CategoryFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return CategoryFailure('Something went wrong');
    }
  }

  Future<CategoryResult> add({
    required String type,
    required String name,
    int? parentId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'name': name,
        if (parentId != null) 'parent_id': parentId.toString(),
      });
      final response = await _api.dio.post<Map<String, dynamic>>(
        'category/add',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return CategoryFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map ? CategoryItem.fromJson(dbData.cast<String, dynamic>()) : null;
      return CategorySuccess(item: item, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return CategoryFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return CategoryFailure('Something went wrong');
    }
  }

  Future<CategoryResult> update({
    required int id,
    required String type,
    required String name,
    int? parentId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'name': name,
        if (parentId != null) 'parent_id': parentId.toString(),
      });
      final response = await _api.dio.post<Map<String, dynamic>>(
        'category/update/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return CategoryFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map ? CategoryItem.fromJson(dbData.cast<String, dynamic>()) : null;
      return CategorySuccess(item: item, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return CategoryFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return CategoryFailure('Something went wrong');
    }
  }

  Future<CategoryResult> delete(int id) async {
    try {
      final response = await _api.dio.delete<Map<String, dynamic>>('category/delete/$id');
      final data = response.data;
      if (data == null) return CategoryFailure('Empty response');
      return CategorySuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return CategoryFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return CategoryFailure('Something went wrong');
    }
  }
}

