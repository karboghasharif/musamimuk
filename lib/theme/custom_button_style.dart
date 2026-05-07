import 'package:flutter/material.dart';

import '../core/app_export.dart';

class CustomButtonStyles {
  static ButtonStyle get fillBlueGray => ElevatedButton.styleFrom(
    backgroundColor: appTheme.blueGray90001,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.h)),
  );
  static ButtonStyle get fillBlueGrayTL6 => ElevatedButton.styleFrom(
    backgroundColor: appTheme.blueGray90003,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.h)),
  );
  static ButtonStyle get fillGray => ElevatedButton.styleFrom(
    backgroundColor: appTheme.gray80004,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.h)),
  );
  static ButtonStyle get fillOnError => ElevatedButton.styleFrom(
    backgroundColor: theme.colorScheme.onError.withOpacity(1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
  );
  static ButtonStyle get fillOnPrimary => ElevatedButton.styleFrom(
    backgroundColor: theme.colorScheme.onPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.h)),
  );
  static ButtonStyle get fillPrimary => ElevatedButton.styleFrom(
    backgroundColor: theme.colorScheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13.h)),
  );
  static ButtonStyle get fillPrimaryBR16 => ElevatedButton.styleFrom(
    backgroundColor: theme.colorScheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12.h),
        bottomRight: Radius.circular(16.h),
      ),
    ),
  );
  static ButtonStyle get fillPrimaryTL10 => ElevatedButton.styleFrom(
    backgroundColor: theme.colorScheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
  );
  static ButtonStyle get fillPrimaryTL19 => ElevatedButton.styleFrom(
    backgroundColor: theme.colorScheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(19.h),
        bottomRight: Radius.circular(19.h),
      ),
    ),
  );
  static ButtonStyle get fillPrimaryTL7 => ElevatedButton.styleFrom(
    backgroundColor: theme.colorScheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.h)),
  );
  static ButtonStyle get fillYellow => ElevatedButton.styleFrom(
    backgroundColor: appTheme.yellow500,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
  );
  static ButtonStyle get outlineBlackTL24 => ElevatedButton.styleFrom(
    backgroundColor: appTheme.blueGray90004,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.h)),
    shadowColor: appTheme.black900.withOpacity(0.25),
    elevation: 3,
  );
  static ButtonStyle get none => ButtonStyle(
    backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
    elevation: MaterialStateProperty.all<double>(0),
  );
}
