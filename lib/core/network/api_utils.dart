library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart' show baseUrl;
import 'package:musamimuk/localization/app_localization.dart';

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

/// Resolves `file_url`, `image_url`, or `file_path` from JSON to a loadable URL.
String apiResolveDesignFileUrl(Map<String, dynamic> json) {
  String resolveToAbsolute(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final origin = apiSiteOrigin();
    final clean = trimmed.replaceFirst(RegExp(r'^/+'), '');
    return '$origin/$clean';
  }

  for (final key in [
    'file_url',
    'image_url',
    'banner_url',
    'thumbnail_url',
    'file_path',
  ]) {
    final raw = json[key]?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return resolveToAbsolute(raw);
    }
  }

  return '';
}

/// Legacy helper kept for call sites; server files are served at `/storage/...`.
String normalizePublicStorageUrl(String url) => url.trim();

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

/// True when the envelope indicates success (`success: true` or legacy `status`).
bool apiResponseIsSuccess(Map<String, dynamic> map) {
  final success = map['success'];
  if (success == true) return true;
  final status = map['status'];
  if (status == true || status == 'success') return true;
  return false;
}

/// Inner object from `data` / `dbData` when it is a map.
Map<String, dynamic>? apiExtractPayloadMap(dynamic data) {
  if (data is! Map) return null;
  final payload = apiExtractDbData(data);
  if (payload is Map) return payload.cast<String, dynamic>();
  return null;
}

/// Optional `meta` object from the unified API envelope.
Map<String, dynamic>? apiExtractMetaMap(dynamic data) {
  if (data is! Map) return null;
  final meta = data['meta'];
  if (meta is Map) return meta.cast<String, dynamic>();
  return null;
}

/// List payload from unified APIs (`data: [...]`) or legacy `dbData` lists.
List<Map<String, dynamic>> apiExtractDataList(dynamic data) {
  if (data is! Map) return const [];
  final map = data.cast<String, dynamic>();
  final payload = map['data'] ?? map['dbData'];
  if (payload is List) {
    return payload
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }
  return apiExtractDbDataList(map);
}

/// Prefer friendly, centralized messages over raw Dio / server text.
///
/// Handles 401 / 403 / 404 / 422 / 5xx, network failures, and timeouts.
String apiMessageFromDioException(DioException e) {
  final status = e.response?.statusCode;
  final bodyMessage = _friendlyBodyMessage(e.response?.data);

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return _apiErrorText('msg_error_timeout');
    case DioExceptionType.cancel:
      return _apiErrorText('msg_error_request_cancelled');
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return _apiErrorText('msg_error_network');
    case DioExceptionType.badResponse:
      return _apiErrorForStatus(status, bodyMessage);
    case DioExceptionType.unknown:
      if (e.error != null &&
          e.error.toString().toLowerCase().contains('socket')) {
        return _apiErrorText('msg_error_network');
      }
      return bodyMessage ?? _apiErrorText('msg_error_unknown');
  }
}

String _apiErrorForStatus(int? status, String? bodyMessage) {
  switch (status) {
    case 401:
      return bodyMessage?.isNotEmpty == true
          ? bodyMessage!
          : _apiErrorText('msg_session_expired');
    case 402:
      return bodyMessage?.isNotEmpty == true
          ? bodyMessage!
          : _apiErrorText('msg_insufficient_coins');
    case 403:
      return bodyMessage?.isNotEmpty == true
          ? bodyMessage!
          : _apiErrorText('msg_error_forbidden');
    case 404:
      return bodyMessage?.isNotEmpty == true
          ? bodyMessage!
          : _apiErrorText('msg_error_not_found');
    case 422:
      return bodyMessage?.isNotEmpty == true
          ? bodyMessage!
          : _apiErrorText('msg_error_validation');
    case 429:
      return bodyMessage?.isNotEmpty == true
          ? bodyMessage!
          : _apiErrorText('msg_error_too_many_requests');
    case 500:
    case 502:
    case 503:
    case 504:
      return bodyMessage?.isNotEmpty == true
          ? bodyMessage!
          : _apiErrorText('msg_error_server');
    default:
      if (bodyMessage != null && bodyMessage.isNotEmpty) return bodyMessage;
      return _apiErrorText('msg_error_unknown');
  }
}

String? _friendlyBodyMessage(dynamic data) {
  final extracted = apiExtractMessage(data);
  if (extracted != null && extracted.trim().isNotEmpty) {
    return _sanitizeApiMessage(extracted.trim());
  }
  if (data is String && data.trim().isNotEmpty) {
    try {
      final parsed = apiExtractMessage(jsonDecode(data));
      if (parsed != null && parsed.trim().isNotEmpty) {
        return _sanitizeApiMessage(parsed.trim());
      }
    } catch (_) {
      if (data.length < 160 && !data.contains('<')) {
        return _sanitizeApiMessage(data.trim());
      }
    }
  }
  return null;
}

String _sanitizeApiMessage(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('sqlstate') ||
      lower.contains('stack trace') ||
      (lower.contains('exception') && lower.contains('at '))) {
    return _apiErrorText('msg_error_server');
  }
  return message;
}

String _apiErrorText(String key) {
  try {
    final translated = AppLocalization.translate(key);
    if (translated != key) return translated;
  } catch (_) {}
  return switch (key) {
    'msg_session_expired' =>
      'Your session has expired. Please log in again.',
    'msg_insufficient_coins' => 'Not enough coins.',
    'msg_error_forbidden' =>
      'You do not have permission to perform this action.',
    'msg_error_not_found' => 'The requested resource was not found.',
    'msg_error_validation' => 'Please check your input and try again.',
    'msg_error_server' =>
      'Something went wrong on our side. Please try again.',
    'msg_error_network' =>
      'Unable to connect. Check your internet connection.',
    'msg_error_timeout' => 'The request timed out. Please try again.',
    'msg_error_too_many_requests' =>
      'Too many requests. Please wait a moment and try again.',
    'msg_error_request_cancelled' => 'Request cancelled.',
    _ => 'Something went wrong. Please try again.',
  };
}

