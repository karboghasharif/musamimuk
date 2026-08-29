import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

/// Nested design summary on a feed submission.
class ContestSubmissionDesignSummary {
  const ContestSubmissionDesignSummary({
    required this.id,
    this.name,
    this.fileUrl,
    this.status,
    this.isActive,
  });

  final int id;
  final String? name;
  final String? fileUrl;
  final String? status;
  final bool? isActive;

  factory ContestSubmissionDesignSummary.fromJson(Map<String, dynamic> json) {
    return ContestSubmissionDesignSummary(
      id: apiParseInt(json['id']),
      name: _nullableString(json['name'] ?? json['title']),
      fileUrl: _nullableString(
        json['file_url'] ?? json['image_url'] ?? json['url'],
      ),
      status: _nullableString(json['status']),
      isActive: apiParseBool(json['is_active']),
    );
  }
}

/// Nested designer summary on a feed submission.
class ContestSubmissionUserSummary {
  const ContestSubmissionUserSummary({
    required this.id,
    this.name,
    this.avatarUrl,
  });

  final int id;
  final String? name;
  final String? avatarUrl;

  factory ContestSubmissionUserSummary.fromJson(Map<String, dynamic> json) {
    return ContestSubmissionUserSummary(
      id: apiParseInt(json['id']),
      name: _nullableString(json['name'] ?? json['full_name']),
      avatarUrl: ContestSubmission.avatarFrom(json),
    );
  }
}

/// Nested contest summary on a feed submission.
class ContestSubmissionContestSummary {
  const ContestSubmissionContestSummary({required this.id, this.name});

  final int id;
  final String? name;

  factory ContestSubmissionContestSummary.fromJson(Map<String, dynamic> json) {
    return ContestSubmissionContestSummary(
      id: apiParseInt(json['id']),
      name: _nullableString(json['name'] ?? json['title']),
    );
  }
}

/// Authoritative counters / like state from like, share, or interact APIs.
class ContestInteractionState {
  const ContestInteractionState({
    required this.submissionId,
    this.liked,
    this.likesCount,
    this.viewsCount,
    this.sharesCount,
    this.shareUrl,
  });

  final int submissionId;
  final bool? liked;
  final int? likesCount;
  final int? viewsCount;
  final int? sharesCount;
  final String? shareUrl;

  factory ContestInteractionState.fromJson(Map<String, dynamic> json) {
    return ContestInteractionState(
      submissionId: apiParseInt(json['submission_id'] ?? json['id']),
      liked: apiParseBool(json['liked'] ?? json['is_liked']),
      likesCount: json['likes_count'] == null
          ? null
          : apiParseInt(json['likes_count']),
      viewsCount: json['views_count'] == null
          ? null
          : apiParseInt(json['views_count']),
      sharesCount: json['shares_count'] == null
          ? null
          : apiParseInt(json['shares_count']),
      shareUrl: _nullableString(json['share_url']),
    );
  }
}

/// A contest submission row (gallery / feed / my-submissions).
class ContestSubmission {
  const ContestSubmission({
    required this.id,
    required this.contestId,
    this.status,
    this.design,
    this.designSummary,
    this.designId,
    this.thumbnailUrl,
    this.submitterName,
    this.submitterId,
    this.submitterAvatarUrl,
    this.userSummary,
    this.contestTitle,
    this.contestSummary,
    this.description,
    this.comments,
    this.likesCount,
    this.viewsCount,
    this.sharesCount,
    this.isLiked,
    this.isFeatured,
    this.position,
    this.createdAt,
    this.rejectionReason,
  });

  final int id;
  final int contestId;
  final String? status;
  final MediaItem? design;
  final ContestSubmissionDesignSummary? designSummary;
  final int? designId;
  final String? thumbnailUrl;
  final String? submitterName;
  final int? submitterId;
  final String? submitterAvatarUrl;
  final ContestSubmissionUserSummary? userSummary;
  final String? contestTitle;
  final ContestSubmissionContestSummary? contestSummary;
  final String? description;
  final String? comments;
  final int? likesCount;
  final int? viewsCount;
  final int? sharesCount;
  final bool? isLiked;
  final bool? isFeatured;
  final int? position;
  final String? createdAt;
  final String? rejectionReason;

  ContestSubmission copyWith({
    int? likesCount,
    int? viewsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isFeatured,
    String? contestTitle,
    String? comments,
    String? description,
  }) {
    return ContestSubmission(
      id: id,
      contestId: contestId,
      status: status,
      design: design,
      designSummary: designSummary,
      designId: designId,
      thumbnailUrl: thumbnailUrl,
      submitterName: submitterName,
      submitterId: submitterId,
      submitterAvatarUrl: submitterAvatarUrl,
      userSummary: userSummary,
      contestTitle: contestTitle ?? this.contestTitle,
      contestSummary: contestSummary,
      description: description ?? this.description,
      comments: comments ?? this.comments,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isFeatured: isFeatured ?? this.isFeatured,
      position: position,
      createdAt: createdAt,
      rejectionReason: rejectionReason,
    );
  }

