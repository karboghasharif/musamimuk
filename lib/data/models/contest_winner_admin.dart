import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

/// Row from `GET /admin/contests/{id}/winners` (`contest_winners` + nested submission/design).
class ContestWinnerAdmin {
  const ContestWinnerAdmin({
    required this.id,
    required this.position,
    this.contestSubmissionId,
    this.prizeAmount,
    this.design,
    this.userName,
  });

  /// `contest_winners.id` (for `DELETE .../winners/{id}`).
  final int id;
  final int position;
  final int? contestSubmissionId;
  final double? prizeAmount;
  final MediaItem? design;
  final String? userName;

  factory ContestWinnerAdmin.fromJson(Map<String, dynamic> json) {
    MediaItem? design;
    String? userName;
    int? submissionId;

    final submission = json['submission'];
    if (submission is Map) {
      final sm = submission.cast<String, dynamic>();
      submissionId =
          sm['id'] == null ? null : apiParseInt(sm['id']);
      final user = sm['user'];
      if (user is Map) {
        final u = apiParseString(user['name']).trim();
        userName = u.isEmpty ? null : u;
      }
      final dr = sm['design'];
      if (dr is Map) {
        design = MediaItem.fromJson(dr.cast<String, dynamic>());
      }
    }

    final dr2 = json['design'];
    if (design == null && dr2 is Map) {
      design = MediaItem.fromJson(dr2.cast<String, dynamic>());
    }

    final prize = json['prize_amount_override'] ?? json['prize_amount'];
    double? prizeAmount;
    if (prize is num) {
      prizeAmount = prize.toDouble();
    } else if (prize != null) {
      prizeAmount = double.tryParse(prize.toString());
    }

    return ContestWinnerAdmin(
      id: apiParseInt(json['id']),
      position: apiParseInt(json['position'], fallback: 0),
      contestSubmissionId:
          json['contest_submission_id'] == null
              ? submissionId
              : apiParseInt(json['contest_submission_id']),
      prizeAmount: prizeAmount,
      design: design,
      userName: userName,
    );
  }

  /// Designs ordered by [position] for contest “accepted / winners” UI.
  static List<MediaItem> toDesignsByPosition(List<ContestWinnerAdmin> winners) {
    final sorted = List<ContestWinnerAdmin>.from(winners)
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.map((e) => e.design).whereType<MediaItem>().toList();
  }
}
