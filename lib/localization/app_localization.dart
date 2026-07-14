import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/app_locale_notifier.dart';
import '../core/utils/navigator_service.dart';
import 'ar/ar_translations.dart';
import 'en_us/en_us_translations.dart';

extension LocalizationExtension on String {
  /// Resolves via [AppLocalization.activeLanguageCode] (prefs + device list).
  String get tr => AppLocalization.translate(this);
}

class AppLocalization {
  AppLocalization(this.locale);
  Locale locale;
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': enUs,
    'ar': arSa,
  };

  /// Set from [MaterialApp.builder] — sits under [Localizations] so lookups
  /// match the current app locale. Do not use [NavigatorService.navigatorKey]
  /// alone: route widgets would not rebuild when locale changes.
  static BuildContext? materialAppBuilderContext;

  static void setMaterialAppBuilderContext(BuildContext context) {
    materialAppBuilderContext = context;
  }

  static AppLocalization of() {
    final ctx =
        materialAppBuilderContext ??
        NavigatorService.navigatorKey.currentContext!;
    return Localizations.of<AppLocalization>(ctx, AppLocalization)!;
  }

  static List<String> languages() => _localizedValues.keys.toList();

  /// Same algorithm as [MaterialApp.localeListResolutionCallback] for our
  /// [supportedLocales] — must not use only [PlatformDispatcher.locale] or
  /// device language order can disagree with layout direction.
  static Locale resolveMatchingLocale(
    List<Locale>? locales,
    List<Locale> supported,
  ) {
    for (final deviceLocale in locales ?? const <Locale>[]) {
      for (final s in supported) {
        if (s.languageCode == deviceLocale.languageCode) {
          return s;
        }
      }
    }
    return const Locale('en');
  }

  /// Active UI language: saved choice, else first supported match in the
  /// platform locale list (same as [resolveMatchingLocale]), else English.
  static String activeLanguageCode() {
    final pref = appLocaleNotifier.languageCode;
    if (pref == 'ar' || pref == 'en') return pref!;
    try {
      return resolveMatchingLocale(
        WidgetsBinding.instance.platformDispatcher.locales,
        const [Locale('en'), Locale('ar')],
      ).languageCode;
    } catch (_) {
      return 'en';
    }
  }

  /// Map lookup from [activeLanguageCode] only.
  ///
  /// Do **not** override with [Localizations.localeOf] using
  /// [materialAppBuilderContext] from [MaterialApp.builder]: that [BuildContext]
  /// is often **above** this app's [Localizations] scope, so it resolves to the
  /// platform default (e.g. `en`) and would overwrite an explicit `ar`/`en`
  /// choice from [appLocaleNotifier].
  static String translate(String text) {
    final code = activeLanguageCode();
    final map = _localizedValues[code] ?? _localizedValues['en']!;
    return map[text] ?? _localizedValues['en']![text] ?? text;
  }

  String getString(String text) => translate(text);
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();
  @override
  bool isSupported(Locale locale) =>
      AppLocalization.languages().contains(locale.languageCode);
  //Returning a SynchronousFuture here because an async "load" operation//cause an async "load" operation
  @override
  Future<AppLocalization> load(Locale locale) {
    return SynchronousFuture<AppLocalization>(AppLocalization(locale));
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => true;
}
