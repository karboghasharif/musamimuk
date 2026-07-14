import 'package:musamimuk/core/network/api_utils.dart';

/// Countdown payload from contest list/detail APIs.
class ContestCountdown {
  const ContestCountdown({
    this.phase,
    this.label,
    this.targetAt,
    this.remainingSeconds,
  });

  final String? phase;
  final String? label;
  final String? targetAt;
  final int? remainingSeconds;

  factory ContestCountdown.fromJson(dynamic json) {
    if (json is! Map) return const ContestCountdown();
    final map = json.cast<String, dynamic>();
    final status = map['status']?.toString();
    final secondsUntilEnd = map['seconds_until_end'];
    final secondsUntilStart = map['seconds_until_start'];
    int? remaining;
    if (map['remaining_seconds'] != null) {
      remaining = apiParseInt(map['remaining_seconds']);
    } else if (secondsUntilEnd != null) {
      remaining = apiParseInt(secondsUntilEnd);
    } else if (secondsUntilStart != null) {
      remaining = apiParseInt(secondsUntilStart);
    }
    return ContestCountdown(
      phase: map['phase']?.toString() ?? status,
      label: map['label']?.toString() ?? _defaultLabel(status, remaining),
      targetAt: map['target_at']?.toString() ??
          map['end_date']?.toString() ??
          map['ends_at']?.toString(),
      remainingSeconds: remaining,
    );
  }

  static String? _defaultLabel(String? status, int? seconds) {
    if (seconds == null) return null;
    final s = status?.toLowerCase().trim();
    if (s == 'upcoming') return 'Starts in';
    if (s == 'active') return 'Ends in';
    if (s == 'ended' || s == 'completed') return 'Ended';
    return null;
  }

  /// Seconds left for display; prefers API [remainingSeconds], then [targetAt].
  int? secondsRemainingAt(DateTime now) {
    if (remainingSeconds != null && remainingSeconds! >= 0) {
      return remainingSeconds;
    }
    final target = _parseTarget();
    if (target == null) return null;
    final diff = target.difference(now).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  DateTime? _parseTarget() {
    final raw = targetAt?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  ContestCountdown tick(int secondsLeft) {
    return ContestCountdown(
      phase: phase,
      label: label,
      targetAt: targetAt,
      remainingSeconds: secondsLeft < 0 ? 0 : secondsLeft,
    );
  }
}

String formatContestCountdown(int totalSeconds) {
  if (totalSeconds <= 0) return '00:00:00';
  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (days > 0) {
    return '${days}d ${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
