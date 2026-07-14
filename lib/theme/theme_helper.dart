import 'package:flutter/material.dart';

import '../core/design_system/app_design_tokens.dart';
import '../core/utils/pref_utils.dart';
import '../core/utils/size_utils.dart';

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
    final radius = BorderRadius.circular(AppDs.radiusLg);
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      textTheme: TextThemes.textTheme(colorScheme),
      scaffoldBackgroundColor: AppDs.surfaceBase,
      canvasColor: AppDs.surfaceBase,
      cardColor: AppDs.surfaceRaised,
      dividerColor: Colors.white.withValues(alpha: 0.1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: AppDs.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.5),
          minimumSize: Size(0, AppDs.buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4,
            vertical: AppDs.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: TextStyle(
            fontSize: AppDs.fontBody,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: Size(0, AppDs.buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4,
            vertical: AppDs.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDs.textOnDarkPrimary,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.2,
          ),
          minimumSize: Size(0, AppDs.buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4,
            vertical: AppDs.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space3,
            vertical: AppDs.space2,
          ),
          textStyle: TextStyle(
            fontSize: AppDs.fontBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDs.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDs.space4,
          vertical: AppDs.space3,
        ),
        hintStyle: TextStyle(
          color: AppDs.textOnDarkSecondary,
          fontSize: AppDs.fontBody,
        ),
        labelStyle: TextStyle(
          color: AppDs.textOnDarkSecondary,
          fontSize: AppDs.fontSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppDs.surfaceElevated,
        selectedColor: colorScheme.primary.withValues(alpha: 0.22),
        labelStyle: TextStyle(
          color: AppDs.textOnDarkSecondary,
          fontSize: AppDs.fontSecondary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: AppDs.textOnDarkPrimary,
          fontSize: AppDs.fontSecondary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDs.space2,
          vertical: AppDs.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusFull),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusLg),
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: Colors.white.withValues(alpha: 0.1),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppDs.surfaceBase,
        foregroundColor: AppDs.textOnDarkPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppDs.textOnDarkPrimary,
          fontSize: AppDs.fontSectionTitle,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  LightCodeColors themeColor() => _getThemeColors();
  ThemeData themeData() => _getThemeData();
}

class TextThemes {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final primary = AppDs.textOnDarkPrimary;
    final secondary = AppDs.textOnDarkSecondary;
    return TextTheme(
      displaySmall: TextStyle(
        color: primary,
        fontSize: 32.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      headlineLarge: TextStyle(
        color: primary,
        fontSize: 30.fSize,
        fontFamily: 'Visby Round CF',
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 28.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 20.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 17.fSize,
        fontFamily: 'Visby Round CF',
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 15.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        color: primary,
        fontSize: 16.fSize,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: primary,
        fontSize: 15.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: secondary,
        fontSize: 13.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 14.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 12.fSize,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
  }
}

class ColorSchemes {
  static const lightCodeColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF4DF08),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF512DA7),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFF4DF08),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF2F353D),
    onSecondaryContainer: Color(0xFFFFFFFF),
    surface: Color(0xFF252A30),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF9FA7B8),
    outline: Color(0xFF4B525B),
    outlineVariant: Color(0xFF2F353D),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFF5C2B2B),
    onErrorContainer: Color(0xFFF0F2F5),
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
