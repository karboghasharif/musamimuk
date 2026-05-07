import 'package:flutter/foundation.dart';

import 'utils/pref_utils.dart';

/// Fires when the user changes language in settings so [MaterialApp] rebuilds.
final AppLocaleNotifier appLocaleNotifier = AppLocaleNotifier();

class AppLocaleNotifier extends ChangeNotifier {
  /// Mirrors prefs so [MaterialApp.locale] updates synchronously in the same
  /// frame as [notifyListeners] (avoids reading prefs before write flushes).
  String? _languageCode;

  /// Bumped only when the user picks a language (not on [syncFromPrefs]) so
  /// [MaterialApp] can remount and apply RTL + fresh route widgets.
  int _localeRevision = 0;

  AppLocaleNotifier() {
    _languageCode = PrefUtils().getLanguageCode();
  }

  /// Call after [PrefUtils.init] so prefs are loaded before [runApp].
  void syncFromPrefs() {
    _languageCode = PrefUtils().getLanguageCode();
    notifyListeners();
  }

  /// Current override: `en`, `ar`, or `null` (follow device).
  String? get languageCode => _languageCode;

  int get localeRevision => _localeRevision;

  Future<void> setLanguageCode(String? code) async {
    final prefs = PrefUtils();
    if (code == null) {
      await prefs.clearLanguageCode();
    } else {
      await prefs.setLanguageCode(code);
    }
    _languageCode = prefs.getLanguageCode();
    _localeRevision++;
    notifyListeners();
  }
}
