import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/contest_item.dart';
import 'package:musamimuk/data/models/media_item.dart';

/// Parsed response from `GET /search?q=...`.
///
/// The v1 collection documents a grouped response where blocks may include
/// designs, contests, shapes, logos, pngs, and (for admins) users.
class GlobalSearchResult {
  final List<MediaItem> designs;
  final List<ContestItem> contests;
  final List<MediaItem> shapes;
  final List<MediaItem> logos;
  final List<MediaItem> pngs;

  /// Raw block for admin-only users list (kept untyped for now).
  final List<Map<String, dynamic>> usersRaw;

  const GlobalSearchResult({
    this.designs = const [],
    this.contests = const [],
    this.shapes = const [],
    this.logos = const [],
    this.pngs = const [],
    this.usersRaw = const [],
  });

  static List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  factory GlobalSearchResult.fromEnvelope(Map<String, dynamic> json) {
    final db = apiExtractDbData(json);
    final data = db is Map ? db.cast<String, dynamic>() : json;

    final designs = _asMapList(data['designs']).map(MediaItem.fromJson).toList();
    final contests =
        _asMapList(data['contests']).map(ContestItem.fromJson).toList();
    final shapes = _asMapList(data['shapes']).map(MediaItem.fromJson).toList();
    final logos = _asMapList(data['logos']).map(MediaItem.fromJson).toList();
    final pngs = _asMapList(data['pngs']).map(MediaItem.fromJson).toList();
    final users = _asMapList(data['users']);

    return GlobalSearchResult(
      designs: designs,
      contests: contests,
      shapes: shapes,
      logos: logos,
      pngs: pngs,
      usersRaw: users,
    );
  }
}

