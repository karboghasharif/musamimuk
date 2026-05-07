library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart' show baseUrl;

/// Small helpers for parsing common musamimuk API response shapes.
///
/// Many endpoints respond with:
/// - { "status": "success|error", "message": "...", "dbData": ... }
/// while others may return:
/// - { "message": "...", "data": ... }
/// - { "errors": { field: ["..."] } }

int apiParseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

String apiParseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final s = value.toString();
  return s;
}

bool? apiParseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return null;
}

/// Site origin for building absolute URLs from relative `file_path` values.
String apiSiteOrigin() {
  final u = Uri.parse(baseUrl);
  final port = u.hasPort ? ':${u.port}' : '';
  return '${u.scheme}://${u.host}$port';
}

/// Resolves `file_url` or `file_path` from design/media JSON to a loadable URL.
String apiResolveDesignFileUrl(Map<String, dynamic> json) {
  final fileUrl = json['file_url']?.toString().trim();
  if (fileUrl != null && fileUrl.isNotEmpty) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return normalizePublicStorageUrl(fileUrl);
    }
  }
  final filePath = json['file_path']?.toString().trim();
  if (filePath == null || filePath.isEmpty) {
    if (fileUrl != null && fileUrl.isNotEmpty) {
      return normalizePublicStorageUrl(fileUrl);
    }
    return '';
  }
  if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
    return normalizePublicStorageUrl(filePath);
  }
  final origin = apiSiteOrigin();
  final clean = filePath.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('public/')) {
    return normalizePublicStorageUrl('$origin/$clean');
  }
  return normalizePublicStorageUrl('$origin/public/$clean');
}

/// Laravel public disk URLs are served under `/public/storage/...` on the site root.
/// APIs often return `https://host/storage/...`; map those to `https://host/public/storage/...`.
///
/// No-op if the URL is empty, already contains `public/storage`, or has no `/storage/` segment.
String normalizePublicStorageUrl(String url) {
  final s = url.trim();
  if (s.isEmpty) return s;
  final lower = s.toLowerCase();
  if (lower.contains('/public/storage')) return s;

  const needle = '/storage/';
  final i = s.indexOf(needle);
  if (i >= 0) {
    return '${s.substring(0, i)}/public${s.substring(i)}';
  }
  if (lower.startsWith('storage/')) {
    return 'public/$s';
  }
  return s;
}

String? apiExtractMessage(dynamic data) {
  if (data is! Map) return null;
  final map = data.cast<String, dynamic>();
  final message =
      map['message'] ??
      map['Message'] ??
      map['msg'] ??
      map['descriptionMessage'] ??
      map['error'] ??
      map['errorDescription'] ??
      map['error_description'];
  if (message != null) return message.toString();

  final errors = map['errors'];
  if (errors is Map && errors.isNotEmpty) {
    try {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    } catch (_) {
      return null;
    }
  }
  return null;
}

dynamic apiExtractDbData(dynamic data) {
  if (data is! Map) return null;
  final map = data.cast<String, dynamic>();
  if (map.containsKey('dbData')) return map['dbData'];
  if (map.containsKey('data')) return map['data'];
  return null;
}

List<Map<String, dynamic>> apiExtractDbDataList(dynamic data) {
  final dbData = apiExtractDbData(data);
  if (dbData is List) {
    return dbData
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }
  return const [];
}

/// Prefer server [message] over Dio's long generic text; handle 401 clearly.
String apiMessageFromDioException(DioException e) {
  final raw = e.response?.data;
  String? fromBody = apiExtractMessage(raw);
  if (fromBody == null && raw is String && raw.isNotEmpty) {
    try {
      fromBody = apiExtractMessage(jsonDecode(raw));
    } catch (_) {}
  }
  if (fromBody != null && fromBody.isNotEmpty) {
    if (e.response?.statusCode == 401) {
      return '$fromBody Please sign in again.';
    }
    return fromBody;
  }
  if (e.response?.statusCode == 401) {
    return 'Session expired or unauthorized. Please sign in again.';
  }
  return e.message ?? 'Network error';
}

