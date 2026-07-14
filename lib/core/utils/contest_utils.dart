import 'package:musamimuk/core/utils/date_display_utils.dart';
import 'package:musamimuk/data/models/contest_item.dart';
import 'package:musamimuk/data/models/contest_submission_admin.dart';

/// Whether a contest should appear under "closed" (ended / completed).
bool isContestClosed(ContestItem contest) {
  final status = contest.status?.toLowerCase().trim();
  if (status == 'upcoming' || status == 'active') return false;
  if (status == 'ended' || status == 'completed' || status == 'closed') {
    return true;
  }
  if (contest.isCompleted == true) return true;
  if (contest.isActive == false &&
      status != null &&
      status != 'upcoming' &&
      status != 'active') {
    return true;
  }
  return isContestEndOverdue(contest.endDate);
}

/// Splits a flat contest list into open vs closed buckets.
({List<ContestItem> open, List<ContestItem> closed}) splitContestsOpenClosed(
  List<ContestItem> items,
) {
  final open = <ContestItem>[];
  final closed = <ContestItem>[];
  for (final contest in items) {
    if (isContestClosed(contest)) {
      closed.add(contest);
    } else {
      open.add(contest);
    }
  }
  return (open: open, closed: closed);
}

/// True when results / winners should be shown to users.
bool isContestResultsAnnounced(
  ContestItem? contest, {
  required bool hasWinners,
}) {
  if (contest == null) return hasWinners;
  if (contest.isCompleted == true) return true;
  final status = contest.status?.toLowerCase().trim();
  if (status == 'completed' || status == 'ended') return true;
  if (hasWinners && isContestEndOverdue(contest.endDate)) return true;
  return false;
}

int? parseOptionalCount(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key];
    if (raw == null) continue;
    if (raw is num) return raw.toInt();
    final parsed = int.tryParse(raw.toString().trim());
    if (parsed != null) return parsed;
  }
  return null;
}

/// Submission totals for the contest detail stats row.
class ContestSubmissionStats {
  const ContestSubmissionStats({
    this.submitted,
    this.accepted,
    this.rejected,
  });

  final int? submitted;
  final int? accepted;
  final int? rejected;

  bool get hasAny =>
      submitted != null || accepted != null || rejected != null;

  factory ContestSubmissionStats.fromContestItem(ContestItem contest) {
    return ContestSubmissionStats(
      submitted: contest.submissionsCount,
      accepted: contest.acceptedCount,
      rejected: contest.rejectedCount,
    );
  }

  factory ContestSubmissionStats.fromJsonMap(Map<String, dynamic> json) {
    final stats = json['stats'];
    final nested = stats is Map ? stats.cast<String, dynamic>() : json;
    return ContestSubmissionStats(
      submitted: parseOptionalCount(nested, const [
        'submissions_count',
        'total_submissions',
        'designs_submitted',
        'submitted_count',
        'submitted',
      ]),
      accepted: parseOptionalCount(nested, const [
        'accepted_count',
        'designs_accepted',
        'accepted_submissions',
        'accepted',
      ]),
      rejected: parseOptionalCount(nested, const [
        'rejected_count',
        'designs_rejected',
        'rejected_submissions',
        'rejected',
      ]),
    );
  }

  static ContestSubmissionStats fromSubmissions(
    List<ContestSubmissionAdmin> submissions,
  ) {
    var accepted = 0;
    var rejected = 0;
    for (final row in submissions) {
      final status = row.status?.toLowerCase().trim() ?? '';
      if (status.contains('accept') ||
          status == 'approved' ||
          status == 'featured') {
        accepted++;
      } else if (status.contains('reject') ||
          status == 'disqualified' ||
          status == 'rejected') {
        rejected++;
      }
    }
    return ContestSubmissionStats(
      submitted: submissions.length,
      accepted: accepted,
      rejected: rejected,
    );
  }

  ContestSubmissionStats merge(ContestSubmissionStats? other) {
    if (other == null) return this;
    return ContestSubmissionStats(
      submitted: submitted ?? other.submitted,
      accepted: accepted ?? other.accepted,
      rejected: rejected ?? other.rejected,
    );
  }
}
