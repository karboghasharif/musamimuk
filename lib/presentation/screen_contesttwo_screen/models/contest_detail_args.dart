import '../../../data/models/contest_item.dart';

/// Typed [Navigator] arguments for [ScreenContesttwoScreen].
class ContestDetailArgs {
  const ContestDetailArgs({
    required this.contestId,
    this.contest,
  });

  final int contestId;
  final ContestItem? contest;

  /// Supports [ContestDetailArgs], a string-key [Map], or null (e.g. deep link shell).
  static ContestDetailArgs? fromRouteArguments(Object? raw) {
    if (raw == null) return null;
    if (raw is ContestDetailArgs) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final idRaw = map['contestId'];
      final contestId = idRaw is int
          ? idRaw
          : idRaw is num
              ? idRaw.toInt()
              : int.tryParse(idRaw?.toString() ?? '') ?? 0;
      ContestItem? contest;
      final contestRaw = map['contest'];
      if (contestRaw is Map) {
        try {
          contest =
              ContestItem.fromJson(Map<String, dynamic>.from(contestRaw));
        } catch (_) {
          contest = null;
        }
      }
      return ContestDetailArgs(contestId: contestId, contest: contest);
    }
    return null;
  }
}
