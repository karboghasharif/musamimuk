import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/global_search_result.dart';

sealed class GlobalSearchApiResult {}

class GlobalSearchApiSuccess extends GlobalSearchApiResult {
  final GlobalSearchResult result;
  final String? message;
  GlobalSearchApiSuccess({required this.result, this.message});
}

class GlobalSearchApiFailure extends GlobalSearchApiResult {
  final String message;
  GlobalSearchApiFailure(this.message);
}

class GlobalSearchRepository {
  GlobalSearchRepository() : _api = ApiClient();

  final ApiClient _api;

  Future<GlobalSearchApiResult> search({
    required String query,
    int limit = 10,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return GlobalSearchApiFailure('Missing search query');
    final l = limit.clamp(1, 50);

    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'search',
        queryParameters: <String, dynamic>{
          'q': q,
          'limit': l.toString(),
        },
      );
      final data = response.data;
      if (data == null) return GlobalSearchApiFailure('Empty response');
      return GlobalSearchApiSuccess(
        result: GlobalSearchResult.fromEnvelope(data),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return GlobalSearchApiFailure(apiMessageFromDioException(e));
    } catch (_) {
      return GlobalSearchApiFailure('Something went wrong');
    }
  }
}

