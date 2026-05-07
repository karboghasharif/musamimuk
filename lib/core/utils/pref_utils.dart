import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  PrefUtils() {
    SharedPreferences.getInstance().then((value) {
      _sharedPreferences = value;
    });
  }
  static SharedPreferences? _sharedPreferences;
  Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    print('SharedPreference Initialized');
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
  /// Local home access without API token: `guest` or `google` (server has no Google OAuth yet).
  static const String _keyOfflineHomeKind = 'offline_home_kind';

  static const String offlineHomeKindGuest = 'guest';
  static const String offlineHomeKindGoogle = 'google';

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
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.setString(_keyToken, token);
  }

  String? getToken() {
    try {
      return _sharedPreferences?.getString(_keyToken);
    } catch (e) {
      return null;
    }
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
    return k == offlineHomeKindGuest || k == offlineHomeKindGoogle;
  }

  Future<void> clearOfflineHomeSession() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.remove(_keyOfflineHomeKind);
  }

  /// Continues as guest: no bearer token; minimal profile for UI.
  Future<void> setGuestOfflineHomeSession(String localizedGuestName) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await removeToken();
    await clearUserSession();
    await prefs.setString(_keyOfflineHomeKind, offlineHomeKindGuest);
    await setUserSession({
      'id': 0,
      'name': localizedGuestName,
      'email': '',
    });
  }

  /// After Google sign-in when the API cannot exchange tokens yet: local profile only.
  Future<void> setGoogleOfflineHomeSession({
    required String? displayName,
    required String? email,
    String? photoUrl,
  }) async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await removeToken();
    await clearUserSession();
    await prefs.setString(_keyOfflineHomeKind, offlineHomeKindGoogle);
    final name = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (email?.trim().isNotEmpty == true ? email!.trim() : null);
    final resolvedName = (name != null && name.isNotEmpty) ? name : 'Google';
    await setUserSession({
      'id': 0,
      'name': resolvedName,
      'email': email?.trim().isNotEmpty == true ? email!.trim() : null,
      'image': photoUrl?.trim().isNotEmpty == true ? photoUrl!.trim() : null,
    });
  }

  /// Whether we have a persisted user profile map (from login/register).
  bool hasUserProfile() {
    final s = getUserSession();
    return s != null && s.isNotEmpty;
  }

  Future<void> removeToken() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    _sharedPreferences ??= prefs;
    await prefs.remove(_keyToken);
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
