import 'package:musamimuk/core/network/api_utils.dart';

/// A user notification item from `GET /notifications`.
///
/// Backend may nest fields under `data` or flatten `title` / `message` on the
/// row — both shapes are accepted.
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

  String get title {
    final fromData = data['title']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) return fromData;
    final flat = raw['title']?.toString().trim();
    if (flat != null && flat.isNotEmpty) return flat;
    return type ?? '';
  }

  String get body {
    final fromData = data['message']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) return fromData;
    final body = data['body']?.toString().trim();
    if (body != null && body.isNotEmpty) return body;
    final flat = raw['message']?.toString().trim();
    if (flat != null && flat.isNotEmpty) return flat;
    return '';
  }

  String? get href {
    final fromData = data['href']?.toString();
    if (fromData != null && fromData.trim().isNotEmpty) return fromData;
    final flat = raw['href']?.toString();
    if (flat != null && flat.trim().isNotEmpty) return flat;
    return null;
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final d = json['data'];
    final nested = d is Map ? d.cast<String, dynamic>() : <String, dynamic>{};
    // If the API flattened title/message onto the row, keep them in [data]
    // so older UI that only reads data stays correct.
    final merged = <String, dynamic>{
      ...nested,
      if (json['title'] != null && nested['title'] == null)
        'title': json['title'],
      if (json['message'] != null && nested['message'] == null)
        'message': json['message'],
      if (json['href'] != null && nested['href'] == null) 'href': json['href'],
    };
    return NotificationItem(
      id: apiParseString(json['id']),
      type: json['type']?.toString(),
      data: merged,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      raw: json,
    );
  }
}
