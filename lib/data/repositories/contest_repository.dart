import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/contest_utils.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';
import 'package:musamimuk/data/models/category_item.dart';
import 'package:musamimuk/data/models/contest_design_entry.dart';
import 'package:musamimuk/data/models/contest_detail.dart';
import 'package:musamimuk/data/models/contest_item.dart';
import 'package:musamimuk/data/models/contest_submission.dart';
import 'package:musamimuk/data/models/contest_winner.dart';
import 'package:musamimuk/data/models/media_item.dart';

sealed class ContestResult {}

class ContestFailure extends ContestResult {
  ContestFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class ContestCategoriesResult extends ContestResult {
  ContestCategoriesResult({required this.categories, this.message});
  final List<CategoryItem> categories;
  final String? message;
}

class ContestListResult extends ContestResult {
  ContestListResult({
    required this.items,
    this.openContests,
    this.closedContests,
    this.message,
    this.page,
  });

  final List<ContestItem> items;
  final List<ContestItem>? openContests;
  final List<ContestItem>? closedContests;
  final String? message;
  final ContestPage<ContestItem>? page;

  ContestItem? findContestById(int id) {
    for (final c in items) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class ContestDetailResult extends ContestResult {
  ContestDetailResult({this.detail, this.item, this.message});
  final ContestDetail? detail;
  final ContestItem? item;
  final String? message;
}

class ContestAcceptedDesignsResult extends ContestResult {
  ContestAcceptedDesignsResult({
    required this.entries,
    this.stats,
    this.message,
  });

  final List<ContestDesignEntry> entries;
  final ContestSubmissionStats? stats;
  final String? message;

  List<MediaItem> get designs => entries.map((e) => e.design).toList();
}

class ContestSubmissionsResult extends ContestResult {
  ContestSubmissionsResult({
    required this.submissions,
    this.page,
    this.message,
  });
  final List<ContestSubmission> submissions;
  final ContestPage<ContestSubmission>? page;
  final String? message;
}

class ContestWinnersResult extends ContestResult {
  ContestWinnersResult({required this.winners, this.message});
  final List<ContestWinner> winners;
  final String? message;
}

class ContestEligibleDesignsResult extends ContestResult {
  ContestEligibleDesignsResult({
    required this.designs,
    this.message,
    this.hint,
    this.canSubmit,
  });
  final List<ContestEligibleDesign> designs;
  final String? message;
  final String? hint;
  final bool? canSubmit;
}

class ContestMessageResult extends ContestResult {
  ContestMessageResult({this.message, this.data});
  final String? message;
  final Map<String, dynamic>? data;
}

/// Like / unlike / share / interact response with authoritative counters.
class ContestInteractionResult extends ContestResult {
  ContestInteractionResult({
    required this.submissionId,
    required this.isLiked,
    required this.likesCount,
    this.viewsCount,
    this.sharesCount,
    this.shareUrl,
    this.message,
  });

  final int submissionId;
  final bool isLiked;
  final int likesCount;
  final int? viewsCount;
  final int? sharesCount;
  final String? shareUrl;
  final String? message;

  ContestInteractionState get state => ContestInteractionState(
    submissionId: submissionId,
    liked: isLiked,
    likesCount: likesCount,
    viewsCount: viewsCount,
    sharesCount: sharesCount,
    shareUrl: shareUrl,
  );
}

/// Backward-compatible alias used by existing feed callers.
typedef ContestLikeResult = ContestInteractionResult;

class ContestRepository {
  ContestRepository({ApiClient? apiClient, Dio? dio})
    : _api = apiClient ?? ApiClient(),
      _dioOverride = dio;

  static ContestRepository? _defaultInstance;
  static ContestRepository get instance =>
      _defaultInstance ??= ContestRepository();

  static void resetInstanceForTest([ContestRepository? repo]) {
    _defaultInstance = repo;
  }

  final ApiClient _api;
  final Dio? _dioOverride;

  Dio get _dio => _dioOverride ?? _api.dio;

  bool get _isGuestOrLoggedOut {
    final prefs = PrefUtils();
    return !prefs.isLoggedIn() || prefs.isGuestAccount();
  }

  ContestFailure _failureFromDio(DioException e) {
    return ContestFailure(
      apiMessageFromDioException(e),
      statusCode: e.response?.statusCode,
    );
  }

  List<ContestItem> _parseContestItems(dynamic data) {
    if (data is! Map) return const [];
    final map = data.cast<String, dynamic>();

    if (map.containsKey('open_contests') ||
        map.containsKey('closed_contests')) {
      List<ContestItem> parseList(dynamic raw) {
        if (raw is! List) return const [];
        return raw
            .whereType<Map>()
            .map((e) => ContestItem.fromJson(e.cast<String, dynamic>()))
            .toList();
      }

      return [
        ...parseList(map['open_contests']),
        ...parseList(map['closed_contests']),
      ];
    }

    return apiExtractDataList(map).map(ContestItem.fromJson).toList();
  }

  Future<ContestResult> categoryList() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('contest/category');
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final list = apiExtractDataList(data).map(CategoryItem.fromJson).toList();
      return ContestCategoriesResult(
        categories: list,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  /// Public paginated listing — `GET /public/contests`.
  Future<ContestResult> publicList({
    int page = 1,
    int perPage = 15,
    int? categoryId,
    String? status,
    String? search,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'public/contests',
        queryParameters: <String, dynamic>{
          'page': page.clamp(1, 1000000).toString(),
          'per_page': perPage.clamp(1, 50).toString(),
          if (categoryId != null) 'category_id': categoryId.toString(),
          if (status != null && status.isNotEmpty && status != 'all')
            'status': status,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) &&
          !data.containsKey('dbData') &&
          !data.containsKey('open_contests')) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not load contests',
        );
      }
      final items = _parseContestItems(data);
      final contestPage = ContestPage.fromResponse(
        data: data,
        items: items,
        message: apiExtractMessage(data),
      );
      final split = splitContestsOpenClosed(items);
      return ContestListResult(
        items: items,
        openContests: split.open,
        closedContests: split.closed,
        message: apiExtractMessage(data),
        page: contestPage,
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  /// Authenticated search — `GET /contests/search`.
  Future<ContestResult> search({
    required String query,
    int page = 1,
    int perPage = 15,
    int? categoryId,
    String? status,
    int limit = 10,
  }) async {
    try {
      final trimmed = query.trim();
      final response = await _dio.get<Map<String, dynamic>>(
        'contests/search',
        queryParameters: <String, dynamic>{
          'search': trimmed,
          'limit': limit.clamp(1, 50).toString(),
          'q': trimmed,
          'page': page.clamp(1, 1000000).toString(),
          'per_page': perPage.clamp(1, 50).toString(),
          if (categoryId != null) 'category_id': categoryId.toString(),
          if (status != null && status.isNotEmpty && status != 'all')
            'status': status,
        },
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final items = _parseContestItems(data);
      return ContestListResult(
        items: items,
        message: apiExtractMessage(data),
        page: ContestPage.fromResponse(
          data: data,
          items: items,
          message: apiExtractMessage(data),
        ),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> list({bool forceRefresh = false}) async {
    return publicList(page: 1, perPage: 50);
  }

  /// Detail — `GET /contests/{id}` (auth) or `GET /public/contests/{id}` (guest).
  Future<ContestResult> getDetail(int id) async {
    try {
      final path = _isGuestOrLoggedOut ? 'public/contests/$id' : 'contests/$id';
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && !data.containsKey('dbData')) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Contest not found',
          statusCode: response.statusCode,
        );
      }
      final detail = ContestDetail.fromResponse(data);
      return ContestDetailResult(
        detail: detail,
        item: detail.contest,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> getById(int id) async {
    return getDetail(id);
  }

  Future<ContestResult> joinContest(int contestId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'contests/$contestId/join',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && data['status'] != true) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not join contest',
        );
      }
      return ContestMessageResult(
        message: apiExtractMessage(data),
        data: apiExtractPayloadMap(data),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> eligibleDesigns(int contestId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'contests/$contestId/eligible-designs',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && !data.containsKey('dbData')) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not load eligible designs',
        );
      }
      final root = data.cast<String, dynamic>();
      final payload = apiExtractPayloadMap(root);
      final list = _parseEligibleDesignRows(
        root,
      ).map((e) => ContestEligibleDesign.fromJson(e)).toList();
      final hint = payload?['hint']?.toString().trim();
      return ContestEligibleDesignsResult(
        designs: list,
        message: apiExtractMessage(data),
        hint: hint != null && hint.isNotEmpty ? hint : null,
        canSubmit: apiParseBool(payload?['can_submit']),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> submitDesign({
    required int contestId,
    required int designId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'contests/$contestId/submissions',
        data: {'design_id': designId},
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && data['status'] != true) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not submit design',
        );
      }
      return ContestMessageResult(
        message: apiExtractMessage(data),
        data: apiExtractPayloadMap(data),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> mySubmissions(int contestId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'contests/$contestId/my-submissions',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && !data.containsKey('dbData')) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not load submissions',
        );
      }
      final root = data.cast<String, dynamic>();
      final list = _parseSubmissionRows(
        root,
      ).map((e) => ContestSubmission.fromJson(e)).toList();
      return ContestSubmissionsResult(
        submissions: list,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> gallerySubmissions(
    int contestId, {
    String sort = 'recent',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'contests/$contestId/submissions',
        queryParameters: <String, dynamic>{
          'sort': sort,
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final root = data.cast<String, dynamic>();
      final list = _parseSubmissionRows(
        root,
      ).map((e) => ContestSubmission.fromJson(e)).toList();
      return ContestSubmissionsResult(
        submissions: list,
        message: apiExtractMessage(data),
        page: ContestPage.fromResponse(
          data: data,
          items: list,
          message: apiExtractMessage(data),
        ),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  /// Global contest feed — `GET /public/contests/submissions/feed`.
  ///
  /// No auth required. Optional [contestId], [featured], [sort] (`recent`|`likes`).
  /// Falls back to aggregating active contest galleries when unavailable.
  Future<ContestResult> feedSubmissions({
    int page = 1,
    int perPage = 20,
    int? contestId,
    bool? featured,
    String sort = 'recent',
  }) async {
    final normalizedSort = sort == 'likes' ? 'likes' : 'recent';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'public/contests/submissions/feed',
        queryParameters: <String, dynamic>{
          'page': page.clamp(1, 1000000).toString(),
          'per_page': perPage.clamp(1, 100).toString(),
          'sort': normalizedSort,
          if (contestId != null && contestId > 0)
            'contest_id': contestId.toString(),
          if (featured != null) 'featured': featured ? '1' : '0',
        },
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final root = data.cast<String, dynamic>();
      final list = _parseSubmissionRows(
        root,
      ).map(ContestSubmission.fromJson).toList();
      return ContestSubmissionsResult(
        submissions: list,
        message: apiExtractMessage(data),
        page: ContestPage.fromResponse(
          data: data,
          items: list,
          message: apiExtractMessage(data),
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _aggregateFeedFromContests(
          page: page,
          perPage: perPage,
          sort: normalizedSort,
        );
      }
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  /// Like a submission — `POST /contests/submissions/{id}/like`.
  Future<ContestResult> likeSubmission(int submissionId) async {
    return _mutateSubmissionLike(submissionId, like: true);
  }

  /// Unlike a submission — `DELETE /contests/submissions/{id}/like`.
  Future<ContestResult> unlikeSubmission(int submissionId) async {
    return _mutateSubmissionLike(submissionId, like: false);
  }

  /// Toggle like based on current state.
  Future<ContestResult> toggleSubmissionLike(
    int submissionId, {
    required bool currentlyLiked,
  }) {
    return currentlyLiked
        ? unlikeSubmission(submissionId)
        : likeSubmission(submissionId);
  }

  /// Record a share — `POST /contests/submissions/{id}/share`.
  ///
  /// Prefer calling this **before** opening the native share sheet, then use
  /// [ContestInteractionResult.shareUrl] from the response.
  Future<ContestResult> recordSubmissionShare(
    int submissionId, {
    String? channel,
    String? source,
  }) async {
    try {
      final body = <String, dynamic>{
        if (channel != null && channel.trim().isNotEmpty)
          'channel': channel.trim(),
        if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
      };
      final response = await _dio.post<Map<String, dynamic>>(
        'contests/submissions/$submissionId/share',
        data: body.isEmpty ? null : body,
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && data['status'] != true) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not record share',
        );
      }
      return _interactionFromPayload(
        data,
        fallbackSubmissionId: submissionId,
        fallbackLiked: false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return ContestFailure(apiMessageFromDioException(e), statusCode: 404);
      }
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  /// Unified interaction — `POST /contests/submissions/{id}/interact`.
  ///
  /// [action] must be one of: `view`, `share`, `like`, `unlike`.
  Future<ContestResult> interactSubmission(
    int submissionId, {
    required String action,
    String? channel,
    String? source,
  }) async {
    final normalized = action.trim().toLowerCase();
    const allowed = {'view', 'share', 'like', 'unlike'};
    if (!allowed.contains(normalized)) {
      return ContestFailure('Invalid interaction action');
    }
    try {
      final body = <String, dynamic>{
        'action': normalized,
        if (normalized == 'share' &&
            channel != null &&
            channel.trim().isNotEmpty)
          'channel': channel.trim(),
        if (normalized == 'share' && source != null && source.trim().isNotEmpty)
          'source': source.trim(),
      };
      final response = await _dio.post<Map<String, dynamic>>(
        'contests/submissions/$submissionId/interact',
        data: body,
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && data['status'] != true) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not record interaction',
        );
      }
      return _interactionFromPayload(
        data,
        fallbackSubmissionId: submissionId,
        fallbackLiked: normalized == 'like',
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> _mutateSubmissionLike(
    int submissionId, {
    required bool like,
  }) async {
    try {
      final Response<Map<String, dynamic>> response;
      if (like) {
        response = await _dio.post<Map<String, dynamic>>(
          'contests/submissions/$submissionId/like',
        );
      } else {
        response = await _dio.delete<Map<String, dynamic>>(
          'contests/submissions/$submissionId/like',
        );
      }
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && data['status'] != true) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not update like',
          statusCode: response.statusCode,
        );
      }
      return _interactionFromPayload(
        data,
        fallbackSubmissionId: submissionId,
        fallbackLiked: like,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return interactSubmission(
          submissionId,
          action: like ? 'like' : 'unlike',
        );
      }
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  ContestInteractionResult _interactionFromPayload(
    Map<String, dynamic> data, {
    required int fallbackSubmissionId,
    required bool fallbackLiked,
  }) {
    final payload = apiExtractPayloadMap(data) ?? data;
    final state = ContestInteractionState.fromJson(payload);
    return ContestInteractionResult(
      submissionId: state.submissionId > 0
          ? state.submissionId
          : fallbackSubmissionId,
      isLiked: state.liked ?? fallbackLiked,
      likesCount: state.likesCount ?? 0,
      viewsCount: state.viewsCount,
      sharesCount: state.sharesCount,
      shareUrl: state.shareUrl,
      message: apiExtractMessage(data),
    );
  }

  List<ContestSubmission>? _feedCache;
  DateTime? _feedCacheAt;

  Future<ContestResult> _aggregateFeedFromContests({
    required int page,
    required int perPage,
    String sort = 'recent',
  }) async {
    try {
      final now = DateTime.now();
      if (_feedCache == null ||
          _feedCacheAt == null ||
          now.difference(_feedCacheAt!) > const Duration(minutes: 3)) {
        final contestsResult = await publicList(
          page: 1,
          perPage: 25,
          status: 'active',
        );
        if (contestsResult is! ContestListResult) {
          return contestsResult;
        }

        final merged = <ContestSubmission>[];
        for (final contest in contestsResult.items.take(12)) {
          final subs = await gallerySubmissions(
            contest.id,
            sort: sort == 'likes' ? 'likes' : 'recent',
            page: 1,
            perPage: 12,
          );
          if (subs is ContestSubmissionsResult) {
            for (final submission in subs.submissions) {
              merged.add(
                submission.copyWith(
                  contestTitle: submission.contestTitle ?? contest.name,
                ),
              );
            }
          }
        }

        if (sort == 'likes') {
          merged.sort(
            (a, b) => (b.likesCount ?? 0).compareTo(a.likesCount ?? 0),
          );
        } else {
          merged.sort((a, b) {
            final ad = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
            final bd = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
            return bd.compareTo(ad);
          });
        }
        _feedCache = merged;
        _feedCacheAt = now;
      }

      final cache = _feedCache ?? const <ContestSubmission>[];
      final start = (page - 1) * perPage;
      if (start >= cache.length) {
        return ContestSubmissionsResult(
          submissions: const [],
          page: ContestPage<ContestSubmission>(
            items: const [],
            currentPage: page,
            perPage: perPage,
            total: cache.length,
          ),
        );
      }

      final slice = cache.skip(start).take(perPage).toList();
      final hasMore = start + perPage < cache.length;
      return ContestSubmissionsResult(
        submissions: slice,
        page: ContestPage<ContestSubmission>(
          items: slice,
          currentPage: page,
          perPage: perPage,
          total: cache.length,
          nextPage: hasMore ? page + 1 : null,
        ),
      );
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> publicWinners(int contestId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'public/contests/$contestId/winners',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      if (!apiResponseIsSuccess(data) && !data.containsKey('dbData')) {
        return ContestFailure(
          apiExtractMessage(data) ?? 'Could not load winners',
        );
      }
      final root = data.cast<String, dynamic>();
      final list = _parseWinnerRows(
        root,
      ).map((e) => ContestWinner.fromJson(e)).toList();
      return ContestWinnersResult(
        winners: list,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> acceptedDesigns(int contestId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'contest/accepteddesigns/$contestId',
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      final rawList = apiExtractDataList(data);
      final entries = ContestDesignEntry.fromAcceptedPayload(rawList);
      final stats = ContestSubmissionStats.fromJsonMap(
        data.cast<String, dynamic>(),
      );
      return ContestAcceptedDesignsResult(
        entries: entries,
        stats: stats.hasAny ? stats : null,
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestSubmissionStats?> submissionStats(
    int contestId, {
    ContestItem? contest,
    int? acceptedFromEntries,
    ContestSubmissionStats? responseStats,
  }) async {
    var stats = contest != null
        ? ContestSubmissionStats.fromContestItem(contest)
        : const ContestSubmissionStats();
    if (!stats.hasAny) {
      stats = responseStats ?? const ContestSubmissionStats();
    } else {
      stats = stats.merge(responseStats);
    }

    if (!stats.hasAny || stats.submitted == null) {
      final detailRes = await getDetail(contestId);
      if (detailRes is ContestDetailResult && detailRes.detail != null) {
        stats = stats.merge(detailRes.detail!.stats);
      }
    }

    if (acceptedFromEntries != null && stats.accepted == null) {
      stats = stats.merge(
        ContestSubmissionStats(accepted: acceptedFromEntries),
      );
    }
    if (stats.submitted == null &&
        stats.accepted != null &&
        stats.rejected != null) {
      stats = stats.merge(
        ContestSubmissionStats(submitted: stats.accepted! + stats.rejected!),
      );
    }
    return stats.hasAny ? stats : null;
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
      final path = 'contest/add';
      final response = await _dio.post<Map<String, dynamic>>(
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
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> submissionStatus({
    required int submissionId,
    required String status,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'contest/submissionstatus/$submissionId',
        data: {'status': status},
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      return ContestMessageResult(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> assignPosition({
    required int submissionId,
    required int position,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'contest/assignposition/$submissionId',
        data: {'position': position},
      );
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      return ContestMessageResult(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }

  Future<ContestResult> delete(int id) async {
    try {
      final path = 'contest/delete/$id';
      final response = await _dio.delete<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) return ContestFailure('Empty response');
      return ContestMessageResult(message: apiExtractMessage(data));
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return ContestFailure('Something went wrong');
    }
  }
}

List<Map<String, dynamic>> _parseEligibleDesignRows(Map<String, dynamic> root) {
  final direct = apiExtractDataList(root);
  if (direct.isNotEmpty) return direct;

  final payload = apiExtractPayloadMap(root);
  if (payload == null) return const [];

  for (final key in const ['designs', 'eligible_designs', 'items']) {
    final raw = payload[key];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
  }
  return const [];
}

List<Map<String, dynamic>> _parseSubmissionRows(Map<String, dynamic> root) {
  final direct = apiExtractDataList(root);
  if (direct.isNotEmpty) return direct;

  final payload = apiExtractPayloadMap(root);
  if (payload == null) return const [];

  for (final key in const ['submissions', 'my_submissions', 'items']) {
    final raw = payload[key];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
  }

  final user = payload['user'];
  if (user is Map) {
    final nested = user['my_submissions'];
    if (nested is List) {
      return nested
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
  }
  return const [];
}

List<Map<String, dynamic>> _parseWinnerRows(Map<String, dynamic> root) {
  final direct = apiExtractDataList(root);
  if (direct.isNotEmpty) return direct;

  final payload = apiExtractPayloadMap(root);
  if (payload == null) return const [];

  for (final key in const ['winners', 'items']) {
    final raw = payload[key];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
  }
  return const [];
}
