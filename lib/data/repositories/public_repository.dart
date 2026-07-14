import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/contest_item.dart';
import 'package:musamimuk/data/models/media_item.dart';

sealed class PublicResult<T> {}

class PublicSuccess<T> extends PublicResult<T> {
  final T data;
  final String? message;
  PublicSuccess({required this.data, this.message});
}

class PublicFailure<T> extends PublicResult<T> {
  final String message;
  PublicFailure(this.message);
}

class PublicRepository {
  PublicRepository() : _api = ApiClient();

  final ApiClient _api;

  Future<PublicResult<List<MediaItem>>> featuredDesigns() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'public/designs/featured',
      );
      final data = response.data;
      if (data == null) return PublicFailure('Empty response');
      return PublicSuccess(
        data: _parseDesignList(data),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return PublicFailure(apiMessageFromDioException(e));
    } catch (_) {
      return PublicFailure('Something went wrong');
    }
  }

  Future<PublicResult<List<MediaItem>>> trendingDesigns() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'public/designs/trending',
      );
      final data = response.data;
      if (data == null) return PublicFailure('Empty response');
      return PublicSuccess(
        data: _parseDesignList(data),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return PublicFailure(apiMessageFromDioException(e));
    } catch (_) {
      return PublicFailure('Something went wrong');
    }
  }

  /// GET `/public/contests/?per_page=..&page=..`
  Future<PublicResult<List<ContestItem>>> publicContests({
    int perPage = 15,
    int page = 1,
    int? categoryId,
    String? status,
    String? tags,
  }) async {
    try {
      final qp = <String, dynamic>{
        'per_page': perPage.clamp(1, 50).toString(),
        'page': page.clamp(1, 1000000).toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (tags != null && tags.trim().isNotEmpty) 'tags': tags.trim(),
      };
      final response = await _api.dio.get<Map<String, dynamic>>(
        'public/contests/',
        queryParameters: qp,
      );
      final data = response.data;
      if (data == null) return PublicFailure('Empty response');
      final db = apiExtractDbData(data);
      dynamic listRaw = db;
      if (db is Map && db.containsKey('data')) listRaw = db['data'];
      final list = (listRaw is List)
          ? listRaw
              .whereType<Map>()
              .map((e) => ContestItem.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <ContestItem>[];
      return PublicSuccess(data: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return PublicFailure(apiMessageFromDioException(e));
    } catch (_) {
      return PublicFailure('Something went wrong');
    }
  }
}

List<MediaItem> _parseDesignList(Map<String, dynamic> root) {
  final direct = apiExtractDataList(root);
  if (direct.isNotEmpty) {
    return direct.map(MediaItem.fromJson).toList();
  }
  final payload = apiExtractPayloadMap(root);
  if (payload != null) {
    for (final key in const ['designs', 'items', 'featured']) {
      final raw = payload[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => MediaItem.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    }
  }
  return const [];
}
