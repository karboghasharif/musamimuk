import 'package:intl/intl.dart';

/// Readable range from ISO-8601 contest dates, e.g. `1 – 31 Aug 2026` or `1 Aug – 30 Sep 2026`.
/// Returns empty when both are missing; falls back to trimmed raw strings if parsing fails.
String formatContestDateRangeDisplay(String? start, String? end) {
  final startTrim = start?.trim() ?? '';
  final endTrim = end?.trim() ?? '';
  if (startTrim.isEmpty && endTrim.isEmpty) return '';

  DateTime? parseLocal(String raw) {
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  final s = parseLocal(startTrim);
  final e = parseLocal(endTrim);

  String full(DateTime d) => DateFormat('d MMM yyyy').format(d);

  if (s != null && e != null) {
    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return full(s);
    }
    if (s.year == e.year && s.month == e.month) {
      return '${DateFormat('d').format(s)} – ${DateFormat('d MMM yyyy').format(e)}';
    }
    if (s.year == e.year) {
      return '${DateFormat('d MMM').format(s)} – ${DateFormat('d MMM yyyy').format(e)}';
    }
    return '${full(s)} – ${full(e)}';
  }
  if (s != null) return full(s);
  if (e != null) return full(e);

  return [
    if (startTrim.isNotEmpty) startTrim,
    if (endTrim.isNotEmpty) endTrim,
  ].join(' – ');
}

/// True when [endDateIso] parses and local **now** is strictly after that instant.
/// Missing or invalid dates → `false` (e.g. do not show “winner announced” yet).
bool isContestEndOverdue(String? endDateIso) {
  if (endDateIso == null || endDateIso.trim().isEmpty) return false;
  try {
    final end = DateTime.parse(endDateIso.trim()).toLocal();
    return DateTime.now().isAfter(end);
  } catch (_) {
    return false;
  }
}
