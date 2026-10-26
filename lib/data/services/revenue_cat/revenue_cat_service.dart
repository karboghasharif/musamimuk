import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/config/revenue_cat_config.dart';

/// Central RevenueCat wrapper: configure, identity, entitlements, paywall,
/// Customer Center, Pro packages, and coin consumables.
///
/// Coin **balances** stay on the Musamimuk server wallet. After a coin pack
/// purchase, the app calls `POST /wallet/revenuecat/verify` to credit coins.
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  final ValueNotifier<CustomerInfo?> customerInfo =
      ValueNotifier<CustomerInfo?>(null);

  bool _configured = false;
  bool get isConfigured => _configured;

  CustomerInfoUpdateListener? _customerInfoListener;

  /// Call once early in [main] after [WidgetsFlutterBinding.ensureInitialized].
  Future<bool> configure({String? appUserId}) async {
    if (_configured) return true;

    final apiKey = RevenueCatConfig.resolveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint(
        'RevenueCat: skipped configure — set appleApiKey / googleApiKey '
        'for release builds (Test Store key must not ship to stores).',
      );
      return false;
    }

    try {
      await Purchases.setLogLevel(
        kReleaseMode ? LogLevel.warn : LogLevel.debug,
      );

      final configuration = PurchasesConfiguration(apiKey);
      final trimmedId = appUserId?.trim();
      if (trimmedId != null && trimmedId.isNotEmpty) {
        configuration.appUserID = trimmedId;
      }

      await Purchases.configure(configuration);
      _configured = true;

      _customerInfoListener = (info) {
        customerInfo.value = info;
      };
      Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);

      customerInfo.value = await Purchases.getCustomerInfo();
      return true;
    } catch (e, st) {
      debugPrint('RevenueCat configure failed: $e\n$st');
      _configured = false;
      return false;
    }
  }

  /// Identify the logged-in Musamimuk user so purchases transfer across devices.
  Future<CustomerInfo?> logIn(String appUserId) async {
    if (!_configured) return null;
    final id = appUserId.trim();
    if (id.isEmpty) return null;

    try {
      final result = await Purchases.logIn(id);
      customerInfo.value = result.customerInfo;
      return result.customerInfo;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat logIn failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('RevenueCat logIn failed: $e');
      return null;
    }
  }

  /// Return to an anonymous RevenueCat user after logout.
  Future<CustomerInfo?> logOut() async {
    if (!_configured) return null;
    try {
      final anonymous = await Purchases.isAnonymous;
      if (anonymous) {
        customerInfo.value = await Purchases.getCustomerInfo();
        return customerInfo.value;
      }
      final info = await Purchases.logOut();
      customerInfo.value = info;
      return info;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat logOut failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('RevenueCat logOut failed: $e');
      return null;
    }
  }

  Future<CustomerInfo?> refreshCustomerInfo({bool invalidateCache = false}) async {
    if (!_configured) return null;
    try {
      if (invalidateCache) {
        await Purchases.invalidateCustomerInfoCache();
      }
      final info = await Purchases.getCustomerInfo();
      customerInfo.value = info;
      return info;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat getCustomerInfo failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo failed: $e');
      return null;
    }
  }

  /// Active `musamimuk_pro` entitlement (cached [customerInfo] or fresh fetch).
  Future<bool> hasProEntitlement({bool forceRefresh = false}) async {
    final info = forceRefresh
        ? await refreshCustomerInfo()
        : (customerInfo.value ?? await refreshCustomerInfo());
    return isProEntitlementActive(info);
  }

  static bool isProEntitlementActive(CustomerInfo? info) {
    if (info == null) return false;
    final entitlement =
        info.entitlements.all[RevenueCatConfig.entitlementPro];
    return entitlement?.isActive == true;
  }

  EntitlementInfo? proEntitlement(CustomerInfo? info) {
    return info?.entitlements.all[RevenueCatConfig.entitlementPro];
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      debugPrint('RevenueCat getOfferings failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('RevenueCat getOfferings failed: $e');
      return null;
    }
  }

  /// Resolves Lifetime / Yearly / Monthly packages from the current offering.
  Future<Map<String, Package>> packagesByProductId() async {
    final offerings = await getOfferings();
    final current = offerings?.current;
    if (current == null) return {};
    return _packagesByProductId(current);
  }

  Map<String, Package> _packagesByProductId(Offering current) {
    final byId = <String, Package>{};
    for (final package in current.availablePackages) {
      final productId = package.storeProduct.identifier;
      if (RevenueCatConfig.productIds.contains(productId)) {
        byId[productId] = package;
      }
    }

    void putTyped(String productId, Package? typed) {
      if (typed != null) byId.putIfAbsent(productId, () => typed);
    }

    putTyped(RevenueCatConfig.productLifetime, current.lifetime);
    putTyped(RevenueCatConfig.productYearly, current.annual);
    putTyped(RevenueCatConfig.productMonthly, current.monthly);
    return byId;
  }

  /// Find a store product package by SKU across current + named offerings.
  Future<Package?> findPackageByProductId(String productId) async {
    final offerings = await getOfferings();
    if (offerings == null) return null;

    Package? search(Offering? offering) {
      if (offering == null) return null;
      for (final package in offering.availablePackages) {
        if (package.storeProduct.identifier == productId) return package;
      }
      return null;
    }

    final fromCoins = search(offerings.getOffering(RevenueCatConfig.coinsOfferingId));
    if (fromCoins != null) return fromCoins;

    final fromCurrent = search(offerings.current);
    if (fromCurrent != null) return fromCurrent;

    for (final offering in offerings.all.values) {
      final match = search(offering);
      if (match != null) return match;
    }
    return null;
  }

  /// Localized price strings for coin SKUs from RevenueCat offerings.
  Future<Map<String, String>> coinPriceLabels(Set<String> skus) async {
    final labels = <String, String>{};
    if (!_configured || skus.isEmpty) return labels;

    final offerings = await getOfferings();
    if (offerings == null) return labels;

    void absorb(Offering? offering) {
      if (offering == null) return;
      for (final package in offering.availablePackages) {
        final id = package.storeProduct.identifier;
        if (skus.contains(id)) {
          labels[id] = package.storeProduct.priceString;
        }
      }
    }

    absorb(offerings.getOffering(RevenueCatConfig.coinsOfferingId));
    absorb(offerings.current);
    for (final offering in offerings.all.values) {
      absorb(offering);
    }
    return labels;
  }

  /// Purchase a specific package (prefer Paywall UI for Pro UX flows).
  Future<RevenueCatPurchaseOutcome> purchasePackage(Package package) async {
    if (!_configured) {
      return RevenueCatPurchaseOutcome.failure(
        'Purchases are not available on this build.',
      );
    }

    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      customerInfo.value = result.customerInfo;
      final isPro = isProEntitlementActive(result.customerInfo);
      return RevenueCatPurchaseOutcome.success(
        customerInfo: result.customerInfo,
        unlockedPro: isPro,
        storeTransaction: result.storeTransaction,
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return RevenueCatPurchaseOutcome.canceled();
      }
      return RevenueCatPurchaseOutcome.failure(
        e.message ?? 'Purchase failed. Please try again.',
        errorCode: code,
      );
    } catch (e) {
      return RevenueCatPurchaseOutcome.failure(
        'Purchase failed. Please try again.',
      );
    }
  }

  /// Buy a coin pack by store product id (`coins_50`, …).
  Future<RevenueCatPurchaseOutcome> purchaseCoinProduct(String productId) async {
    if (!_configured) {
      return RevenueCatPurchaseOutcome.failure(
        'Coin purchases are not available on this build.',
      );
    }
    final package = await findPackageByProductId(productId);
    if (package == null) {
      return RevenueCatPurchaseOutcome.failure(
        'This coin pack is not available in the store yet.',
      );
    }
    return purchasePackage(package);
  }

  Future<RevenueCatPurchaseOutcome> restorePurchases() async {
    if (!_configured) {
      return RevenueCatPurchaseOutcome.failure(
        'Subscriptions are not available on this build.',
      );
    }

    try {
      final info = await Purchases.restorePurchases();
      customerInfo.value = info;
      return RevenueCatPurchaseOutcome.success(
        customerInfo: info,
        unlockedPro: isProEntitlementActive(info),
      );
    } on PlatformException catch (e) {
      return RevenueCatPurchaseOutcome.failure(
        e.message ?? 'Could not restore purchases.',
        errorCode: PurchasesErrorHelper.getErrorCode(e),
      );
    } catch (e) {
      return RevenueCatPurchaseOutcome.failure(
        'Could not restore purchases.',
      );
    }
  }

  /// Fetch the Coin packs offering (`coins`) — not [Offerings.current].
  Future<Offering?> getCoinsOffering() async {
    final offerings = await getOfferings();
    return offerings?.getOffering(RevenueCatConfig.coinsOfferingId);
  }

  /// Present the remotely configured RevenueCat Paywall.
  ///
  /// Prefer [presentPaywallIfNeeded] so restore auto-dismisses when
  /// `musamimuk_pro` becomes active.
  Future<PaywallResult> presentPaywall({
    bool onlyIfNeeded = true,
    Offering? offering,
    bool displayCloseButton = true,
    void Function(CustomerInfo info, StoreTransaction transaction)?
        onPurchaseCompleted,
  }) async {
    if (!_configured) return PaywallResult.error;

    void handlePurchase(CustomerInfo info, StoreTransaction transaction) {
      customerInfo.value = info;
      onPurchaseCompleted?.call(info, transaction);
    }

    try {
      if (onlyIfNeeded) {
        return await RevenueCatUI.presentPaywallIfNeeded(
          RevenueCatConfig.entitlementPro,
          offering: offering,
          displayCloseButton: displayCloseButton,
          onPurchaseCompleted: handlePurchase,
          onRestoreCompleted: (info) {
            customerInfo.value = info;
          },
        );
      }

      return await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: displayCloseButton,
        onPurchaseCompleted: handlePurchase,
        onRestoreCompleted: (info) {
          customerInfo.value = info;
        },
      );
    } catch (e, st) {
      debugPrint('RevenueCat presentPaywall failed: $e\n$st');
      return PaywallResult.error;
    }
  }

  /// Present the **Coin packs** paywall (`offering` id = [RevenueCatConfig.coinsOfferingId]).
  ///
  /// Always uses [RevenueCatUI.presentPaywall] (not IfNeeded) — coins are consumables,
  /// not an entitlement gate.
  Future<PaywallResult> presentCoinsPaywall({
    bool displayCloseButton = true,
    void Function(CustomerInfo info, StoreTransaction transaction)?
        onPurchaseCompleted,
  }) async {
    final coinsOffering = await getCoinsOffering();
    if (coinsOffering == null) {
      debugPrint(
        'RevenueCat: offering "${RevenueCatConfig.coinsOfferingId}" not found',
      );
      return PaywallResult.error;
    }
    return presentPaywall(
      onlyIfNeeded: false,
      offering: coinsOffering,
      displayCloseButton: displayCloseButton,
      onPurchaseCompleted: onPurchaseCompleted,
    );
  }

  /// Self-serve manage / cancel / restore UI (Pro & Enterprise RC plans).
  Future<void> presentCustomerCenter() async {
    if (!_configured) return;
    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreCompleted: (info) {
          customerInfo.value = info;
        },
      );
      await refreshCustomerInfo();
    } catch (e, st) {
      debugPrint('RevenueCat presentCustomerCenter failed: $e\n$st');
    }
  }

  /// Optional attributes for dashboard / support context.
  Future<void> setUserAttributes({
    String? email,
    String? displayName,
  }) async {
    if (!_configured) return;
    try {
      if (email != null && email.trim().isNotEmpty) {
        await Purchases.setEmail(email.trim());
      }
      if (displayName != null && displayName.trim().isNotEmpty) {
        await Purchases.setDisplayName(displayName.trim());
      }
    } catch (e) {
      debugPrint('RevenueCat setUserAttributes failed: $e');
    }
  }
}

