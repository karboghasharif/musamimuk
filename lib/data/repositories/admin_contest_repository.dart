import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/contest_item.dart';
import 'package:musamimuk/data/models/contest_submission_admin.dart';
import 'package:musamimuk/data/models/contest_winner_admin.dart';

sealed class AdminContestResult {}

class AdminContestFailure extends AdminContestResult {
  AdminContestFailure(this.message);
  final String message;
}

class AdminContestMessageSuccess extends AdminContestResult {
  AdminContestMessageSuccess({this.message});
  final String? message;
}

class AdminContestListMeta {
  const AdminContestListMeta({
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

  static AdminContestListMeta? fromResponse(Map<String, dynamic> root) {
    final raw = root['meta'];
    if (raw is! Map) return null;
    final m = raw.cast<String, dynamic>();
    return AdminContestListMeta(
      currentPage: apiParseInt(m['current_page'], fallback: 1),
      nextPage: m['next_page'] == null ? null : apiParseInt(m['next_page']),
      previousPage:
          m['previous_page'] == null ? null : apiParseInt(m['previous_page']),
      perPage: apiParseInt(m['per_page'], fallback: 20),
      total: apiParseInt(m['total']),
    );
  }
}

class AdminContestListSuccess extends AdminContestResult {
  AdminContestListSuccess({
    required this.items,
    this.meta,
    this.message,
  });

  final List<ContestItem> items;
  final AdminContestListMeta? meta;
  final String? message;
}

class AdminContestDetailSuccess extends AdminContestResult {
  AdminContestDetailSuccess({this.item, this.message});
  final ContestItem? item;
  final String? message;
}

class AdminSubmissionsListSuccess extends AdminContestResult {
  AdminSubmissionsListSuccess({
    required this.items,
    this.meta,
    this.message,
  });

  final List<ContestSubmissionAdmin> items;
  final AdminContestListMeta? meta;
  final String? message;
}

class AdminWinnersListSuccess extends AdminContestResult {
  AdminWinnersListSuccess({
    required this.winners,
    this.message,
  });

  final List<ContestWinnerAdmin> winners;
  final String? message;
}

/// Section **12. Admin — contests & winners & submissions** (Bearer + admin role).
class AdminContestRepository {
  AdminContestRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// `GET /admin/contests`
  Future<AdminContestResult> listContests({
    int perPage = 20,
    int page = 1,
    int? categoryId,
    String? tags,
    String? status,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'admin/contests',
        queryParameters: <String, dynamic>{
          'per_page': perPage,
          if (page > 1) 'page': page,
          if (categoryId != null) 'category_id': categoryId,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      final list =
          apiExtractDbDataList(data).map(ContestItem.fromJson).toList();
      final meta = AdminContestListMeta.fromResponse(data.cast<String, dynamic>());
      return AdminContestListSuccess(
        items: list,
        meta: meta,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `GET /admin/contests/{id}`
  Future<AdminContestResult> getContest(int id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'admin/contests/$id',
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map
          ? ContestItem.fromJson(dbData.cast<String, dynamic>())
          : null;
      return AdminContestDetailSuccess(
        item: item,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `POST /admin/contests` — same fields as legacy `contest/add`.
  Future<AdminContestResult> createContest({
    required int categoryId,
    required String name,
    required String startDate,
    required String endDate,
    String? filePath,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('category_id', categoryId.toString()),
        MapEntry('name', name),
        MapEntry('start_date', startDate),
        MapEntry('end_date', endDate),
      ]);
      if (filePath != null && filePath.isNotEmpty) {
        formData.files.add(
          MapEntry('file', await MultipartFile.fromFile(filePath)),
        );
      }
      final response = await _api.dio.post<Map<String, dynamic>>(
        'admin/contests',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map
          ? ContestItem.fromJson(dbData.cast<String, dynamic>())
          : null;
      return AdminContestDetailSuccess(
        item: item,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `PUT /admin/contests/{id}`
  Future<AdminContestResult> updateContest({
    required int id,
    required int categoryId,
    required String name,
    required String startDate,
    required String endDate,
    String? filePath,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('category_id', categoryId.toString()),
        MapEntry('name', name),
        MapEntry('start_date', startDate),
        MapEntry('end_date', endDate),
      ]);
      if (filePath != null && filePath.isNotEmpty) {
        formData.files.add(
          MapEntry('file', await MultipartFile.fromFile(filePath)),
        );
      }
      final response = await _api.dio.put<Map<String, dynamic>>(
        'admin/contests/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map
          ? ContestItem.fromJson(dbData.cast<String, dynamic>())
          : null;
      return AdminContestDetailSuccess(
        item: item,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `PATCH /admin/contests/{id}/status`
  Future<AdminContestResult> patchContestStatus(
    int id, {
    bool? isActive,
    bool? isCompleted,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isActive != null) body['is_active'] = isActive;
      if (isCompleted != null) body['is_completed'] = isCompleted;
      final response = await _api.dio.patch<Map<String, dynamic>>(
        'admin/contests/$id/status',
        data: body,
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `DELETE /admin/contests/{id}`
  Future<AdminContestResult> deleteContest(int id) async {
    try {
      final response = await _api.dio.delete<Map<String, dynamic>>(
        'admin/contests/$id',
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `GET /admin/contests/{id}/submissions`
  Future<AdminContestResult> listSubmissions(
    int contestId, {
    int perPage = 20,
    String sort = 'recent',
    int page = 1,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'admin/contests/$contestId/submissions',
        queryParameters: <String, dynamic>{
          'per_page': perPage,
          'sort': sort,
          if (page > 1) 'page': page,
        },
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      final list = apiExtractDbDataList(data)
          .map(ContestSubmissionAdmin.fromJson)
          .toList();
      final meta = AdminContestListMeta.fromResponse(data.cast<String, dynamic>());
      return AdminSubmissionsListSuccess(
        items: list,
        meta: meta,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  static List<ContestWinnerAdmin> _parseWinnersList(dynamic data) {
    if (data is! Map) return const [];
    final root = data.cast<String, dynamic>();
    dynamic raw = apiExtractDbData(root);
    if (raw is! List) {
      final w = root['winners'];
      if (w is List) raw = w;
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ContestWinnerAdmin.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// `GET /admin/contests/{id}/winners`
  Future<AdminContestResult> listWinners(int contestId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'admin/contests/$contestId/winners',
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      final winners = _parseWinnersList(data);
      return AdminWinnersListSuccess(
        winners: winners,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `POST /admin/contests/{id}/winners` — finalize winners.
  Future<AdminContestResult> finalizeWinners(
    int contestId,
    List<Map<String, dynamic>> winners,
  ) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'admin/contests/$contestId/winners',
        data: <String, dynamic>{'winners': winners},
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `PUT /admin/contests/{id}/winners` — replace winner set.
  Future<AdminContestResult> replaceWinners(
    int contestId,
    List<Map<String, dynamic>> winners,
  ) async {
    try {
      final response = await _api.dio.put<Map<String, dynamic>>(
        'admin/contests/$contestId/winners',
        data: <String, dynamic>{'winners': winners},
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `DELETE /admin/contests/{contestId}/winners/{winnerRowId}`
  Future<AdminContestResult> deleteWinner(int contestId, int winnerRowId) async {
    try {
      final response = await _api.dio.delete<Map<String, dynamic>>(
        'admin/contests/$contestId/winners/$winnerRowId',
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `PATCH /admin/submissions/{id}/approve`
  Future<AdminContestResult> approveSubmission(int submissionId) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        'admin/submissions/$submissionId/approve',
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `PATCH /admin/submissions/{id}/reject`
  Future<AdminContestResult> rejectSubmission(
    int submissionId, {
    String? adminNotes,
  }) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        'admin/submissions/$submissionId/reject',
        data: <String, dynamic>{
          if (adminNotes != null) 'admin_notes': adminNotes,
        },
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `PATCH /admin/submissions/{id}/feature`
  Future<AdminContestResult> featureSubmission(int submissionId) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        'admin/submissions/$submissionId/feature',
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }

  /// `PATCH /admin/submissions/{id}/disqualify`
  Future<AdminContestResult> disqualifySubmission(
    int submissionId, {
    String? adminNotes,
  }) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        'admin/submissions/$submissionId/disqualify',
        data: <String, dynamic>{
          if (adminNotes != null) 'admin_notes': adminNotes,
        },
      );
      final data = response.data;
      if (data == null) return AdminContestFailure('Empty response');
      return AdminContestMessageSuccess(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return AdminContestFailure(apiMessageFromDioException(e));
    } catch (_) {
      return AdminContestFailure('Something went wrong');
    }
  }
}
