import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

sealed class DesignInteractionResult {}

class DesignInteractionSuccess extends DesignInteractionResult {
  final String? message;
  final Map<String, dynamic>? data;
  DesignInteractionSuccess({this.message, this.data});
}

class DesignInteractionFailure extends DesignInteractionResult {
  final String message;
  DesignInteractionFailure(this.message);
}

sealed class FavoriteDesignsResult {}

class FavoriteDesignsSuccess extends FavoriteDesignsResult {
  final List<MediaItem> items;
  final String? message;
  FavoriteDesignsSuccess({required this.items, this.message});
}

class FavoriteDesignsFailure extends FavoriteDesignsResult {
  final String message;
  FavoriteDesignsFailure(this.message);
}

class DesignInteractionRepository {
  DesignInteractionRepository() : _api = ApiClient();

  final ApiClient _api;

  Future<DesignInteractionResult> recordView(int designId) =>
      _postSimple('designs/$designId/view');

  Future<DesignInteractionResult> recordDownload(int designId) =>
      _postSimple('designs/$designId/download');

  Future<DesignInteractionResult> addFavorite(int designId) =>
      _postSimple('designs/$designId/favorite');

  Future<DesignInteractionResult> removeFavorite(int designId) async {
    try {
      final response =
          await _api.dio.delete<Map<String, dynamic>>('designs/$designId/favorite');
      final data = response.data;
      return DesignInteractionSuccess(
        message: apiExtractMessage(data),
        data: apiExtractDbData(data) is Map
            ? (apiExtractDbData(data) as Map).cast<String, dynamic>()
            : null,
      );
    } on DioException catch (e) {
      return DesignInteractionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignInteractionFailure('Something went wrong');
    }
  }

  Future<FavoriteDesignsResult> favorites() async {
    try {
      final response =
          await _api.dio.get<Map<String, dynamic>>('designs/favorites');
      final data = response.data;
      if (data == null) return FavoriteDesignsFailure('Empty response');
      final list = apiExtractDbDataList(data).map(MediaItem.fromJson).toList();
      return FavoriteDesignsSuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return FavoriteDesignsFailure(apiMessageFromDioException(e));
    } catch (_) {
      return FavoriteDesignsFailure('Something went wrong');
    }
  }

  /// GET `/designs/search?search=..&limit=..`
  Future<FavoriteDesignsResult> search({
    required String search,
    int limit = 10,
  }) async {
    final s = search.trim();
    if (s.isEmpty) return FavoriteDesignsFailure('Missing search query');
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'designs/search',
        queryParameters: <String, dynamic>{
          'search': s,
          'limit': limit.clamp(1, 50).toString(),
        },
      );
      final data = response.data;
      if (data == null) return FavoriteDesignsFailure('Empty response');
      final list = apiExtractDbDataList(data).map(MediaItem.fromJson).toList();
      return FavoriteDesignsSuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return FavoriteDesignsFailure(apiMessageFromDioException(e));
    } catch (_) {
      return FavoriteDesignsFailure('Something went wrong');
    }
  }

  /// POST `/designs/{id}/remove-bg`.
  Future<DesignInteractionResult> removeBackground(int designId) =>
      _postSimple('designs/$designId/remove-bg');

  Future<DesignInteractionResult> _postSimple(String path) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(path);
      final data = response.data;
      return DesignInteractionSuccess(
        message: apiExtractMessage(data),
        data: apiExtractDbData(data) is Map
            ? (apiExtractDbData(data) as Map).cast<String, dynamic>()
            : null,
      );
    } on DioException catch (e) {
      return DesignInteractionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return DesignInteractionFailure('Something went wrong');
    }
  }
}

