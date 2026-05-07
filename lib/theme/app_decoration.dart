import 'package:flutter/material.dart';
import '../core/app_export.dart';

class AppDecoration {
  static BoxDecoration get fillAmberA => BoxDecoration(
        color: appTheme.amberA400,
      );
  static BoxDecoration get fillBlueGray => BoxDecoration(
        color: appTheme.blueGray90007,
      );
  static BoxDecoration get fillBluegray90001 => BoxDecoration(
        color: appTheme.blueGray90001,
      );
  static BoxDecoration get fillBluegray90002 => BoxDecoration(
        color: appTheme.blueGray90002,
      );
  static BoxDecoration get fillBluegray90004 => BoxDecoration(
        color: appTheme.blueGray90004,
      );
  static BoxDecoration get fillBluegray90005 => BoxDecoration(
        color: appTheme.blueGray90005,
      );
  static BoxDecoration get fillGray => BoxDecoration(
        color: appTheme.gray100,
      );
  static BoxDecoration get fillGray800 => BoxDecoration(
        color: appTheme.gray800,
      );
  static BoxDecoration get fillGray80001 => BoxDecoration(
        color: appTheme.gray80001,
      );
  static BoxDecoration get fillGray90002 => BoxDecoration(
        color: appTheme.gray90002,
      );
  static BoxDecoration get fillIndigo => BoxDecoration(
        color: appTheme.indigo700,
      );
  static BoxDecoration get fillOnPrimaryContainer => BoxDecoration(
        color: theme.colorScheme.onPrimaryContainer.withOpacity(1),
      );
  static BoxDecoration get fillOnPrimaryContainer1 => BoxDecoration(
        color: theme.colorScheme.onPrimaryContainer,
      );
  static BoxDecoration get fillPrimary => BoxDecoration(
        color: theme.colorScheme.primary,
      );
  static BoxDecoration get fillYellow => BoxDecoration(
        color: appTheme.yellow500,
      );
  static BoxDecoration get fillYellowA => BoxDecoration(
        color: appTheme.yellowA400,
      );
  static BoxDecoration get gradientBlackToRedA => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.48, 1),
          end: const Alignment(0.47, 0),
          colors: [appTheme.black900, appTheme.redA70001.withOpacity(0)],
        ),
      );
  static BoxDecoration get gradientGrayToGray => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.5, 0),
          end: const Alignment(0.5, 1),
          colors: [appTheme.gray90006, appTheme.gray90004],
        ),
      );
  static BoxDecoration get gradientRedAToRedA => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0, 0.53),
          end: const Alignment(1, 0.53),
          colors: [appTheme.redA70001, appTheme.cyanA200, appTheme.redA40001],
        ),
      );
  static BoxDecoration get gradientRedAToRedA40001 => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0, 0.53),
          end: const Alignment(1, 0.53),
          colors: [appTheme.redA40001.withOpacity(0), appTheme.redA40001],
        ),
      );
  static BoxDecoration get outlineBlack => BoxDecoration(
        border: Border.all(
          color: appTheme.black900,
          width: 3.h,
        ),
      );
  static BoxDecoration get outlineBlack900 => BoxDecoration(
        color: appTheme.blueGray90004,
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.25),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(
              11,
              0,
            ),
          )
        ],
      );
  static BoxDecoration get outlineBlueGray => BoxDecoration(
        border: Border.all(
          color: appTheme.blueGray700,
          width: 1.h,
        ),
      );
  static BoxDecoration get outlineGray => BoxDecoration(
        color: appTheme.blueGray90006,
        border: Border.all(
          color: appTheme.gray40001,
          width: 1.h,
        ),
      );
}

class BorderRadiusStyle {
  static BorderRadius get circleBorder44 => BorderRadius.circular(
        44.h,
      );
  static BorderRadius get circleBorder53 => BorderRadius.circular(
        53.h,
      );
  static BorderRadius get customBorderTL23 => BorderRadius.only(
        topLeft: Radius.circular(23.h),
        topRight: Radius.circular(18.h),
      );
  static BorderRadius get roundedBorder10 => BorderRadius.circular(
        10.h,
      );
  static BorderRadius get roundedBorder15 => BorderRadius.circular(
        15.h,
      );
  static BorderRadius get roundedBorder22 => BorderRadius.circular(
        22.h,
      );
  static BorderRadius get roundedBorder27 => BorderRadius.circular(
        27.h,
      );
  static BorderRadius get roundedBorder30 => BorderRadius.circular(
        30.h,
      );
  static BorderRadius get roundedBorder33 => BorderRadius.circular(
        33.h,
      );
  static BorderRadius get roundedBorder4 => BorderRadius.circular(
        4.h,
      );
  static BorderRadius get roundedBorder7 => BorderRadius.circular(
        7.h,
      );
}
