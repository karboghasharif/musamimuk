import 'package:flutter/material.dart';
import '../core/app_export.dart';

LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

class ThemeHelper {
  final _appTheme = PrefUtils().getThemeData();
  final Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors()
  };
  final Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme
  };
  _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? LightCodeColors();
  }

  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      textTheme: TextThemes.textTheme(colorScheme),
      scaffoldBackgroundColor: appTheme.blueGray90007,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: appTheme.black900,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: colorScheme.primary,
      ),
    );
  }

  LightCodeColors themeColor() => _getThemeColors();
  ThemeData themeData() => _getThemeData();
}

class TextThemes {
  static TextTheme textTheme(ColorScheme colorScheme) => TextTheme(
        bodyLarge: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 17.fSize,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 13.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 11.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: appTheme.blueGray90004,
          fontSize: 37.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 30.fSize,
          fontFamily: 'Visby Round CF',
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 28.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
        labelLarge: TextStyle(
          color: appTheme.blueGray90004,
          fontSize: 12.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 11.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 20.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 18.fSize,
          fontFamily: 'Visby Round CF',
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: colorScheme.onPrimaryContainer.withOpacity(1),
          fontSize: 14.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      );
}

class ColorSchemes {
  static const lightCodeColorScheme = ColorScheme.light(
    primary: Color(0XFFF4DF08),
    primaryContainer: Color(0XFF512DA7),
    secondaryContainer: Color(0XFFF8D832),
    errorContainer: Color(0XFF8F8F8F),
    onError: Color(0X7FDEDEDE),
    onErrorContainer: Color(0XFF1305FF),
    onPrimary: Color(0XFF24282E),
    onPrimaryContainer: Color(0X19FFFFFF),
  );
}

class LightCodeColors {
  Color get amberA400 => const Color(0XFFCFBC00);
  Color get black900 => const Color(0XFF000000);
  Color get blue100 => const Color(0XFFBBDEFA);
  Color get blue300 => const Color(0XFF64B4F4);
  Color get blue500 => const Color(0XFF2196F3);
  Color get blue700 => const Color(0XFF1976D3);
  Color get blue900 => const Color(0XFF0E47A1);
  Color get blueGray100 => const Color(0XFFD9D9D9);
  Color get blueGray10001 => const Color(0XFFC9CACD);
  Color get blueGray300 => const Color(0XFF9FA7B7);
  Color get blueGray400 => const Color(0XFF888888);
  Color get blueGray700 => const Color(0XFF4B525B);
  Color get blueGray70001 => const Color(0XFF4C535B);
  Color get blueGray70002 => const Color(0XFF515559);
  Color get blueGray800 => const Color(0XFF324A5E);
  Color get blueGray900 => const Color(0XFF2F2E41);
  Color get blueGray90001 => const Color(0XFF2F353C);
  Color get blueGray90002 => const Color(0XFF2F353D);
  Color get blueGray90003 => const Color(0XFF25292F);
  Color get blueGray90004 => const Color(0XFF252A30);
  Color get blueGray90005 => const Color(0XFF2F343B);
  Color get blueGray90006 => const Color(0XFF323232);
  Color get blueGray90007 => const Color(0XFF24292F);
  Color get cyan100 => const Color(0XFFADF5FF);
  Color get cyan300 => const Color(0XFF4FCFE0);
  Color get cyan500 => const Color(0XFF00BCD5);
  Color get cyan700 => const Color(0XFF0098A6);
  Color get cyan900 => const Color(0XFF006162);
  Color get cyanA200 => const Color(0XFF03FDEE);
  Color get deepPurple100 => const Color(0XFFD0C4E8);
  Color get deepPurple300 => const Color(0XFF9675CE);
  Color get deepPurple500 => const Color(0XFF653CB4);
  Color get deepPurple900 => const Color(0XFF301B92);
  Color get gray100 => const Color(0XFFF3F3F3);
  Color get gray300 => const Color(0XFFE6E6E6);
  Color get gray400 => const Color(0XFFBDBDBD);
  Color get gray40001 => const Color(0XFFAFAFAF);
  Color get gray40002 => const Color(0XFFC6C6C6);
  Color get gray500 => const Color(0XFF939393);
  Color get gray50001 => const Color(0XFFA7A7A7);
  Color get gray50002 => const Color(0XFF9A9A9A);
  Color get gray700 => const Color(0XFF646464);
  Color get gray70001 => const Color(0XFF636363);
  Color get gray800 => const Color(0XFF353B42);
  Color get gray80001 => const Color(0XFF363C43);
  Color get gray80002 => const Color(0XFF3C3C3C);
  Color get gray80003 => const Color(0XFF46432C);
  Color get gray80004 => const Color(0XFF4B4B4B);
  Color get gray900 => const Color(0XFF130F26);
  Color get gray90001 => const Color(0XFF1D1D22);
  Color get gray90002 => const Color(0XFF181B1E);
  Color get gray90003 => const Color(0XFF4A093C);
  Color get gray90004 => const Color(0XFF212121);
  Color get gray90005 => const Color(0XFF131212);
  Color get gray90006 => const Color(0XFF1C1C1C);
  Color get gray8008b => const Color(0X8B404040);
  Color get green300 => const Color(0XFF82C682);
  Color get green500 => const Color(0XFF4CB050);
  Color get green700 => const Color(0XFF398E3D);
  Color get green900 => const Color(0XFF174D33);
  Color get greenA100 => const Color(0XFFB9FFB9);
  Color get greenA700 => const Color(0XFF10FF12);
  Color get indigo700 => const Color(0XFF385C8E);
  Color get lime300 => const Color(0XFFDEE676);
  Color get lime500 => const Color(0XFFCDDC39);
  Color get lime700 => const Color(0XFFB0B42B);
  Color get lime900 => const Color(0XFF8D8000);
  Color get lime90001 => const Color(0XFF817717);
  Color get limeA700 => const Color(0XFF9DCE0A);
  Color get orangeA100 => const Color(0XFFFFD782);
  Color get pink100 => const Color(0XFFF9BBD0);
  Color get pink300 => const Color(0XFFF06292);
  Color get pink50 => const Color(0XFFFFDAF7);
  Color get pink500 => const Color(0XFFEA1E63);
  Color get pink700 => const Color(0XFFC0195B);
  Color get pink900 => const Color(0XFF890E4E);
  Color get pink90001 => const Color(0XFF771061);
  Color get purple100 => const Color(0XFFE1BEE8);
  Color get purple300 => const Color(0XFFB968C7);
  Color get purple400 => const Color(0XFFDE23B5);
  Color get purple500 => const Color(0XFF9C28B1);
  Color get purple700 => const Color(0XFF7A1FA2);
  Color get purple900 => const Color(0XFF4A148C);
  Color get purpleA200 => const Color(0XFFFF4FD9);
  Color get purpleA400 => const Color(0XFFFA01E9);
  Color get red100 => const Color(0XFFFFCDD2);
  Color get red300 => const Color(0XFFE57373);
  Color get red500 => const Color(0XFFF44237);
  Color get red600 => const Color(0XFFDD2E44);
  Color get red700 => const Color(0XFFD32F2E);
  Color get red70001 => const Color(0XFFDF2C2C);
  Color get red900 => const Color(0XFFB31E1A);
  Color get red90001 => const Color(0XFF9B0000);
  Color get redA400 => const Color(0XFFFF2424);
  Color get redA40001 => const Color(0XFFF50A32);
  Color get redA700 => const Color(0XFFF30000);
  Color get redA70001 => const Color(0XFFFF0000);
  Color get redA70002 => const Color(0XFFC90000);
  Color get teal50 => const Color(0XFFE1E8ED);
  Color get yellow200 => const Color(0XFFF8FF9E);
  Color get yellow500 => const Color(0XFFFFEB29);
  Color get yellowA200 => const Color(0XFFF8FD03);
  Color get yellowA400 => const Color(0XFFE8E500);
}
