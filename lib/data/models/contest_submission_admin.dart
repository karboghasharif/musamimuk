import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

/// Row from `GET /admin/contests/{id}/submissions` (shape may vary by backend).
class ContestSubmissionAdmin {
  const ContestSubmissionAdmin({
    required this.id,
    this.contestId,
    this.status,
    this.adminNotes,
    this.design,
    this.submitterName,
    this.userId,
  });

  final int id;
  final int? contestId;
  final String? status;
  final String? adminNotes;
  final MediaItem? design;
  final String? submitterName;
  final int? userId;

  factory ContestSubmissionAdmin.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String? name;
    int? uid;
    if (user is Map) {
      final m = user.cast<String, dynamic>();
      final n = apiParseString(m['name']).trim();
      name = n.isEmpty ? null : n;
      uid = m['id'] == null ? null : apiParseInt(m['id']);
    }
    final designRaw = json['design'];
    return ContestSubmissionAdmin(
      id: apiParseInt(json['id']),
      contestId: json['contest_id'] == null ? null : apiParseInt(json['contest_id']),
      status: json['status']?.toString(),
      adminNotes: json['admin_notes']?.toString(),
      design: designRaw is Map
          ? MediaItem.fromJson(designRaw.cast<String, dynamic>())
          : null,
      submitterName: name,
      userId: uid ?? (json['user_id'] == null ? null : apiParseInt(json['user_id'])),
    );
  }
}
