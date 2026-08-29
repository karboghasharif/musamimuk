import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/design_persistence_models.dart';
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
  final SavedDesign? design;
  SaveDesignSuccess({
    required this.id,
    this.imageUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.title,
    this.design,
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

sealed class DesignRedesignResult {}

class DesignRedesignSuccess extends DesignRedesignResult {
  DesignRedesignSuccess(this.design);
  final RedesignDesign design;
}

class DesignRedesignFailure extends DesignRedesignResult {
  DesignRedesignFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

sealed class DesignCloneResult {}

class DesignCloneSuccess extends DesignCloneResult {
  DesignCloneSuccess(this.design);
  final SavedDesign design;
}

class DesignCloneFailure extends DesignCloneResult {
  DesignCloneFailure(this.message);
  final String message;
}

/// Handles design save via POST `design/add` (multipart), matching the live API.
class DesignRepository {
  DesignRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

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
    List<String> assetIds = const [],
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
      final tagStr = (tags != null && tags.trim().isNotEmpty)
          ? tags.trim()
          : 'design';

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
      for (final assetId
          in assetIds.map((id) => id.trim()).where((id) => id.isNotEmpty)) {
        formData.fields.add(MapEntry('asset_ids[]', assetId));
      }
      final fileName = (filename != null && filename.trim().isNotEmpty)
          ? filename.trim()
          : 'design.jpg';
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(imageBytes, filename: fileName),
        ),
      );

      final response = await _dio.post<Map<String, dynamic>>(
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

      final dbMap = dbData.cast<String, dynamic>();
      final item = MediaItem.fromJson(dbMap);
      final savedDesign = SavedDesign.fromJson({
        ...dbMap,
        'file_url': apiResolveDesignFileUrl(dbMap),
      });
      return SaveDesignSuccess(
        id: savedDesign.id.toString(),
        imageUrl: savedDesign.fileUrl.isNotEmpty ? savedDesign.fileUrl : null,
        thumbnailUrl: savedDesign.thumbnailUrl,
        width: savedDesign.width ?? width,
        height: savedDesign.height ?? height,
        title: item.name.isNotEmpty ? item.name : name,
        design: savedDesign,
      );
    } on DioException catch (e) {
      return SaveDesignFailure(apiMessageFromDioException(e));
    } catch (_) {
      return SaveDesignFailure('Something went wrong');
    }
  }

  /// GET `design/list?per_page=..` (legacy v1).
  Future<DesignListResult> list({int perPage = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
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
    String? name,
    int? categoryId,
    String? visibility,
    String? tags,
    int? subCategoryId,
    int? width,
    int? height,
    Uint8List? imageBytes,
    String? filename,
    String? designData,
    bool clearDesignData = false,
    List<String>? assetIds,
  }) async {
    try {
      final form = FormData();
      if (name != null) form.fields.add(MapEntry('name', name));
      if (categoryId != null) {
        form.fields.add(MapEntry('category_id', categoryId.toString()));
      }
      if (visibility != null) {
        form.fields.add(MapEntry('visibility', visibility));
      }
      if (tags != null) form.fields.add(MapEntry('tags', tags));
      if (subCategoryId != null) {
        form.fields.add(MapEntry('sub_category_id', subCategoryId.toString()));
      }
      if (width != null) {
        form.fields.add(MapEntry('width', width.toString()));
      }
      if (height != null) {
        form.fields.add(MapEntry('height', height.toString()));
      }
      if (clearDesignData) {
        form.fields.add(const MapEntry('design_data', 'null'));
      } else if (designData != null) {
        form.fields.add(MapEntry('design_data', designData));
      }
      if (assetIds != null) {
        for (final assetId
            in assetIds.map((id) => id.trim()).where((id) => id.isNotEmpty)) {
          form.fields.add(MapEntry('asset_ids[]', assetId));
        }
      }
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
      final response = await _dio.post<Map<String, dynamic>>(
        'design/update/$id',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return DesignActionFailure('Empty response');
      final db = apiExtractDbData(data);
      final item = db is Map
          ? MediaItem.fromJson(db.cast<String, dynamic>())
          : null;
      return DesignActionSuccess(message: apiExtractMessage(data), item: item);
    } on DioException catch (e) {
      return DesignActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignActionFailure('Something went wrong');
    }
  }

  Future<DesignRedesignResult> loadForRedesign(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'design/redesign/$id',
      );
      final payload = apiExtractPayloadMap(response.data);
      if (payload == null) {
        return DesignRedesignFailure(
          apiExtractMessage(response.data) ?? 'Design could not be loaded.',
        );
      }
      return DesignRedesignSuccess(
        RedesignDesign.fromJson({
          ...payload,
          'file_url': apiResolveDesignFileUrl(payload),
        }),
      );
    } on DioException catch (error) {
      return DesignRedesignFailure(
        apiMessageFromDioException(error),
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      return DesignRedesignFailure('Design could not be loaded.');
    }
  }

  Future<DesignCloneResult> clone(int id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'design/clone/$id',
      );
      final payload = apiExtractPayloadMap(response.data);
      if (payload == null) {
        return DesignCloneFailure(
          apiExtractMessage(response.data) ?? 'Design could not be cloned.',
        );
      }
      return DesignCloneSuccess(SavedDesign.fromJson(payload));
    } on DioException catch (error) {
      return DesignCloneFailure(apiMessageFromDioException(error));
    } catch (_) {
      return DesignCloneFailure('Design could not be cloned.');
    }
  }

  /// DELETE `design/delete/{id}`.
  Future<DesignActionResult> delete(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        'design/delete/$id',
      );
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
      final response = await _dio.post<Map<String, dynamic>>(
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
      final response = await _dio.post<Map<String, dynamic>>(
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
      final response = await _dio.get<Map<String, dynamic>>(path);
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
