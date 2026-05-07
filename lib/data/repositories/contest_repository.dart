import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';
import 'package:musamimuk/data/models/category_item.dart';
import 'package:musamimuk/data/models/contest_item.dart';
import 'package:musamimuk/data/models/contest_winner_admin.dart';
import 'package:musamimuk/data/models/media_item.dart';
import 'package:musamimuk/data/repositories/admin_contest_repository.dart';

sealed class ContestResult {}

class ContestFailure extends ContestResult {
  ContestFailure(this.message);
  final String message;
}

/// [ContestRepository.categoryList]
class ContestCategoriesResult extends ContestResult {
  ContestCategoriesResult({required this.categories, this.message});
  final List<CategoryItem> categories;
  final String? message;
}

/// [ContestRepository.list]
class ContestListResult extends ContestResult {
  ContestListResult({
    required this.items,
    this.openContests,
    this.closedContests,
    this.message,
  });

  final List<ContestItem> items;
  final List<ContestItem>? openContests;
  final List<ContestItem>? closedContests;
  final String? message;

  ContestItem? findContestById(int id) {
    for (final c in items) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// [ContestRepository.getById], [ContestRepository.add]
class ContestDetailResult extends ContestResult {
  ContestDetailResult({this.item, this.message});
  final ContestItem? item;
  final String? message;
}

/// [ContestRepository.acceptedDesigns]
class ContestAcceptedDesignsResult extends ContestResult {
  ContestAcceptedDesignsResult({required this.designs, this.message});
  final List<MediaItem> designs;
  final String? message;
}

/// Message-only API responses (submission status, assign, delete).
class ContestMessageResult extends ContestResult {
  ContestMessageResult({this.message});
  final String? message;
}

class ContestRepository {
  ContestRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// Shared instance so list cache and DI are consistent across contest screens.
  static ContestRepository? _defaultInstance;
  static ContestRepository get instance =>
      _defaultInstance ??= ContestRepository();

  /// Tests may reset to supply a mock [ApiClient].
  static void resetInstanceForTest([ContestRepository? repo]) {
    _defaultInstance = repo;
  }

  final ApiClient _api;

  List<ContestItem>? _listCacheItems;
  List<ContestItem>? _listCacheOpen;
  List<ContestItem>? _listCacheClosed;
  DateTime? _listCachedAt;
  static const Duration _listCacheTtl = Duration(minutes: 2);

  void invalidateContestListCache() {
    _listCacheItems = null;
    _listCacheOpen = null;
    _listCacheClosed = null;
    _listCachedAt = null;
  }

  Future<ContestResult> categoryList() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'contest/category',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final list = apiExtractDbDataList(
        data,
      ).map(CategoryItem.fromJson).toList();
      return ContestCategoriesResult(
        categories: list,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> list({bool forceRefresh = false}) async {
    final admin = PrefUtils().isAdminRole();
    if (!admin &&
        !forceRefresh &&
        _listCachedAt != null &&
        _listCacheItems != null) {
      if (DateTime.now().difference(_listCachedAt!) < _listCacheTtl) {
        return ContestListResult(
          items: List<ContestItem>.from(_listCacheItems!),
          openContests: _listCacheOpen == null
              ? null
              : List<ContestItem>.from(_listCacheOpen!),
          closedContests: _listCacheClosed == null
              ? null
              : List<ContestItem>.from(_listCacheClosed!),
        );
      }
    }

    if (admin) {
      try {
        final ares = await AdminContestRepository(apiClient: _api).listContests(
          perPage: 50,
        );
        if (ares is AdminContestFailure) {
          return ContestFailure(ares.message);
        }
        final success = ares as AdminContestListSuccess;
        final items = success.items;
        bool closedBucket(ContestItem c) {
          final s = c.status?.toLowerCase();
          if (c.isCompleted == true) return true;
          if (s == 'ended' || s == 'completed') return true;
          return false;
        }

        final open = items.where((c) => !closedBucket(c)).toList();
        final closed = items.where(closedBucket).toList();
        return ContestListResult(
          items: items,
          openContests: open,
          closedContests: closed,
          message: success.message,
        );
      } on DioException catch (e) {
        return ContestFailure(
          apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
        );
      } catch (_) {
        return ContestFailure('Something went wrong');
      }
    }

    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'contest/list',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');

      if (data.containsKey('open_contests') ||
          data.containsKey('closed_contests')) {
        List<ContestItem> parseContestList(dynamic raw) {
          if (raw is! List) return const [];
          return raw
              .whereType<Map>()
              .map((e) => ContestItem.fromJson(e.cast<String, dynamic>()))
              .toList();
        }

        final open = parseContestList(data['open_contests']);
        final closed = parseContestList(data['closed_contests']);
        final merged = [...open, ...closed];
        _listCacheItems = merged;
        _listCacheOpen = open;
        _listCacheClosed = closed;
        _listCachedAt = DateTime.now();
        return ContestListResult(
          openContests: open,
          closedContests: closed,
          items: merged,
          message: apiExtractMessage(data),
        );
      }

      final list = apiExtractDbDataList(
        data,
      ).map(ContestItem.fromJson).toList();
      _listCacheItems = list;
      _listCacheOpen = null;
      _listCacheClosed = null;
      _listCachedAt = DateTime.now();
      return ContestListResult(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  /// Cold-open fallback when [list] does not contain [id] (e.g. truncated list).
  /// Prefer resolving contests via [list] and [ContestListResult.findContestById].
  Future<ContestResult> getById(int id) async {
    try {
      final path =
          PrefUtils().isAdminRole() ? 'admin/contests/$id' : 'contest/$id';
      final response = await _api.dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map
          ? ContestItem.fromJson(dbData.cast<String, dynamic>())
          : null;
      return ContestDetailResult(item: item, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> acceptedDesigns(int contestId) async {
    if (PrefUtils().isAdminRole()) {
      final ares =
          await AdminContestRepository(apiClient: _api).listWinners(contestId);
      if (ares is AdminContestFailure) {
        return ContestFailure(ares.message);
      }
      final winRes = ares as AdminWinnersListSuccess;
      final designs =
          ContestWinnerAdmin.toDesignsByPosition(winRes.winners);
      return ContestAcceptedDesignsResult(
        designs: designs,
        message: winRes.message,
      );
    }
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'contest/accepteddesigns/$contestId',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final list = apiExtractDbDataList(data).map(MediaItem.fromJson).toList();
      return ContestAcceptedDesignsResult(
        designs: list,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> add({
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
      final path =
          PrefUtils().isAdminRole() ? 'admin/contests' : 'contest/add';
      final response = await _api.dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final dbData = apiExtractDbData(data);
      final item = dbData is Map
          ? ContestItem.fromJson(dbData.cast<String, dynamic>())
          : null;
      return ContestDetailResult(item: item, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> submissionStatus({
    required int submissionId,
    required String status,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'contest/submissionstatus/$submissionId',
        data: {'status': status},
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      return ContestMessageResult(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> assignPosition({
    required int submissionId,
    required int position,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        'contest/assignposition/$submissionId',
        data: {'position': position},
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      return ContestMessageResult(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> delete(int id) async {
    try {
      final path = PrefUtils().isAdminRole()
          ? 'admin/contests/$id'
          : 'contest/delete/$id';
      final response = await _api.dio.delete<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      return ContestMessageResult(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return ContestFailure(
        apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }
}
