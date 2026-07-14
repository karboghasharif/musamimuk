import 'package:flutter/material.dart';

import '../core/design_system/app_design_tokens.dart';
import '../core/utils/size_utils.dart';
import '../core/app_export.dart' show theme;

extension on TextStyle {
  TextStyle get inter => copyWith(fontFamily: 'Inter');
  TextStyle get poppins => copyWith(fontFamily: 'Poppins');
  TextStyle get visbyRoundCF => copyWith(fontFamily: 'Visby Round CF');
}

/// Legacy [CustomTextStyles] mapped to accessible dark-theme text colors.
class CustomTextStyles {
  static Color get _primary => AppDs.textOnDarkPrimary;
  static Color get _secondary => AppDs.textOnDarkSecondary;
  static Color get _accent => theme.colorScheme.primary;

  static get bodyLargeOnPrimaryContainer =>
      theme.textTheme.bodyLarge!.copyWith(color: _primary, fontSize: 16.fSize);
  static get bodyLargePoppins => theme.textTheme.bodyLarge!.poppins.copyWith(
    fontSize: 18.fSize,
    color: _primary,
  );
  static get bodyMedium14 =>
      theme.textTheme.bodyMedium!.copyWith(fontSize: 14.fSize, color: _primary);
  static get bodyMedium15 =>
      theme.textTheme.bodyMedium!.copyWith(fontSize: 15.fSize, color: _primary);
  static get bodyMediumBluegray300 => theme.textTheme.bodyMedium!.copyWith(
    color: _secondary,
    fontSize: 15.fSize,
  );
  static get bodyMediumBluegray90004 =>
      theme.textTheme.bodyMedium!.copyWith(color: _primary, fontSize: 14.fSize);
  static get bodyMediumInter =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: _primary);
  static get bodyMediumInterBluegray90004 => theme.textTheme.bodyMedium!.inter
      .copyWith(color: _secondary, fontSize: 14.fSize);
  static get bodyMediumInterBluegray9000414 => theme.textTheme.bodyMedium!.inter
      .copyWith(color: _primary, fontSize: 14.fSize);
  static get bodyMediumInterGray700 =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: _secondary);
  static get bodyMediumInterGray8008b =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: _secondary);
  static get bodyMediumInterGray90001 =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: _primary);
  static get bodyMediumInterOnPrimaryContainer =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: _secondary);
  static get bodyMediumInterOnPrimaryContainer14 => theme
      .textTheme
      .bodyMedium!
      .inter
      .copyWith(color: _secondary, fontSize: 14.fSize);
  static get bodyMediumInterPrimary =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: _accent);
  static get bodyMediumInter_1 =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: _primary);
  static get bodyMediumVisbyRoundCFBluegray300 => theme
      .textTheme
      .bodyMedium!
      .visbyRoundCF
      .copyWith(color: _secondary, fontSize: 15.fSize);
  static get bodySmall10 => theme.textTheme.bodySmall!.copyWith(
    fontSize: 10.fSize,
    color: _secondary,
  );
  static get bodySmall12 => theme.textTheme.bodySmall!.copyWith(
    fontSize: 12.fSize,
    color: _secondary,
  );
  static get bodySmallBluegray90004 =>
      theme.textTheme.bodySmall!.copyWith(color: _secondary);
  static get bodySmallBluegray900048 => theme.textTheme.bodySmall!.copyWith(
    color: _secondary,
    fontSize: 11.fSize,
  );
  static get bodySmallGray50001 => theme.textTheme.bodySmall!.copyWith(
    color: _secondary,
    fontSize: 12.fSize,
  );
  static get bodySmallInter => theme.textTheme.bodySmall!.inter.copyWith(
    fontSize: 12.fSize,
    color: _secondary,
  );
  static get bodySmallInterGray90005 => theme.textTheme.bodySmall!.inter
      .copyWith(color: _secondary, fontSize: 12.fSize);
  static get bodySmallOnPrimaryContainer => theme.textTheme.bodySmall!.copyWith(
    color: _secondary,
    fontSize: 12.fSize,
    fontWeight: FontWeight.w400,
  );
  static get bodySmallOnPrimaryContainer12 => theme.textTheme.bodySmall!
      .copyWith(color: _secondary, fontSize: 12.fSize);
  static get bodySmallOnPrimaryContainerLight => theme.textTheme.bodySmall!
      .copyWith(color: _secondary, fontWeight: FontWeight.w400);
  static get bodySmallPrimary =>
      theme.textTheme.bodySmall!.copyWith(color: _accent);
  static get bodySmallPrimary8 =>
      theme.textTheme.bodySmall!.copyWith(color: _accent, fontSize: 11.fSize);
  static get bodySmallYellowA400 =>
      theme.textTheme.bodySmall!.copyWith(color: _accent);
  static get poppinsBluegray90004 => TextStyle(
    color: _secondary,
    fontSize: 11.fSize,
    fontWeight: FontWeight.w400,
  ).poppins;
  static get titleLargeBluegray90004 => theme.textTheme.titleLarge!.copyWith(
    color: _primary,
    fontWeight: FontWeight.w600,
  );
  static get titleMediumBluegray90002 => theme.textTheme.titleMedium!.copyWith(
    color: _primary,
    fontWeight: FontWeight.w700,
  );

  /// On yellow/primary buttons — keep dark text for contrast.
  static get titleMediumBluegray90004 => theme.textTheme.titleMedium!.copyWith(
    color: theme.colorScheme.onPrimary,
    fontSize: 16.fSize,
    fontWeight: FontWeight.w600,
  );
  static get titleMediumBluegray90004Bold =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontSize: 16.fSize,
        fontWeight: FontWeight.w700,
      );
  static get titleMediumBold => theme.textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.w700,
    color: _primary,
  );
  static get titleMediumOnError => theme.textTheme.titleMedium!.copyWith(
    color: theme.colorScheme.onError,
    fontSize: 16.fSize,
  );
  static get titleMediumPoppins => theme.textTheme.titleMedium!.poppins
      .copyWith(fontSize: 16.fSize, color: _primary);
  static get titleMediumPoppins16 => theme.textTheme.titleMedium!.poppins
      .copyWith(fontSize: 16.fSize, color: _primary);
  static get titleMediumPoppinsBluegray90004 =>
      theme.textTheme.titleMedium!.poppins.copyWith(
        color: theme.colorScheme.onPrimary,
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumPoppinsBluegray9000416 => theme
      .textTheme
      .titleMedium!
      .poppins
      .copyWith(color: theme.colorScheme.onPrimary, fontSize: 16.fSize);
  static get titleSmallBluegray90004 =>
      theme.textTheme.titleSmall!.copyWith(color: _primary, fontSize: 15.fSize);
  static get titleSmallPrimary => theme.textTheme.titleSmall!.copyWith(
    color: _accent,
    fontSize: 15.fSize,
    fontWeight: FontWeight.w600,
  );
  static get titleSmallPrimary_1 =>
      theme.textTheme.titleSmall!.copyWith(color: _accent);
  static get titleSmallVisbyRoundCF => theme.textTheme.titleSmall!.visbyRoundCF
      .copyWith(fontWeight: FontWeight.w600, color: _primary);
  static get titleSmallVisbyRoundCFBluegray10001 => theme
      .textTheme
      .titleSmall!
      .visbyRoundCF
      .copyWith(color: _secondary, fontSize: 15.fSize);
  static get titleSmallVisbyRoundCFBluegray300 => theme
      .textTheme
      .titleSmall!
      .visbyRoundCF
      .copyWith(color: _secondary, fontSize: 15.fSize);
  static get titleSmallVisbyRoundCFBluegray30015 => theme
      .textTheme
      .titleSmall!
      .visbyRoundCF
      .copyWith(color: _secondary, fontSize: 15.fSize);
  static get titleSmallVisbyRoundCFPrimary =>
      theme.textTheme.titleSmall!.visbyRoundCF.copyWith(
        color: _accent,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w900,
      );
}