  /// Applies authoritative interaction counters from the API.
  ContestSubmission applyInteraction(ContestInteractionState state) {
    return copyWith(
      isLiked: state.liked ?? isLiked,
      likesCount: state.likesCount ?? likesCount,
      viewsCount: state.viewsCount ?? viewsCount,
      sharesCount: state.sharesCount ?? sharesCount,
    );
  }

  String get displayStatus {
    final s = (status ?? '').toLowerCase().trim();
    if (s.contains('approve') || s == 'accepted' || s == 'featured') {
      return 'Approved';
    }
    if (s.contains('reject') || s == 'disqualified') return 'Rejected';
    if (s.contains('pending') || s.isEmpty) return 'Pending';
    return status ?? 'Pending';
  }

  String get imageUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl!;
    final summaryUrl = designSummary?.fileUrl;
    if (summaryUrl != null && summaryUrl.isNotEmpty) return summaryUrl;
    return design?.fileUrl ?? '';
  }

  String get displayComments {
    final c = comments?.trim();
    if (c != null && c.isNotEmpty) return c;
    return description?.trim() ?? '';
  }

  String get designerName {
    final fromUser = userSummary?.name?.trim();
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;
    return submitterName?.trim() ?? '';
  }

  String get contestDisplayName {
    final fromContest = contestSummary?.name?.trim();
    if (fromContest != null && fromContest.isNotEmpty) return fromContest;
    return contestTitle?.trim() ?? '';
  }

  factory ContestSubmission.fromJson(Map<String, dynamic> json) {
    final designRaw = json['design'];
    MediaItem? design;
    ContestSubmissionDesignSummary? designSummary;
    if (designRaw is Map) {
      final map = designRaw.cast<String, dynamic>();
      design = MediaItem.fromJson(map);
      designSummary = ContestSubmissionDesignSummary.fromJson(map);
    }

    final userRaw = json['user'] ?? json['submitter'];
    ContestSubmissionUserSummary? userSummary;
    Map<String, dynamic>? userMap;
    if (userRaw is Map) {
      userMap = userRaw.cast<String, dynamic>();
      userSummary = ContestSubmissionUserSummary.fromJson(userMap);
    }

    final contestRaw = json['contest'];
    ContestSubmissionContestSummary? contestSummary;
    String? contestTitle;
    if (contestRaw is Map) {
      final map = contestRaw.cast<String, dynamic>();
      contestSummary = ContestSubmissionContestSummary.fromJson(map);
      contestTitle = contestSummary.name;
    }
    contestTitle ??= _nullableString(
      json['contest_name'] ?? json['contest_title'],
    );

    final comments = _nullableString(json['comments']);
    final description = _nullableString(json['description']);
    final designDescription = designRaw is Map
        ? _nullableString(designRaw['description'])
        : null;
    final resolvedDescription = description ?? comments ?? designDescription;

    return ContestSubmission(
      id: apiParseInt(json['id'] ?? json['submission_id']),
      contestId: apiParseInt(json['contest_id'] ?? contestSummary?.id),
      status: _submissionStatus(json),
      design: design,
      designSummary: designSummary,
      designId: json['design_id'] == null
          ? (designSummary?.id ?? design?.id)
          : apiParseInt(json['design_id']),
      thumbnailUrl: _nullableString(
        json['thumbnail_url'] ?? json['preview_url'],
      ),
      submitterName:
          _nullableString(json['submitter_name']) ?? userSummary?.name,
      submitterId:
          userSummary?.id ??
          (userMap?['id'] == null ? null : apiParseInt(userMap!['id'])),
      submitterAvatarUrl:
          userSummary?.avatarUrl ??
          avatarFrom(userMap) ??
          _nullableString(json['submitter_avatar'] ?? json['avatar_url']),
      userSummary: userSummary,
      contestTitle: contestTitle,
      contestSummary: contestSummary,
      description: resolvedDescription,
      comments: comments,
      likesCount: json['likes_count'] == null
          ? null
          : apiParseInt(json['likes_count']),
      viewsCount: json['views_count'] == null
          ? null
          : apiParseInt(json['views_count']),
      sharesCount: json['shares_count'] == null
          ? null
          : apiParseInt(json['shares_count']),
      isLiked: apiParseBool(
        json['is_liked'] ?? json['liked_by_me'] ?? json['liked'],
      ),
      isFeatured: apiParseBool(json['is_featured']),
      position: json['position'] == null ? null : apiParseInt(json['position']),
      createdAt: _nullableString(json['created_at'] ?? json['submitted_at']),
      rejectionReason: _nullableString(json['rejection_reason']),
    );
  }

  static String? avatarFrom(Map<String, dynamic>? user) {
    if (user == null) return null;
    for (final key in const [
      'image',
      'avatar',
      'avatar_url',
      'profile_image',
      'photo',
    ]) {
      final value = user[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _submissionStatus(Map<String, dynamic> json) {
    final label = json['status_label']?.toString().trim();
    if (label != null && label.isNotEmpty) return label;
    final status = json['status']?.toString().trim();
    return status == null || status.isEmpty ? null : status;
  }
}

String? _nullableString(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
