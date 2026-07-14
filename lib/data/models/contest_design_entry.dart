import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/contest_winner_admin.dart';
import 'package:musamimuk/data/models/media_item.dart';

/// Accepted design or winner row for contest detail UI.
class ContestDesignEntry {
  const ContestDesignEntry({
    required this.design,
    this.position,
    this.displayName,
  });

  final MediaItem design;
  final int? position;
  final String? displayName;

  static List<ContestDesignEntry> fromWinners(List<ContestWinnerAdmin> winners) {
    final sorted = List<ContestWinnerAdmin>.from(winners)
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted
        .where((winner) => winner.design != null)
        .map(
          (winner) => ContestDesignEntry(
            design: winner.design!,
            position: winner.position > 0 ? winner.position : null,
            displayName: _firstNonEmpty([
              winner.userName,
              winner.design?.creatorName,
            ]),
          ),
        )
        .toList();
  }

  static List<ContestDesignEntry> fromAcceptedPayload(List<dynamic> rawList) {
    return rawList.whereType<Map>().map((row) {
      final json = row.cast<String, dynamic>();
      final designJson = json['design'] is Map
          ? (json['design'] as Map).cast<String, dynamic>()
          : json;
      final design = MediaItem.fromJson(designJson);

      int? position;
      final positionRaw = json['position'] ?? json['rank'];
      if (positionRaw != null) {
        final parsed = apiParseInt(positionRaw);
        if (parsed > 0) position = parsed;
      }

      String? displayName = _firstNonEmpty([design.creatorName, design.name]);
      final user = json['user'];
      if (user is Map) {
        final name = apiParseString(user['name']).trim();
        if (name.isNotEmpty) displayName = name;
      }
      final submitter = apiParseString(json['submitter_name']).trim();
      if (submitter.isNotEmpty) displayName = submitter;

      return ContestDesignEntry(
        design: design,
        position: position,
        displayName: displayName,
      );
    }).toList();
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
