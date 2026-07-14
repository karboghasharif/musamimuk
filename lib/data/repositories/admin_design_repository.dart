import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

sealed class AdminDesignListResult {}

class AdminDesignListSuccess extends AdminDesignListResult {
  AdminDesignListSuccess({
    required this.items,
    this.meta,
    this.message,
  });

  final List<MediaItem> items;
  final AdminDesignListMeta? meta;
  final String? message;
}

class AdminDesignListFailure extends AdminDesignListResult {
  AdminDesignListFailure(this.message);
  final String message;
}

class AdminDesignListMeta {
  const AdminDesignListMeta({
    required this.currentPage,
    this.nextPage,
    this.previousPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int? nextPage;
  final int? previousPage;
  final int perPage;
  final int total;

  static AdminDesignListMeta? fromResponse(Map<String, dynamic> root) {
    final raw = root['meta'] ?? root['pagination'];
    if (raw is! Map) return null;
    final m = raw.cast<String, dynamic>();
    return AdminDesignListMeta(
      currentPage: apiParseInt(m['current_page'], fallback: 1),
      nextPage: m['next_page'] == null ? null : apiParseInt(m['next_page']),
      previousPage: m['previous_page'] == null ? null : apiParseInt(m['previous_page']),
      perPage: apiParseInt(m['per_page'], fallback: 20),
      total: apiParseInt(m['total']),
    );
  }
}

/// Public design catalog: `GET /designs` (auth Bearer).
class AdminDesignRepository {
  AdminDesignRepository() : _api = ApiClient();

  final ApiClient _api;

  /// [sort] e.g. `latest` — matches backend query param.
  Future<AdminDesignListResult> list({
    int perPage = 20,
    String sort = 'latest',
    int page = 1,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'designs',
        queryParameters: <String, dynamic>{
          'per_page': perPage,
          'sort': sort,
          if (page > 1) 'page': page,
        },
      );
      final data = response.data;
      if (data == null) return AdminDesignListFailure('Empty response');
      final list = apiExtractDataList(data).map(MediaItem.fromJson).toList();
      final meta = AdminDesignListMeta.fromResponse(data.cast<String, dynamic>());
      return AdminDesignListSuccess(
        items: list,
        meta: meta,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdminDesignListFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminDesignListFailure('Something went wrong');
    }
  }
}
