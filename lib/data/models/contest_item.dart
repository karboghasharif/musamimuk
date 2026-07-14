import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/contest_utils.dart';
import 'package:musamimuk/data/models/contest_countdown.dart';
import 'package:musamimuk/data/models/contest_prize.dart';
import 'package:musamimuk/data/models/contest_user_context.dart';
import 'package:musamimuk/data/models/media_item.dart';

class ContestItem {
  final int id;
  final String name;
  final int? categoryId;
  final String fileUrl;
  final String? startDate;
  final String? endDate;
  final MediaCategoryRef? category;
  /// From admin list: `upcoming` | `active` | `ended` | `completed` (optional).
  final String? status;
  final bool? isActive;
  final bool? isCompleted;
  final int? submissionsCount;
  final int? acceptedCount;
  final int? rejectedCount;
  final int? participantsCount;
  final ContestPrize? prize;
  final ContestCountdown? countdown;
  final String? prizeText;
  final String? description;
  final String? tags;
  final ContestUserContext? user;

  const ContestItem({
    required this.id,
    required this.name,
    this.categoryId,
    required this.fileUrl,
    this.startDate,
    this.endDate,
    this.category,
    this.status,
    this.isActive,
    this.isCompleted,
    this.submissionsCount,
    this.acceptedCount,
    this.rejectedCount,
    this.participantsCount,
    this.prize,
    this.countdown,
    this.prizeText,
    this.description,
    this.tags,
    this.user,
  });

  factory ContestItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final fileUrlRaw = apiParseString(json['file_url']);
    final imageUrlRaw = apiParseString(json['image_url']);
    final directUrl = fileUrlRaw.isNotEmpty ? fileUrlRaw : imageUrlRaw;
    final resolvedUrl =
        directUrl.isNotEmpty ? directUrl : apiResolveDesignFileUrl(json);
    final prizeRaw = json['prize'] ?? json['prize_breakdown'];
    final countdownRaw = json['countdown'];
    final countdown = countdownRaw != null
        ? ContestCountdown.fromJson(countdownRaw)
        : null;
    final userRaw = json['user'];
    ContestUserContext? user;
    if (userRaw is Map) {
      user = ContestUserContext.fromJson(userRaw.cast<String, dynamic>());
    } else if (ContestUserContext.hasInlineFlags(json)) {
      user = ContestUserContext.fromJson(json);
    }
    int? parsedCategoryId;
    if (json['category_id'] != null) {
      parsedCategoryId = apiParseInt(json['category_id']);
    } else if (cat is Map && cat['id'] != null) {
      parsedCategoryId = apiParseInt(cat['id']);
    }
    return ContestItem(
      id: apiParseInt(json['id']),
      name: apiParseString(json['name']),
      categoryId: parsedCategoryId,
      fileUrl: resolvedUrl,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      category: cat is Map ? MediaCategoryRef.fromJson(cat.cast<String, dynamic>()) : null,
      status: _parseStatus(json, countdown),
      isActive: apiParseBool(json['is_active']),
      isCompleted: apiParseBool(json['is_completed']),
      submissionsCount: parseOptionalCount(json, const [
        'submissions_count',
        'total_submissions',
        'designs_submitted',
        'submitted_count',
      ]),
      acceptedCount: parseOptionalCount(json, const [
        'accepted_count',
        'designs_accepted',
        'accepted_submissions',
      ]),
      rejectedCount: parseOptionalCount(json, const [
        'rejected_count',
        'designs_rejected',
        'rejected_submissions',
      ]),
      participantsCount: parseOptionalCount(json, const [
        'participants_count',
        'joined_count',
        'entries_count',
      ]),
      prize: prizeRaw != null ? ContestPrize.fromJson(prizeRaw) : null,
      countdown: countdown,
      prizeText: json['prize_text']?.toString() ??
          json['prize_amount']?.toString(),
      description: json['description']?.toString(),
      tags: json['tags']?.toString(),
      user: user,
    );
  }

  /// For [Navigator] arguments (from [GET /api/contest/list] items).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (categoryId != null) 'category_id': categoryId,
        'file_url': fileUrl,
        'image_url': fileUrl,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (status != null) 'status': status,
        if (isActive != null) 'is_active': isActive,
        if (isCompleted != null) 'is_completed': isCompleted,
        if (submissionsCount != null) 'submissions_count': submissionsCount,
        if (acceptedCount != null) 'accepted_count': acceptedCount,
        if (rejectedCount != null) 'rejected_count': rejectedCount,
        if (participantsCount != null) 'participants_count': participantsCount,
        if (prizeText != null) 'prize_text': prizeText,
        if (description != null) 'description': description,
        if (tags != null) 'tags': tags,
        if (category != null)
          'category': {'id': category!.id, 'name': category!.name},
        if (countdown != null)
          'countdown': {
            if (countdown!.phase != null) 'status': countdown!.phase,
            if (countdown!.remainingSeconds != null)
              'seconds_until_end': countdown!.remainingSeconds,
            if (countdown!.label != null) 'label': countdown!.label,
          },
        if (user != null)
          'user': {
            if (user!.primaryAction != null) 'primary_action': user!.primaryAction,
            'has_joined': user!.joined,
            if (user!.canJoin != null) 'can_join': user!.canJoin,
            if (user!.canSubmit != null) 'can_submit': user!.canSubmit,
            if (user!.hasSubmitted) 'has_submitted': user!.hasSubmitted,
          },
      };

  String get prizeDisplay =>
      prize?.displayText().isNotEmpty == true
          ? prize!.displayText()
          : (prizeText?.trim().isNotEmpty == true ? prizeText!.trim() : '');

  String get statusLabel {
    final s = status?.toLowerCase().trim();
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  static String? _parseStatus(
    Map<String, dynamic> json,
    ContestCountdown? countdown,
  ) {
    final st = json['status']?.toString().trim();
    if (st != null && st.isNotEmpty) return st;
    final phase = countdown?.phase?.trim();
    if (phase != null && phase.isNotEmpty) return phase;
    return null;
  }
}

