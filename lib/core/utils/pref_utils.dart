import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Offset;
import 'package:shared_preferences/shared_preferences.dart';

import '../session/secure_token_storage.dart';

class PrefUtils {
  PrefUtils() {
    SharedPreferences.getInstance().then((value) {
      _sharedPreferences = value;
    });
  }
  static SharedPreferences? _sharedPreferences;
  static String? _tokenCache;

  Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    final secureStorage = SecureTokenStorage.instance;
    _tokenCache = await secureStorage.readToken();

    // One-time migration from legacy SharedPreferences token storage.
    final legacyToken = _sharedPreferences?.getString(_keyToken);
    if ((_tokenCache == null || _tokenCache!.isEmpty) &&
        legacyToken != null &&
        legacyToken.isNotEmpty) {
      await secureStorage.writeToken(legacyToken);
      _tokenCache = legacyToken;
    }
    await _sharedPreferences?.remove(_keyToken);
  }

  void clearPreferencesData() async {
    _sharedPreferences!.clear();
  }

  Future<void> setThemeData(String value) {
    return _sharedPreferences!.setString('themeData', value);
  }

  String getThemeData() {
    try {
      return _sharedPreferences!.getString('themeData')!;
    } catch (e) {
      return 'primary';
    }
  }

  static const String _keyToken = 'auth_token';
  static const String _keyUserSession = 'user_session';
  static const String _keyLanguageCode = 'language_code';
  static const String _keyRememberSession = 'remember_session';
  static const String _keySavedLoginEmail = 'saved_login_email';

  /// Stable per-install identifier used to start/resume a backend guest session.
  static const String _keyDeviceId = 'device_id';

  /// Local home access without API token: guest / google / apple
  /// (backend has no social OAuth exchange yet).
  static const String _keyOfflineHomeKind = 'offline_home_kind';

  static const String offlineHomeKindGuest = 'guest';
  static const String offlineHomeKindGoogle = 'google';
  static const String offlineHomeKindApple = 'apple';

  /// When `false`, a cold start clears persisted auth so the user must sign in again.
  /// Defaults to `true` when unset so existing installs keep their session.
  Future<void> setRememberSession(bool value) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.setBool(_keyRememberSession, value);
  }

  bool getRememberSession() {
    try {
      return _sharedPreferences?.getBool(_keyRememberSession) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Last email used with "Remember me" (optional pre-fill on the login screen).
  Future<void> setSavedLoginEmail(String? email) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    if (email == null || email.isEmpty) {
      await prefs.remove(_keySavedLoginEmail);
    } else {
      await prefs.setString(_keySavedLoginEmail, email);
    }
  }

  String? getSavedLoginEmail() {
    try {
      final e = _sharedPreferences?.getString(_keySavedLoginEmail);
      if (e == null || e.isEmpty) return null;
      return e;
    } catch (_) {
      return null;
    }
  }

  /// Persists app UI language: `'en'`, `'ar'`, or clear with [clearLanguageCode].
  /// When unset, [MaterialApp] follows the device locale.
  Future<void> setLanguageCode(String code) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.setString(_keyLanguageCode, code);
  }

  Future<void> clearLanguageCode() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.remove(_keyLanguageCode);
  }

  /// `'en'` / `'ar'` if the user chose a language, else `null` (use device locale).
  String? getLanguageCode() {
    try {
      final c = _sharedPreferences?.getString(_keyLanguageCode);
      if (c == null || c.isEmpty) return null;
      return c;
    } catch (_) {
      return null;
    }
  }

  Future<void> setToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      await removeToken();
      return;
    }
    await SecureTokenStorage.instance.writeToken(normalized);
    _tokenCache = normalized;
  }

  String? getToken() {
    return _tokenCache;
  }

  /// Whether a non-empty auth token is stored (user can call authenticated APIs).
  bool isLoggedIn() {
    final t = getToken();
    return t != null && t.isNotEmpty;
  }

  /// Admin middleware roles from API docs (e.g. `1` or `3`).
  bool isAdminRole() {
    final s = getUserSession();
    if (s == null) return false;
    final r = s['role_id'];
    final id = r is int ? r : int.tryParse(r?.toString() ?? '');
    return id == 1 || id == 3;
  }

  /// Returns a stable device id for guest sessions, generating and persisting
  /// one on first use. Survives logout ([clearAuth]); reset only on reinstall.
  Future<String> getOrCreateDeviceId() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    final existing = prefs.getString(_keyDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateUuidV4();
    await prefs.setString(_keyDeviceId, id);
    return id;
  }

  /// RFC-4122 v4 UUID from a cryptographically secure RNG (no extra package).
  static String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// Guest or Google-offline session: home and editor work; cloud APIs stay gated by [isLoggedIn].
  String? getOfflineHomeKind() {
    try {
      final k = _sharedPreferences?.getString(_keyOfflineHomeKind);
      if (k == null || k.isEmpty) return null;
      return k;
    } catch (_) {
      return null;
    }
  }

  bool hasOfflineHomeAccess() {
    final k = getOfflineHomeKind();
    return k == offlineHomeKindGuest ||
        k == offlineHomeKindGoogle ||
        k == offlineHomeKindApple;
  }

  /// True when the current session is a guest.
  ///
  /// Prefers the backend `is_guest` flag (role_id 4) from the stored user, and
  /// falls back to the legacy local guest marker for older sessions.
  bool isGuestAccount() {
    final s = getUserSession();
    if (s != null) {
      final flag = s['is_guest'];
      if (flag is bool) return flag;
      if (flag != null) {
        final t = flag.toString().toLowerCase();
        if (t == 'true' || t == '1') return true;
        if (t == 'false' || t == '0') return false;
      }
      final r = s['role_id'];
      final id = r is int ? r : int.tryParse(r?.toString() ?? '');
      if (id == 4) return true;
      if (s['role']?.toString().toLowerCase() == 'guest') return true;
    }
    return getOfflineHomeKind() == offlineHomeKindGuest;
  }

  Future<void> clearOfflineHomeSession() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.remove(_keyOfflineHomeKind);
  }

  /// Marks the local offline-home kind as guest (used by the backend guest
  /// session so splash / offline gates keep working alongside the real token).
  Future<void> markGuestOfflineHome() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.setString(_keyOfflineHomeKind, offlineHomeKindGuest);
  }

  /// Continues as guest: no bearer token; minimal profile for UI.
  Future<void> setGuestOfflineHomeSession(String localizedGuestName) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await removeToken();
    await clearUserSession();
    await prefs.setString(_keyOfflineHomeKind, offlineHomeKindGuest);
    await setUserSession({'id': 0, 'name': localizedGuestName, 'email': ''});
  }

  /// After Google sign-in when the API cannot exchange tokens yet: local profile only.
  Future<void> setGoogleOfflineHomeSession({
    required String? displayName,
    required String? email,
    String? photoUrl,
  }) {
    return setSocialOfflineHomeSession(
      kind: offlineHomeKindGoogle,
      fallbackName: 'Google',
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
    );
  }

  /// After Apple sign-in when the API cannot exchange tokens yet: local profile only.
  Future<void> setAppleOfflineHomeSession({
    required String? displayName,
    required String? email,
  }) {
    return setSocialOfflineHomeSession(
      kind: offlineHomeKindApple,
      fallbackName: 'Apple',
      displayName: displayName,
      email: email,
    );
  }

  /// Shared offline social session (no bearer token until backend OAuth exists).
  Future<void> setSocialOfflineHomeSession({
    required String kind,
    required String fallbackName,
    required String? displayName,
    required String? email,
    String? photoUrl,
  }) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await removeToken();
    await clearUserSession();
    await prefs.setString(_keyOfflineHomeKind, kind);
    final name = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (email?.trim().isNotEmpty == true ? email!.trim() : null);
    final resolvedName =
        (name != null && name.isNotEmpty) ? name : fallbackName;
    await setUserSession({
      'id': 0,
      'name': resolvedName,
      'email': email?.trim().isNotEmpty == true ? email!.trim() : null,
      'image': photoUrl?.trim().isNotEmpty == true ? photoUrl!.trim() : null,
      'auth_provider': kind,
    });
  }

  /// Whether we have a persisted user profile map (from login/register).
  bool hasUserProfile() {
    final s = getUserSession();
    return s != null && s.isNotEmpty;
  }

  Future<void> removeToken() async {
    await SecureTokenStorage.instance.deleteToken();
    _tokenCache = null;
    await _sharedPreferences?.remove(_keyToken);
  }

  /// Saves user session (from login or register). Pass a map with id, name, email, etc.
  Future<void> setUserSession(Map<String, dynamic> userJson) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    final encoded = _encodeSession(userJson);
    if (encoded != null) await prefs.setString(_keyUserSession, encoded);
  }

  /// Returns stored user session as a map, or null if none.
  Map<String, dynamic>? getUserSession() {
    try {
      final encoded = _sharedPreferences?.getString(_keyUserSession);
      return _decodeSession(encoded);
    } catch (e) {
      return null;
    }
  }

  /// Clears user session (e.g. on logout). Also use [removeToken] to clear token.
  Future<void> clearUserSession() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.remove(_keyUserSession);
  }

  /// Clears auth token and user session (full logout).
  Future<void> clearAuth() async {
    await removeToken();
    await clearUserSession();
    await clearOfflineHomeSession();
  }

  static const String _keyEditorFabDx = 'editor_fab_dx';
  static const String _keyEditorFabDy = 'editor_fab_dy';

  /// Last user-dragged position of the editor AI FAB (logical pixels).
  Offset? getEditorFabOffset() {
    try {
      final dx = _sharedPreferences?.getDouble(_keyEditorFabDx);
      final dy = _sharedPreferences?.getDouble(_keyEditorFabDy);
      if (dx == null || dy == null) return null;
      return Offset(dx, dy);
    } catch (_) {
      return null;
    }
  }

  Future<void> setEditorFabOffset(Offset offset) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.setDouble(_keyEditorFabDx, offset.dx);
    await prefs.setDouble(_keyEditorFabDy, offset.dy);
  }

  static String? _encodeSession(Map<String, dynamic> json) {
    try {
      final sanitized = <String, dynamic>{};
      for (final e in json.entries) {
        if (e.value != null) sanitized[e.key] = e.value;
      }
      return jsonEncode(sanitized);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _decodeSession(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return jsonDecode(encoded) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
