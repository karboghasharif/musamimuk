import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/asset_meta.dart';
import 'package:musamimuk/data/models/category_item.dart';
import 'package:musamimuk/data/models/media_item.dart';
import 'package:musamimuk/data/repositories/media_repository.dart';

sealed class AssetResult {}

class AssetSuccess extends AssetResult {
  AssetSuccess({
    this.message,
    this.items,
    this.item,
    this.meta,
    this.interaction,
  });

  final String? message;
  final List<MediaItem>? items;
  final MediaItem? item;
  final ApiPaginationMeta? meta;
  final AssetInteractionData? interaction;
}

class AssetFailure extends AssetResult {
  AssetFailure(this.message);
  final String message;
}

sealed class AssetMetaResult {}

class AssetMetaSuccess extends AssetMetaResult {
  AssetMetaSuccess({required this.meta, this.message});
  final AssetMeta meta;
  final String? message;
}

class AssetMetaFailure extends AssetMetaResult {
  AssetMetaFailure(this.message);
  final String message;
}

sealed class AssetCategoriesResult {}

class AssetCategoriesSuccess extends AssetCategoriesResult {
  AssetCategoriesSuccess({this.message, required this.items});
  final String? message;
  final List<CategoryItem> items;
}

class AssetCategoriesFailure extends AssetCategoriesResult {
  AssetCategoriesFailure(this.message);
  final String message;
}

class ApiPaginationMeta {
  const ApiPaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    this.nextPage,
    this.previousPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int? nextPage;
  final int? previousPage;

  factory ApiPaginationMeta.fromJson(Map<String, dynamic> json) {
    int? nullablePage(dynamic v) {
      if (v == null) return null;
      final n = apiParseInt(v, fallback: -1);
      return n < 0 ? null : n;
    }

    return ApiPaginationMeta(
      currentPage: apiParseInt(json['current_page'], fallback: 1),
      perPage: apiParseInt(json['per_page'], fallback: 20),
      total: apiParseInt(json['total']),
      nextPage: nullablePage(json['next_page']),
      previousPage: nullablePage(json['previous_page']),
    );
  }
}

class AssetInteractionData {
  const AssetInteractionData({
    required this.assetId,
    this.type,
    this.viewsCount,
    this.downloadsCount,
    this.likesCount,
    this.favoritesCount,
    this.fileUrl,
  });

  final int assetId;
  final String? type;
  final int? viewsCount;
  final int? downloadsCount;
  final int? likesCount;
  final int? favoritesCount;
  final String? fileUrl;

  factory AssetInteractionData.fromJson(Map<String, dynamic> json) {
    return AssetInteractionData(
      assetId: apiParseInt(json['asset_id']),
      type: json['type']?.toString(),
      viewsCount: json['views_count'] == null
          ? null
          : apiParseInt(json['views_count']),
      downloadsCount: json['downloads_count'] == null
          ? null
          : apiParseInt(json['downloads_count']),
      likesCount: json['likes_count'] == null
          ? null
          : apiParseInt(json['likes_count']),
      favoritesCount: json['favorites_count'] == null
          ? null
          : apiParseInt(json['favorites_count']),
      fileUrl: json['file_url']?.toString(),
    );
  }
}

/// Unified `/assets` API (auth required via [ApiClient] interceptor).
class AssetRepository {
  AssetRepository() : _api = ApiClient();

  final ApiClient _api;

  static String? typeParamFor(MediaType type) {
    return switch (type) {
      MediaType.shape => 'shape',
      MediaType.png => 'png',
      MediaType.logo => 'logo',
      MediaType.design => null,
    };
  }

  /// Normalizes any `/assets/meta` type slug for unified API calls.
  ///
  /// Previously only four types were allowed, which blocked every other type
  /// returned from the database (e.g. stickers, frames, icons).
  static String? unifiedAssetType(String raw) {
    var normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');

    const aliases = <String, String>{
      'shapes': 'shape',
      'png_images': 'png',
      'png-images': 'png',
      'pngimages': 'png',
      'logos': 'logo',
      'online_pic': 'online_pic',
      'onlinepic': 'online_pic',
      'online-pic': 'online_pic',
    };
    normalized = aliases[normalized] ?? normalized;

    if (RegExp(r'^[a-z0-9_-]+$').hasMatch(normalized)) {
      return normalized;
    }
    return null;
  }

