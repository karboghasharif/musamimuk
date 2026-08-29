import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:musamimuk/data/models/wallet_models.dart';
import 'package:musamimuk/data/repositories/wallet_repository.dart';

/// Android application id used for Play Billing verify payloads.
const String kMusamimukAndroidPackageName = 'com.musamimuk.app';

/// Wraps store purchase + server `POST /wallet/iap/verify`.
///
/// Completes / acknowledges the store purchase **only after** a successful
/// (or already_credited) verify so receipts are not lost on verify failure.
class IapPurchaseService {
  IapPurchaseService({
    InAppPurchase? iap,
    WalletRepository? walletRepository,
  })  : _iap = iap ?? InAppPurchase.instance,
        _walletRepository = walletRepository ?? WalletRepository();

  final InAppPurchase _iap;
  final WalletRepository _walletRepository;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, ProductDetails> _productsById = {};
  Completer<IapPurchaseOutcome>? _pendingPurchase;

  bool get isAvailableSync => _available;
  bool _available = false;
  bool _initialized = false;

  Future<bool> ensureInitialized() async {
    if (_initialized) return _available;
    _available = await _iap.isAvailable();
    if (_available) {
      _subscription ??= _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object error, StackTrace stack) {
          debugPrint('IAP purchaseStream error: $error');
          _failPending(
            IapPurchaseOutcome.failure('Store purchase failed. Please try again.'),
          );
        },
      );
    }
    _initialized = true;
    return _available;
  }

  Future<Map<String, ProductDetails>> queryProducts(Set<String> skus) async {
    await ensureInitialized();
    if (!_available || skus.isEmpty) return {};
    final response = await _iap.queryProductDetails(skus);
    if (response.error != null) {
      debugPrint('IAP queryProductDetails error: ${response.error}');
    }
    for (final product in response.productDetails) {
      _productsById[product.id] = product;
    }
    return Map<String, ProductDetails>.from(_productsById)
      ..removeWhere((key, _) => !skus.contains(key));
  }

  ProductDetails? productForSku(String sku) => _productsById[sku];

  /// Starts a consumable purchase and waits until verify + complete finish.
  Future<IapPurchaseOutcome> buyConsumable(WalletPackage package) async {
    await ensureInitialized();
    if (!_available) {
      return IapPurchaseOutcome.failure(
        'In-app purchases are not available on this device.',
      );
    }
    if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
      return IapPurchaseOutcome.failure(
        'Another purchase is already in progress.',
      );
    }

    var product = _productsById[package.sku];
    product ??= (await queryProducts({package.sku}))[package.sku];
    if (product == null) {
      return IapPurchaseOutcome.failure(
        'This coin package is not available in the store yet.',
      );
    }

    final completer = Completer<IapPurchaseOutcome>();
    _pendingPurchase = completer;

    final param = PurchaseParam(productDetails: product);
    final started = await _iap.buyConsumable(
      purchaseParam: param,
      autoConsume: false,
    );
    if (!started) {
      _pendingPurchase = null;
      return IapPurchaseOutcome.failure(
        'Could not start the store purchase.',
      );
    }

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pendingPurchase = null;
        return IapPurchaseOutcome.failure(
          'Purchase timed out. If you were charged, reopen the store to finish.',
        );
      },
    );
  }

  /// Re-attempt verify for a purchase that was paid but not yet completed.
  Future<IapPurchaseOutcome> verifyAndComplete(PurchaseDetails details) async {
    return _verifyThenComplete(details);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final details in purchases) {
      unawaited(_handlePurchase(details));
    }
  }

  Future<void> _handlePurchase(PurchaseDetails details) async {
    switch (details.status) {
      case PurchaseStatus.pending:
        return;
      case PurchaseStatus.canceled:
        await _safeComplete(details);
        _failPending(IapPurchaseOutcome.canceled());
        return;
      case PurchaseStatus.error:
        await _safeComplete(details);
        _failPending(
          IapPurchaseOutcome.failure(
            details.error?.message ?? 'Store purchase failed.',
          ),
        );
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final outcome = await _verifyThenComplete(details);
        _completePending(outcome);
        return;
    }
  }

  Future<IapPurchaseOutcome> _verifyThenComplete(
    PurchaseDetails details,
  ) async {
    final platform = (!kIsWeb && Platform.isIOS) ? 'ios' : 'android';
    final productId = details.productID;
    final storeTxnId = details.purchaseID?.trim().isNotEmpty == true
        ? details.purchaseID!.trim()
        : details.verificationData.serverVerificationData;

    if (storeTxnId.isEmpty) {
      return IapPurchaseOutcome.failure(
        'Missing store transaction id. Please try again.',
      );
    }

    final result = await _walletRepository.verifyIap(
      platform: platform,
      productId: productId,
      storeTransactionId: storeTxnId,
      purchaseToken: platform == 'android'
          ? details.verificationData.serverVerificationData
          : null,
      packageName:
          platform == 'android' ? kMusamimukAndroidPackageName : null,
      receiptData: platform == 'ios'
          ? details.verificationData.localVerificationData
          : null,
    );

    if (result is WalletFailure<WalletIapVerifyResult>) {
      // Do NOT complete the store purchase — keep receipt for retry.
      return IapPurchaseOutcome.failure(result.message);
    }

    final success = result as WalletSuccess<WalletIapVerifyResult>;
    await _safeComplete(details);
    return IapPurchaseOutcome.success(
      wallet: success.data.wallet,
      alreadyCredited: success.data.alreadyCredited,
      message: success.message ?? success.data.message,
    );
  }

  Future<void> _safeComplete(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(details);
      } catch (e) {
        debugPrint('IAP completePurchase failed: $e');
      }
    }
  }

  void _completePending(IapPurchaseOutcome outcome) {
    final pending = _pendingPurchase;
    if (pending != null && !pending.isCompleted) {
      pending.complete(outcome);
    }
    _pendingPurchase = null;
  }

  void _failPending(IapPurchaseOutcome outcome) {
    _completePending(outcome);
  }
}

class IapPurchaseOutcome {
  const IapPurchaseOutcome._({
    required this.ok,
    this.canceled = false,
    this.wallet,
    this.alreadyCredited = false,
    this.message = '',
  });

  factory IapPurchaseOutcome.success({
    required WalletBalance wallet,
    bool alreadyCredited = false,
    String? message,
  }) {
    return IapPurchaseOutcome._(
      ok: true,
      wallet: wallet,
      alreadyCredited: alreadyCredited,
      message: message ?? '',
    );
  }

  factory IapPurchaseOutcome.failure(String message) {
    return IapPurchaseOutcome._(ok: false, message: message);
  }

  factory IapPurchaseOutcome.canceled() {
    return const IapPurchaseOutcome._(
      ok: false,
      canceled: true,
      message: '',
    );
  }

  final bool ok;
  final bool canceled;
  final WalletBalance? wallet;
  final bool alreadyCredited;
  final String message;
}