class RevenueCatPurchaseOutcome {
  const RevenueCatPurchaseOutcome._({
    required this.ok,
    this.canceled = false,
    this.unlockedPro = false,
    this.customerInfo,
    this.storeTransaction,
    this.message = '',
    this.errorCode,
  });

  factory RevenueCatPurchaseOutcome.success({
    required CustomerInfo customerInfo,
    required bool unlockedPro,
    StoreTransaction? storeTransaction,
  }) {
    return RevenueCatPurchaseOutcome._(
      ok: true,
      unlockedPro: unlockedPro,
      customerInfo: customerInfo,
      storeTransaction: storeTransaction,
    );
  }

  factory RevenueCatPurchaseOutcome.failure(
    String message, {
    PurchasesErrorCode? errorCode,
  }) {
    return RevenueCatPurchaseOutcome._(
      ok: false,
      message: message,
      errorCode: errorCode,
    );
  }

  factory RevenueCatPurchaseOutcome.canceled() {
    return const RevenueCatPurchaseOutcome._(
      ok: false,
      canceled: true,
    );
  }

  final bool ok;
  final bool canceled;
  final bool unlockedPro;
  final CustomerInfo? customerInfo;
  final StoreTransaction? storeTransaction;
  final String message;
  final PurchasesErrorCode? errorCode;
}
