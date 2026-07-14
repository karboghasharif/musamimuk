import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

/// A contest submission row (gallery / feed / my-submissions).
class ContestSubmission {
  const ContestSubmission({
    required this.id,
    required this.contestId,
    this.status,
    this.design,
    this.designId,
    this.thumbnailUrl,
    this.submitterName,
    this.submitterId,
    this.submitterAvatarUrl,
    this.contestTitle,
    this.description,
    this.likesCount,
    this.sharesCount,
    this.isLiked,
    this.createdAt,
    this.rejectionReason,
  });

  final int id;
  final int contestId;
  final String? status;
  final MediaItem? design;
  final int? designId;
  final String? thumbnailUrl;
  final String? submitterName;
  final int? submitterId;
  final String? submitterAvatarUrl;
  final String? contestTitle;
  final String? description;
  final int? likesCount;
  final int? sharesCount;
  final bool? isLiked;
  final String? createdAt;
  final String? rejectionReason;

  ContestSubmission copyWith({
    int? likesCount,
    int? sharesCount,
    bool? isLiked,
    String? contestTitle,
  }) {
    return ContestSubmission(
      id: id,
      contestId: contestId,
      status: status,
      design: design,
      designId: designId,
      thumbnailUrl: thumbnailUrl,
      submitterName: submitterName,
      submitterId: submitterId,
      submitterAvatarUrl: submitterAvatarUrl,
      contestTitle: contestTitle ?? this.contestTitle,
      description: description,
      likesCount: likesCount ?? this.likesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      rejectionReason: rejectionReason,
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
    return design?.fileUrl ?? '';
  }

  factory ContestSubmission.fromJson(Map<String, dynamic> json) {
    final designRaw = json['design'];
    MediaItem? design;
    if (designRaw is Map) {
      design = MediaItem.fromJson(designRaw.cast<String, dynamic>());
    }

    final user = json['user'] ?? json['submitter'];
    Map<String, dynamic>? userMap;
    if (user is Map) {
      userMap = user.cast<String, dynamic>();
    }

    final contestRaw = json['contest'];
    String? contestTitle;
    if (contestRaw is Map) {
      contestTitle = contestRaw['name']?.toString() ??
          contestRaw['title']?.toString();
    }
    contestTitle ??= json['contest_name']?.toString() ??
        json['contest_title']?.toString();

    final description = json['description']?.toString()?.trim();
    final designDescription = designRaw is Map
        ? designRaw['description']?.toString().trim()
        : null;
    final resolvedDescription = (description != null && description.isNotEmpty)
        ? description
        : (designDescription != null && designDescription.isNotEmpty
            ? designDescription
            : null);

    return ContestSubmission(
      id: apiParseInt(json['id'] ?? json['submission_id']),
      contestId: apiParseInt(json['contest_id']),
      status: _submissionStatus(json),
      design: design,
      designId: json['design_id'] == null
          ? design?.id
          : apiParseInt(json['design_id']),
      thumbnailUrl: json['thumbnail_url']?.toString() ??
          json['preview_url']?.toString(),
      submitterName: json['submitter_name']?.toString() ??
          userMap?['name']?.toString() ??
          userMap?['full_name']?.toString(),
      submitterId: userMap?['id'] == null
          ? null
          : apiParseInt(userMap!['id']),
      submitterAvatarUrl: _avatarFrom(userMap) ??
          json['submitter_avatar']?.toString() ??
          json['avatar_url']?.toString(),
      contestTitle: contestTitle,
      description: resolvedDescription,
      likesCount: json['likes_count'] == null
          ? null
          : apiParseInt(json['likes_count']),
      sharesCount: json['shares_count'] == null
          ? null
          : apiParseInt(json['shares_count']),
      isLiked: apiParseBool(
        json['is_liked'] ?? json['liked_by_me'] ?? json['liked'],
      ),
      createdAt: json['created_at']?.toString() ??
          json['submitted_at']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  static String? _avatarFrom(Map<String, dynamic>? user) {
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
