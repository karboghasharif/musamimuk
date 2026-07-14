import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';
import 'package:musamimuk/data/repositories/media_repository.dart';

/// Result of saving a design to the server.
sealed class SaveDesignResult {}

class SaveDesignSuccess extends SaveDesignResult {
  final String id;
  final String? imageUrl;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final String? title;
  SaveDesignSuccess({
    required this.id,
    this.imageUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.title,
  });
}

class SaveDesignFailure extends SaveDesignResult {
  final String message;
  SaveDesignFailure(this.message);
}

sealed class DesignListResult {}

class DesignListSuccess extends DesignListResult {
  final List<MediaItem> items;
  final String? message;
  DesignListSuccess({required this.items, this.message});
}

class DesignListFailure extends DesignListResult {
  final String message;
  DesignListFailure(this.message);
}

sealed class DesignActionResult {}

class DesignActionSuccess extends DesignActionResult {
  final String? message;
  final MediaItem? item;
  DesignActionSuccess({this.message, this.item});
}

class DesignActionFailure extends DesignActionResult {
  final String message;
  DesignActionFailure(this.message);
}

/// Handles design save via POST `design/add` (multipart), matching the live API.
class DesignRepository {
  DesignRepository() : _api = ApiClient();

  final ApiClient _api;

  /// Saves the design by uploading the rendered image and metadata.
  ///
  /// [imageBytes] – final image (e.g. from pro_image_editor).
  /// [title] – maps to API field `name`.
  /// [categoryId] – when omitted, the first category from `GET design/category` is used.
  /// [visibility] – `"public"` or `"private"` (default `"public"`).
  /// [filename] – multipart filename (e.g. `design.png`, `design.jpg`, `design.pdf`).
  ///
  /// Endpoint: POST `design/add` (multipart/form-data): `file`, `category_id`, `name`,
  /// `tags`, optional `sub_category_id`, `width`, `height`, `visibility`,
  /// `design_data` (Pro Image Editor state history JSON for redesign).
  Future<SaveDesignResult> saveDesign({
    required Uint8List imageBytes,
    int? width,
    int? height,
    String? title,
    int? categoryId,
    String? tags,
    int? subCategoryId,
    String visibility = 'public',
    String? filename,
    String? designData,
  }) async {
    try {
      final resolvedCategoryId = await _resolveCategoryId(categoryId);
      if (resolvedCategoryId == null) {
        return SaveDesignFailure(
          'No design category available. Create a design category or sign in.',
        );
      }

      final name = (title != null && title.trim().isNotEmpty)
          ? title.trim()
          : 'My design';
      final tagStr =
          (tags != null && tags.trim().isNotEmpty) ? tags.trim() : 'design';

      final formData = FormData();
      formData.fields.addAll([
        MapEntry('category_id', resolvedCategoryId.toString()),
        MapEntry('name', name),
        MapEntry('tags', tagStr),
        MapEntry('visibility', visibility),
      ]);
      if (subCategoryId != null) {
        formData.fields.add(
          MapEntry('sub_category_id', subCategoryId.toString()),
        );
      }
      if (width != null) {
        formData.fields.add(MapEntry('width', width.toString()));
      }
      if (height != null) {
        formData.fields.add(MapEntry('height', height.toString()));
      }
      final history = designData?.trim();
      if (history != null && history.isNotEmpty) {
        formData.fields.add(MapEntry('design_data', history));
      }
      final fileName = (filename != null && filename.trim().isNotEmpty)
          ? filename.trim()
          : 'design.jpg';
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            imageBytes,
            filename: fileName,
          ),
        ),
      );

      final response = await _api.dio.post<Map<String, dynamic>>(
        'design/add',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final data = response.data;
      if (data == null) {
        return SaveDesignFailure('Empty response');
      }

      final status = data['status']?.toString();
      if (status == 'error') {
        return SaveDesignFailure(
          apiExtractMessage(data) ?? 'Failed to save design',
        );
      }

      final dbData = apiExtractDbData(data);
      if (dbData is! Map) {
        return SaveDesignFailure(
          apiExtractMessage(data) ?? 'Failed to save design',
        );
      }

      final item = MediaItem.fromJson(dbData.cast<String, dynamic>());
      return SaveDesignSuccess(
        id: item.id.toString(),
        imageUrl: item.fileUrl.isNotEmpty ? item.fileUrl : null,
        thumbnailUrl: item.fileUrl.isNotEmpty ? item.fileUrl : null,
        width: width,
        height: height,
        title: item.name.isNotEmpty ? item.name : name,
      );
    } on DioException catch (e) {
      return SaveDesignFailure(apiMessageFromDioException(e));
    } catch (e) {
      return SaveDesignFailure(e.toString());
    }
  }

  /// GET `design/list?per_page=..` (legacy v1).
  Future<DesignListResult> list({int perPage = 20}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'design/list',
        queryParameters: <String, dynamic>{
          'per_page': perPage.clamp(1, 100).toString(),
        },
      );
      final data = response.data;
      if (data == null) return DesignListFailure('Empty response');
      final list = apiExtractDataList(data).map(MediaItem.fromJson).toList();
      return DesignListSuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return DesignListFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignListFailure('Something went wrong');
    }
  }

  /// POST `design/update/{id}` (multipart). File is optional.
  Future<DesignActionResult> update({
    required int id,
    required String name,
    required int categoryId,
    required String visibility, // public|private
    String? tags,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('name', name),
        MapEntry('category_id', categoryId.toString()),
        MapEntry('visibility', visibility),
        if (tags != null) MapEntry('tags', tags),
      ]);
      if (imageBytes != null && imageBytes.isNotEmpty) {
        form.files.add(
          MapEntry(
            'file',
            MultipartFile.fromBytes(
              imageBytes,
              filename: (filename != null && filename.trim().isNotEmpty)
                  ? filename.trim()
                  : 'design.jpg',
            ),
          ),
        );
      }
      final response = await _api.dio.post<Map<String, dynamic>>(
        'design/update/$id',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return DesignActionFailure('Empty response');
      final db = apiExtractDbData(data);
      final item =
          db is Map ? MediaItem.fromJson(db.cast<String, dynamic>()) : null;
      return DesignActionSuccess(message: apiExtractMessage(data), item: item);
    } on DioException catch (e) {
      return DesignActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignActionFailure('Something went wrong');
    }
  }

  /// DELETE `design/delete/{id}`.
  Future<DesignActionResult> delete(int id) async {
    try {
      final response =
          await _api.dio.delete<Map<String, dynamic>>('design/delete/$id');
      final data = response.data;
      return DesignActionSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return DesignActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignActionFailure('Something went wrong');
    }
  }

  /// POST `design/update-status/{id}` with `{ status }`.
  Future<DesignActionResult> updateStatus({
    required int id,
    required String status, // draft|published|reported|hidden
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'design/update-status/$id',
        data: <String, dynamic>{'status': status},
      );
      return DesignActionSuccess(message: apiExtractMessage(response.data));
    } on DioException catch (e) {
      return DesignActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignActionFailure('Something went wrong');
    }
  }

  /// POST `design/track/{id}` with `{ action: view|download|like }`.
  Future<DesignActionResult> track({
    required int id,
    required String action,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'design/track/$id',
        data: <String, dynamic>{'action': action},
      );
      return DesignActionSuccess(message: apiExtractMessage(response.data));
    } on DioException catch (e) {
      return DesignActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignActionFailure('Something went wrong');
    }
  }

  Future<DesignListResult> mostUsed() => _simpleList('design/most-used');
  Future<DesignListResult> unused() => _simpleList('design/unused');
  Future<DesignListResult> popular() => _simpleList('design/popular');
  Future<DesignListResult> trending() => _simpleList('design/trending');

  Future<DesignListResult> _simpleList(String path) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) return DesignListFailure('Empty response');
      final list = apiExtractDataList(data).map(MediaItem.fromJson).toList();
      return DesignListSuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return DesignListFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignListFailure('Something went wrong');
    }
  }

  /// Returns [categoryId] if set; otherwise loads design categories and uses the first id.
  Future<int?> _resolveCategoryId(int? categoryId) async {
    if (categoryId != null) return categoryId;

    final result = await MediaRepository(type: MediaType.design).categoryList();
    if (result is MediaCategoriesSuccess && result.items.isNotEmpty) {
      return result.items.first.id;
    }
    return null;
  }
}
