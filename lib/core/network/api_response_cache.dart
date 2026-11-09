import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Disk + memory cache for idempotent API GET JSON bodies.
///
/// Use via [ApiCacheInterceptor]. Do **not** cache auth, wallet, print, or
/// other mutating / highly personal endpoints.
class ApiResponseCache {
  ApiResponseCache._();
  static final ApiResponseCache instance = ApiResponseCache._();

  static const String _prefsPrefix = 'api_cache_v1:';
  static const int _maxDiskEntries = 80;

  final Map<String, _CacheEntry> _memory = {};

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  /// Fresh cached JSON map, or null if missing/expired.
  Future<Map<String, dynamic>?> read(String key) async {
    final mem = _memory[key];
    if (mem != null) {
      if (!mem.isExpired) return mem.data;
      _memory.remove(key);
    }

    final prefs = await _prefs;
    final raw = prefs.getString('$_prefsPrefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      final expiresAtMs = map['_expires_at_ms'];
      final payload = map['data'];
      if (expiresAtMs is! num || payload is! Map) {
        await prefs.remove('$_prefsPrefix$key');
        return null;
      }
      if (DateTime.now().millisecondsSinceEpoch > expiresAtMs.toInt()) {
        await prefs.remove('$_prefsPrefix$key');
        return null;
      }
      final data = payload.cast<String, dynamic>();
      _memory[key] = _CacheEntry(
        data: data,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs.toInt()),
      );
      return data;
    } catch (_) {
      await prefs.remove('$_prefsPrefix$key');
      return null;
    }
  }

  Future<void> write(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
  }) async {
    final expiresAt = DateTime.now().add(ttl);
    _memory[key] = _CacheEntry(data: data, expiresAt: expiresAt);
    final prefs = await _prefs;
    final envelope = <String, dynamic>{
      '_expires_at_ms': expiresAt.millisecondsSinceEpoch,
      'data': data,
    };
    await prefs.setString('$_prefsPrefix$key', jsonEncode(envelope));
    await _trimDiskIfNeeded(prefs);
  }

  /// Drops all entries, or only keys that start with [keyPrefix].
  Future<void> clear({String? keyPrefix}) async {
    if (keyPrefix == null) {
      _memory.clear();
      final prefs = await _prefs;
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith(_prefsPrefix))
          .toList(growable: false);
      for (final k in keys) {
        await prefs.remove(k);
      }
      return;
    }
    _memory.removeWhere((k, _) => k.startsWith(keyPrefix));
    final prefs = await _prefs;
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('$_prefsPrefix$keyPrefix'))
        .toList(growable: false);
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Clear user-scoped cache after logout (keys containing `|u:`).
  Future<void> clearUserScoped() async {
    _memory.removeWhere((k, _) => k.contains('|u:'));
    final prefs = await _prefs;
    final keys = prefs
        .getKeys()
        .where(
          (k) => k.startsWith(_prefsPrefix) && k.contains('|u:'),
        )
        .toList(growable: false);
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  Future<void> _trimDiskIfNeeded(SharedPreferences prefs) async {
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefsPrefix))
        .toList(growable: false);
    if (keys.length <= _maxDiskEntries) return;
    // Drop oldest by reading expiry when possible; otherwise first keys.
    keys.sort();
    final overflow = keys.length - _maxDiskEntries;
    for (var i = 0; i < overflow; i++) {
      await prefs.remove(keys[i]);
    }
  }
}

class _CacheEntry {
  _CacheEntry({required this.data, required this.expiresAt});
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
