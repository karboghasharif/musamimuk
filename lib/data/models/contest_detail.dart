import 'package:musamimuk/data/models/contest_countdown.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/contest_utils.dart';
import 'package:musamimuk/data/models/contest_item.dart';
import 'package:musamimuk/data/models/contest_prize.dart';
import 'package:musamimuk/data/models/contest_user_context.dart';
import 'package:musamimuk/data/models/media_item.dart';
import 'package:musamimuk/data/repositories/asset_repository.dart';
/// Full contest detail payload (list item + user context + countdown).
class ContestDetail {
  const ContestDetail({
    required this.contest,
    this.user,
    this.countdown,
    this.stats,
    this.prize,
    this.participantsCount,
    this.raw,
  });

  final ContestItem contest;
  final ContestUserContext? user;
  final ContestCountdown? countdown;
  final ContestSubmissionStats? stats;
  final ContestPrize? prize;
  final int? participantsCount;
  final Map<String, dynamic>? raw;

  factory ContestDetail.fromResponse(Map<String, dynamic> data) {
    final payload = _unwrapContestPayload(data);
    final contestMap = payload['contest'] is Map
        ? payload['contest'].cast<String, dynamic>()
        : payload;
    final contest = ContestItem.fromJson(contestMap);
    final userRaw = payload['user'] ?? contestMap['user'];
    ContestUserContext? user;
    if (userRaw is Map) {
      user = ContestUserContext.fromJson(userRaw.cast<String, dynamic>());
    } else if (ContestUserContext.hasInlineFlags(contestMap)) {
      user = ContestUserContext.fromJson(contestMap);
    } else if (ContestUserContext.hasInlineFlags(payload)) {
      user = ContestUserContext.fromJson(payload);
    }
    if (contest.user != null) {
      user = ContestUserContext.merge(user, contest.user);
    }
    if (user != null) {
      user = user.normalized();
    }
    final countdownRaw = payload['countdown'] ?? contestMap['countdown'];
    final prizeRaw = payload['prize'] ?? contestMap['prize'];
    final stats = ContestSubmissionStats.fromJsonMap(payload);
    return ContestDetail(
      contest: contest,
      user: user,
      countdown: countdownRaw != null
          ? ContestCountdown.fromJson(countdownRaw)
          : contest.countdown,
      stats: stats.hasAny ? stats : ContestSubmissionStats.fromContestItem(contest),
      prize: prizeRaw != null ? ContestPrize.fromJson(prizeRaw) : contest.prize,
      participantsCount: parseOptionalCount(payload, const [
        'participants_count',
        'joined_count',
        'entries_count',
      ]) ?? contest.participantsCount,
      raw: payload,
    );
  }
}

Map<String, dynamic> _unwrapContestPayload(Map<String, dynamic> data) {
  final inner = apiExtractPayloadMap(data) ?? apiExtractDbData(data);
  if (inner is Map<String, dynamic>) return inner;
  return data;
}

/// Eligible design for contest submission.
class ContestEligibleDesign {
  const ContestEligibleDesign({
    required this.id,
    required this.name,
    required this.fileUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.createdAt,
  });

  final int id;
  final String name;
  final String fileUrl;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final String? createdAt;

  String get displayUrl =>
      (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) ? thumbnailUrl! : fileUrl;

  factory ContestEligibleDesign.fromJson(Map<String, dynamic> json) {
    return ContestEligibleDesign(
      id: apiParseInt(json['id']),
      name: apiParseString(json['name']),
      fileUrl: apiResolveDesignFileUrl(json),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      width: json['width'] == null ? null : apiParseInt(json['width']),
      height: json['height'] == null ? null : apiParseInt(json['height']),
      createdAt: json['created_at']?.toString(),
    );
  }

  MediaItem toMediaItem() => MediaItem(
        id: id,
        name: name,
        fileUrl: fileUrl,
        width: width,
        height: height,
        createdAt: createdAt,
        status: 'published',
        isActive: true,
      );
}

/// Paginated list wrapper for contest endpoints.
class ContestPage<T> {
  const ContestPage({
    required this.items,
    this.currentPage = 1,
    this.perPage = 15,
    this.total = 0,
    this.nextPage,
    this.previousPage,
    this.message,
  });

  final List<T> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int? nextPage;
  final int? previousPage;
  final String? message;

  bool get hasMore => nextPage != null && nextPage! > currentPage;

  factory ContestPage.fromResponse({
    required Map<String, dynamic> data,
    required List<T> items,
    String? message,
  }) {
    final meta = data['meta'];
    if (meta is Map) {
      final m = meta.cast<String, dynamic>();
      final pagination = ApiPaginationMeta.fromJson(m);
      return ContestPage(
        items: items,
        currentPage: pagination.currentPage,
        perPage: pagination.perPage,
        total: pagination.total,
        nextPage: pagination.nextPage,
        previousPage: pagination.previousPage,
        message: message,
      );
    }
    return ContestPage(items: items, message: message);
  }
}
