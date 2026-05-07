import 'package:musamimuk/core/network/api_utils.dart';

/// A user notification item from `GET /notifications`.
///
/// The backend may return different shapes depending on Laravel notifications
/// storage; we keep parsing permissive and preserve unknown fields in [raw].
class NotificationItem {
  final String id;
  final String? type;
  final Map<String, dynamic> data;
  final String? readAt;
  final String? createdAt;
  final Map<String, dynamic> raw;

  const NotificationItem({
    required this.id,
    this.type,
    required this.data,
    this.readAt,
    this.createdAt,
    required this.raw,
  });

  bool get isRead => (readAt ?? '').trim().isNotEmpty;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final d = json['data'];
    return NotificationItem(
      id: apiParseString(json['id']),
      type: json['type']?.toString(),
      data: d is Map ? d.cast<String, dynamic>() : const <String, dynamic>{},
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      raw: json,
    );
  }
}

