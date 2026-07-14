import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/category_item.dart';
import 'package:musamimuk/data/models/media_item.dart';
import 'package:musamimuk/data/repositories/asset_repository.dart';

enum MediaType { shape, png, logo, design }

extension on MediaType {
  String get pathSegment => switch (this) {
        MediaType.shape => 'shape',
        MediaType.png => 'png',
        MediaType.logo => 'logo',
        MediaType.design => 'design',
      };
}

sealed class MediaResult {}

class MediaSuccess extends MediaResult {
  final String? message;
  final MediaItem? item;
  final List<MediaItem>? items;
  MediaSuccess({this.message, this.item, this.items});
}

class MediaFailure extends MediaResult {
  final String message;
  MediaFailure(this.message);
}

sealed class MediaCategoriesResult {}

class MediaCategoriesSuccess extends MediaCategoriesResult {
  final String? message;
  final List<CategoryItem> items;
  MediaCategoriesSuccess({this.message, required this.items});
}

class MediaCategoriesFailure extends MediaCategoriesResult {
  final String message;
  MediaCategoriesFailure(this.message);
}

class MediaRepository {
  MediaRepository({required this.type}) : _api = ApiClient();

  final MediaType type;
  final ApiClient _api;

  Future<MediaResult> list() async {
    final assetType = AssetRepository.typeParamFor(type);
    if (assetType != null) {
      final result = await AssetRepository().listAssets(
        type: assetType,
        perPage: 100,
      );
      if (result is AssetFailure) return MediaFailure(result.message);
      final success = result as AssetSuccess;
      return MediaSuccess(items: success.items, message: success.message);
    }
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('${type.pathSegment}/list');
      final data = response.data;
      if (data == null) return MediaFailure('Empty response');
      final list = apiExtractDataList(data).map(MediaItem.fromJson).toList();
      return MediaSuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return MediaFailure(apiMessageFromDioException(e));
    } catch (_) {
      return MediaFailure('Something went wrong');
    }
  }

  Future<MediaResult> getById(int id) async {
    final assetType = AssetRepository.typeParamFor(type);
    if (assetType != null) {
      final result = await AssetRepository().getAsset(id);
      if (result is AssetFailure) return MediaFailure(result.message);
      final success = result as AssetSuccess;
      return MediaSuccess(item: success.item, message: success.message);
    }
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('${type.pathSegment}/$id');
      final data = response.data;
      if (data == null) return MediaFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map ? MediaItem.fromJson(dbData.cast<String, dynamic>()) : null;
      return MediaSuccess(item: item, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return MediaFailure(apiMessageFromDioException(e));
    } catch (_) {
      return MediaFailure('Something went wrong');
    }
  }

  Future<MediaCategoriesResult> categoryList() async {
    final assetType = AssetRepository.typeParamFor(type);
    if (assetType != null) {
      final result = await AssetRepository().categories(type: assetType);
      if (result is AssetCategoriesFailure) {
        return MediaCategoriesFailure(result.message);
      }
      final success = result as AssetCategoriesSuccess;
      return MediaCategoriesSuccess(items: success.items, message: success.message);
    }
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '${type.pathSegment}/category',
      );
      final data = response.data;
      if (data == null) return MediaCategoriesFailure('Empty response');
      final list = apiExtractDbDataList(data).map(CategoryItem.fromJson).toList();
      return MediaCategoriesSuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return MediaCategoriesFailure(
        apiMessageFromDioException(e),
      );
    } catch (_) {
      return MediaCategoriesFailure('Something went wrong');
    }
  }

  Future<MediaResult> add({
    required int categoryId,
    required String name,
    String? tags,
    String? filePath,
    int? subCategoryId,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('category_id', categoryId.toString()),
        MapEntry('name', name),
        if (tags != null) MapEntry('tags', tags),
        if (subCategoryId != null) MapEntry('sub_category_id', subCategoryId.toString()),
      ]);
      if (filePath != null && filePath.isNotEmpty) {
        formData.files.add(
          MapEntry('file', await MultipartFile.fromFile(filePath)),
        );
      }

      final response = await _api.dio.post<Map<String, dynamic>>(
        '${type.pathSegment}/add',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return MediaFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map ? MediaItem.fromJson(dbData.cast<String, dynamic>()) : null;
      return MediaSuccess(item: item, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return MediaFailure(apiMessageFromDioException(e));
    } catch (_) {
      return MediaFailure('Something went wrong');
    }
  }

  Future<MediaResult> update({
    required int id,
    required int categoryId,
    required String name,
    String? tags,
    String? filePath,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('category_id', categoryId.toString()),
        MapEntry('name', name),
        if (tags != null) MapEntry('tags', tags),
      ]);
      if (filePath != null && filePath.isNotEmpty) {
        formData.files.add(
          MapEntry('file', await MultipartFile.fromFile(filePath)),
        );
      }
      final response = await _api.dio.post<Map<String, dynamic>>(
        '${type.pathSegment}/update/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return MediaFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map ? MediaItem.fromJson(dbData.cast<String, dynamic>()) : null;
      return MediaSuccess(item: item, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return MediaFailure(apiMessageFromDioException(e));
    } catch (_) {
      return MediaFailure('Something went wrong');
    }
  }

  Future<MediaResult> delete(int id) async {
    try {
      final response = await _api.dio.delete<Map<String, dynamic>>(
        '${type.pathSegment}/delete/$id',
      );
      final data = response.data;
      if (data == null) return MediaFailure('Empty response');
      return MediaSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return MediaFailure(apiMessageFromDioException(e));
    } catch (_) {
      return MediaFailure('Something went wrong');
    }
  }
}

