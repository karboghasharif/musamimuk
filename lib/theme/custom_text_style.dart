import 'package:flutter/material.dart';
import '../core/app_export.dart';

extension on TextStyle {
  TextStyle get inter {
    return copyWith(fontFamily: 'Inter');
  }

  TextStyle get poppins {
    return copyWith(fontFamily: 'Poppins');
  }

  TextStyle get visbyRoundCF {
    return copyWith(fontFamily: 'Visby Round CF');
  }
}

class CustomTextStyles {
  static get bodyLargeOnPrimaryContainer => theme.textTheme.bodyLarge!.copyWith(
    color: Colors.white,
    fontSize: 16.fSize,
  );
  static get bodyLargePoppins =>
      theme.textTheme.bodyLarge!.poppins.copyWith(fontSize: 18.fSize);
  static get bodyMedium14 =>
      theme.textTheme.bodyMedium!.copyWith(fontSize: 14.fSize);
  static get bodyMedium15 =>
      theme.textTheme.bodyMedium!.copyWith(fontSize: 15.fSize);
  static get bodyMediumBluegray300 => theme.textTheme.bodyMedium!.copyWith(
    color: appTheme.blueGray300,
    fontSize: 15.fSize,
  );
  static get bodyMediumBluegray90004 => theme.textTheme.bodyMedium!.copyWith(
    color: Colors.white,
    fontSize: 14.fSize,
  );
  static get bodyMediumInter => theme.textTheme.bodyMedium!.inter;
  static get bodyMediumInterBluegray90004 => theme.textTheme.bodyMedium!.inter
      .copyWith(color: appTheme.blueGray90004.withOpacity(0.55));
  static get bodyMediumInterBluegray9000414 => theme.textTheme.bodyMedium!.inter
      .copyWith(color: appTheme.blueGray90004, fontSize: 14.fSize);
  static get bodyMediumInterGray700 =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: appTheme.gray700);
  static get bodyMediumInterGray8008b =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: appTheme.gray8008b);
  static get bodyMediumInterGray90001 =>
      theme.textTheme.bodyMedium!.inter.copyWith(color: appTheme.gray90001);
  static get bodyMediumInterOnPrimaryContainer => theme
      .textTheme
      .bodyMedium!
      .inter
      .copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.55));
  static get bodyMediumInterOnPrimaryContainer14 =>
      theme.textTheme.bodyMedium!.inter.copyWith(
        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.16),
        fontSize: 14.fSize,
      );
  static get bodyMediumInterPrimary => theme.textTheme.bodyMedium!.inter
      .copyWith(color: theme.colorScheme.primary);
  static get bodyMediumInter_1 => theme.textTheme.bodyMedium!.inter;
  static get bodyMediumVisbyRoundCFBluegray300 => theme
      .textTheme
      .bodyMedium!
      .visbyRoundCF
      .copyWith(color: appTheme.blueGray300, fontSize: 15.fSize);
  static get bodySmall10 =>
      theme.textTheme.bodySmall!.copyWith(fontSize: 10.fSize);
  static get bodySmall12 =>
      theme.textTheme.bodySmall!.copyWith(fontSize: 12.fSize);
  static get bodySmallBluegray90004 =>
      theme.textTheme.bodySmall!.copyWith(color: appTheme.blueGray90004);
  static get bodySmallBluegray900048 => theme.textTheme.bodySmall!.copyWith(
    color: appTheme.blueGray90004,
    fontSize: 8.fSize,
  );
  static get bodySmallGray50001 => theme.textTheme.bodySmall!.copyWith(
    color: appTheme.gray50001,
    fontSize: 12.fSize,
  );
  static get bodySmallInter =>
      theme.textTheme.bodySmall!.inter.copyWith(fontSize: 12.fSize);
  static get bodySmallInterGray90005 => theme.textTheme.bodySmall!.inter
      .copyWith(color: appTheme.gray90005, fontSize: 12.fSize);
  static get bodySmallOnPrimaryContainer => theme.textTheme.bodySmall!.copyWith(
    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
    fontSize: 10.fSize,
    fontWeight: FontWeight.w300,
  );
  static get bodySmallOnPrimaryContainer12 =>
      theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
        fontSize: 12.fSize,
      );
  static get bodySmallOnPrimaryContainerLight =>
      theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
        fontWeight: FontWeight.w300,
      );
  static get bodySmallPrimary =>
      theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.primary);
  static get bodySmallPrimary8 => theme.textTheme.bodySmall!.copyWith(
    color: theme.colorScheme.primary,
    fontSize: 8.fSize,
  );
  static get bodySmallYellowA400 =>
      theme.textTheme.bodySmall!.copyWith(color: appTheme.yellowA400);
  static get poppinsBluegray90004 => TextStyle(
    color: appTheme.blueGray90004,
    fontSize: 6.fSize,
    fontWeight: FontWeight.w400,
  ).poppins;
  static get titleLargeBluegray90004 => theme.textTheme.titleLarge!.copyWith(
    color: appTheme.blueGray90004,
    fontWeight: FontWeight.w400,
  );
  static get titleMediumBluegray90002 => theme.textTheme.titleMedium!.copyWith(
    color: appTheme.blueGray90002,
    fontWeight: FontWeight.w700,
  );
  static get titleMediumBluegray90004 => theme.textTheme.titleMedium!.copyWith(
    color: appTheme.blueGray90004,
    fontSize: 16.fSize,
    fontWeight: FontWeight.w600,
  );
  static get titleMediumBluegray90004Bold =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.blueGray90004,
        fontSize: 16.fSize,
        fontWeight: FontWeight.w700,
      );
  static get titleMediumBold =>
      theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700);
  static get titleMediumOnError => theme.textTheme.titleMedium!.copyWith(
    color: theme.colorScheme.onError,
    fontSize: 16.fSize,
  );
  static get titleMediumPoppins =>
      theme.textTheme.titleMedium!.poppins.copyWith(fontSize: 16.fSize);
  static get titleMediumPoppins16 =>
      theme.textTheme.titleMedium!.poppins.copyWith(fontSize: 16.fSize);
  static get titleMediumPoppinsBluegray90004 =>
      theme.textTheme.titleMedium!.poppins.copyWith(
        color: appTheme.blueGray90004,
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumPoppinsBluegray9000416 => theme
      .textTheme
      .titleMedium!
      .poppins
      .copyWith(color: appTheme.blueGray90004, fontSize: 16.fSize);
  static get titleSmallBluegray90004 => theme.textTheme.titleSmall!.copyWith(
    color: appTheme.blueGray90004,
    fontSize: 15.fSize,
  );
  static get titleSmallPrimary => theme.textTheme.titleSmall!.copyWith(
    color: theme.colorScheme.primary,
    fontSize: 15.fSize,
    fontWeight: FontWeight.w600,
  );
  static get titleSmallPrimary_1 =>
      theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary);
  static get titleSmallVisbyRoundCF => theme.textTheme.titleSmall!.visbyRoundCF
      .copyWith(fontWeight: FontWeight.w600);
  static get titleSmallVisbyRoundCFBluegray10001 => theme
      .textTheme
      .titleSmall!
      .visbyRoundCF
      .copyWith(color: appTheme.blueGray10001, fontSize: 15.fSize);
  static get titleSmallVisbyRoundCFBluegray300 => theme
      .textTheme
      .titleSmall!
      .visbyRoundCF
      .copyWith(color: appTheme.blueGray300, fontSize: 15.fSize);
  static get titleSmallVisbyRoundCFBluegray30015 => theme
      .textTheme
      .titleSmall!
      .visbyRoundCF
      .copyWith(color: appTheme.blueGray300, fontSize: 15.fSize);
  static get titleSmallVisbyRoundCFPrimary =>
      theme.textTheme.titleSmall!.visbyRoundCF.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w900,
      );
}
