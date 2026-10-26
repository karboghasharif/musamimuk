import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// RevenueCat project configuration for Musamimuk Pro subscriptions.
///
/// Dashboard checklist:
/// 1. Create entitlement `musamimuk_pro`.
/// 2. Create products with store identifiers: `lifetime`, `pro_yearly`, `pro_monthly`.
/// 3. Attach all three products to `musamimuk_pro`.
/// 4. Add them to the **current** Offering as Lifetime / Annual / Monthly packages.
/// 5. Design a Paywall on that Offering (RevenueCat dashboard → Paywalls).
/// 6. (Optional) Enable Customer Center for manage / restore / cancel flows.
///
/// Keys: Project Settings → API keys in the RevenueCat dashboard.
/// Never ship a Test Store (`test_…`) key in App Store / Play production builds.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Entitlement that unlocks Musamimuk Pro.
  static const String entitlementPro = 'musamimuk_pro';

  /// Store product identifiers (must match App Store / Play / Test Store).
  /// Play subscriptions use `productId:basePlanId` in RevenueCat.
  static const String productLifetime = 'lifetime';
  static const String productYearly = 'pro_yearly:yearly-base';
  static const String productMonthly = 'pro_monthly:monthly-base';

  static const Set<String> productIds = {
    productLifetime,
    productYearly,
    productMonthly,
  };

  /// Consumable coin packs (must match `coin_packages.sku` + RC Test Store products).
  /// Do **not** attach these to [entitlementPro].
  static const String coinSku50 = 'coins_50';
  static const String coinSku120 = 'coins_120';
  static const String coinSku500 = 'coins_500';

  static const Set<String> coinProductIds = {
    coinSku50,
    coinSku120,
    coinSku500,
  };

  /// Optional Offering identifier for coin packs (falls back to searching all offerings).
  static const String coinsOfferingId = 'coins';

  /// Test Store public SDK key (safe for debug / local testing only).
  static const String testApiKey = 'test_VzTVhnnwaszleFgTGCxdaVTuYqY';

  /// Replace with App Store public SDK key before release (`appl_…`).
  static const String appleApiKey = '';

  /// Google Play public SDK key (`goog_…`).
  static const String googleApiKey = 'goog_TBLPplEYjOqbfUbTAKcPcMMmIYy';

  /// Public API key for the current build + platform.
  ///
  /// Debug → Test Store. Release → platform store key (required).
  static String? resolveApiKey() {
    if (kIsWeb) return null;

    if (kReleaseMode) {
      if (Platform.isIOS) {
        return appleApiKey.trim().isEmpty ? null : appleApiKey.trim();
      }
      if (Platform.isAndroid) {
        return googleApiKey.trim().isEmpty ? null : googleApiKey.trim();
      }
      return null;
    }

    // Debug / profile: Test Store works without App Store / Play setup.
    return testApiKey;
  }
}