  Future<AssetMetaResult> fetchMeta() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('assets/meta');
      final data = response.data;
      if (data == null) return AssetMetaFailure('Empty response');
      if (!apiResponseIsSuccess(data) && !data.containsKey('dbData')) {
        return AssetMetaFailure(
          apiExtractMessage(data) ?? 'Could not load asset types',
        );
      }
      final payload = apiExtractPayloadMap(data) ?? apiExtractDbData(data);
      if (payload is! Map) {
        return AssetMetaSuccess(
          meta: const AssetMeta(types: AssetMeta.fallbackTypes),
        );
      }
      final meta = AssetMeta.fromJson(payload.cast<String, dynamic>());
      final types = meta.types.isEmpty ? AssetMeta.fallbackTypes : meta.types;
      return AssetMetaSuccess(
        meta: AssetMeta(
          types: types,
          statuses: meta.statuses,
          sortOptions: meta.sortOptions,
        ),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AssetMetaFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AssetMetaFailure('Something went wrong');
    }
  }

  Future<AssetCategoriesResult> categories({required String type}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'assets/categories',
        queryParameters: {'type': type},
      );
      final data = response.data;
      if (data == null) return AssetCategoriesFailure('Empty response');
      if (!apiResponseIsSuccess(data) && !data.containsKey('dbData')) {
        return AssetCategoriesFailure(
          apiExtractMessage(data) ?? 'Could not load categories',
        );
      }
      final list = apiExtractDataList(data).map(CategoryItem.fromJson).toList();
      return AssetCategoriesSuccess(
        items: list,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AssetCategoriesFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AssetCategoriesFailure('Something went wrong');
    }
  }

  Future<AssetResult> listAssets({
    required String type,
    int? categoryId,
    String? search,
    String sort = 'latest',
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'assets',
        queryParameters: <String, dynamic>{
          'type': type,
          'sort': sort,
          'page': page.clamp(1, 1000000).toString(),
          'per_page': perPage.clamp(1, 100).toString(),
          if (categoryId != null) 'category_id': categoryId.toString(),
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final data = response.data;
      if (data == null) return AssetFailure('Empty response');
      if (!apiResponseIsSuccess(data) && !data.containsKey('dbData')) {
        return AssetFailure(apiExtractMessage(data) ?? 'Could not load assets');
      }
      final items = apiExtractDataList(data).map(MediaItem.fromJson).toList();
      ApiPaginationMeta? meta;
      final rawMeta = data['meta'];
      if (rawMeta is Map) {
        meta = ApiPaginationMeta.fromJson(rawMeta.cast<String, dynamic>());
      }
      return AssetSuccess(items: items, meta: meta, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AssetFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AssetFailure('Something went wrong');
    }
  }

  Future<AssetResult> getAsset(int id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('assets/$id');
      final data = response.data;
      if (data == null) return AssetFailure('Empty response');
      final payload = apiExtractPayloadMap(data) ?? apiExtractDbData(data);
      if (payload is! Map) return AssetFailure('Asset not found');
      return AssetSuccess(
        item: MediaItem.fromJson(payload.cast<String, dynamic>()),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AssetFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AssetFailure('Something went wrong');
    }
  }

  Future<AssetResult> interact(int id, {required String action}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'assets/$id/interact',
        data: {'action': action},
      );
      final data = response.data;
      if (data == null) return AssetFailure('Empty response');
      final payload = apiExtractPayloadMap(data);
      return AssetSuccess(
        interaction: payload == null
            ? null
            : AssetInteractionData.fromJson(payload),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AssetFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AssetFailure('Something went wrong');
    }
  }
}
