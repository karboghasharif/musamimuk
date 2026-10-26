import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';
import 'package:musamimuk/data/models/wallet_models.dart';
import 'package:musamimuk/data/repositories/wallet_repository.dart';
import 'package:musamimuk/data/services/iap/iap_purchase_service.dart';
import 'package:musamimuk/data/services/revenue_cat/revenue_cat_service.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

/// App-wide wallet / coins state. Balance always comes from the server.
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({
    WalletRepository? repository,
    IapPurchaseService? iapService,
    RevenueCatService? revenueCat,
  })  : _repository = repository ?? WalletRepository(),
        _iap = iapService ?? IapPurchaseService(),
        _rc = revenueCat ?? RevenueCatService.instance,
        super(const WalletState()) {
    on<WalletBootstrapEvent>(_onBootstrap);
    on<WalletRefreshEvent>(_onRefresh);
    on<WalletLoadPackagesEvent>(_onLoadPackages);
    on<WalletLoadTransactionsEvent>(_onLoadTransactions);
    on<WalletApplyServerBalanceEvent>(_onApplyBalance);
    on<WalletBuyPackageEvent>(_onBuyPackage);
    on<WalletCreditRevenueCatPurchaseEvent>(_onCreditRevenueCatPurchase);
    on<WalletClearErrorEvent>(_onClearError);
    on<WalletResetEvent>(_onReset);
  }

  final WalletRepository _repository;
  final IapPurchaseService _iap;
  final RevenueCatService _rc;

  IapPurchaseService get iapService => _iap;

  Future<void> _onBootstrap(
    WalletBootstrapEvent event,
    Emitter<WalletState> emit,
  ) async {
    final prefs = PrefUtils();
    if (!prefs.isLoggedIn() || prefs.isGuestAccount()) {
      emit(const WalletState(bootstrapped: true));
      return;
    }
    emit(state.copyWith(isLoadingWallet: true, clearError: true));
    await _loadWalletAndCosts(emit);
    emit(state.copyWith(bootstrapped: true));
  }

  Future<void> _onRefresh(
    WalletRefreshEvent event,
    Emitter<WalletState> emit,
  ) async {
    final prefs = PrefUtils();
    if (!prefs.isLoggedIn() || prefs.isGuestAccount()) {
      emit(const WalletState(bootstrapped: true));
      return;
    }
    emit(state.copyWith(isLoadingWallet: true, clearError: true));
    await _loadWalletAndCosts(emit);
  }

  Future<void> _loadWalletAndCosts(Emitter<WalletState> emit) async {
    final walletRes = await _repository.getWallet();
    final costsRes = await _repository.getCosts();

    WalletBalance? balance = state.balance;
    List<WalletFeatureCost> costs = state.costs;
    var grokEnabled = state.grokEnabled;
    String? error;

    if (walletRes is WalletSuccess<WalletBalance>) {
      balance = walletRes.data;
    } else if (walletRes is WalletFailure<WalletBalance>) {
      error = walletRes.message;
    }

    if (costsRes is WalletSuccess<WalletCostsPayload>) {
      costs = costsRes.data.costs;
      grokEnabled = costsRes.data.grokEnabled;
    }

    emit(
      state.copyWith(
        isLoadingWallet: false,
        balance: balance,
        costs: costs,
        grokEnabled: grokEnabled,
        errorMessage: error,
        clearError: error == null,
      ),
    );
  }

  Future<void> _onLoadPackages(
    WalletLoadPackagesEvent event,
    Emitter<WalletState> emit,
  ) async {
    if (PrefUtils().isGuestAccount()) {
      emit(
        state.copyWith(
          isLoadingPackages: false,
          packages: const [],
          storeProductsReady: false,
        ),
      );
      return;
    }

    emit(state.copyWith(isLoadingPackages: true, clearError: true));
    final result = await _repository.getPackages();
    if (result is WalletFailure<List<WalletPackage>>) {
      emit(
        state.copyWith(
          isLoadingPackages: false,
          errorMessage: result.message,
        ),
      );
      return;
    }

    final packages =
        (result as WalletSuccess<List<WalletPackage>>).data;
    final skus = packages.map((p) => p.sku).where((s) => s.isNotEmpty).toSet();

    var rcLabels = <String, String>{};
    var storeReady = false;
    var storeAvailable = false;

    if (_rc.isConfigured) {
      rcLabels = await _rc.coinPriceLabels(skus);
      storeReady = true;
      storeAvailable = true;
    } else {
      await _iap.ensureInitialized();
      if (skus.isNotEmpty) {
        await _iap.queryProducts(skus);
      }
      storeReady = true;
      storeAvailable = _iap.isAvailableSync;
    }

    emit(
      state.copyWith(
        isLoadingPackages: false,
        packages: packages,
        storeProductsReady: storeReady,
        iapAvailable: storeAvailable,
        rcPriceLabels: rcLabels,
      ),
    );
  }

  Future<void> _onLoadTransactions(
    WalletLoadTransactionsEvent event,
    Emitter<WalletState> emit,
  ) async {
    if (PrefUtils().isGuestAccount()) return;

    final append = event.page > 1;
    emit(
      state.copyWith(
        isLoadingTransactions: !append,
        isLoadingMoreTransactions: append,
        clearError: true,
      ),
    );

    final result = await _repository.getTransactions(
      page: event.page,
      perPage: event.perPage,
    );
    if (result is WalletFailure<WalletTransactionsPage>) {
      emit(
        state.copyWith(
          isLoadingTransactions: false,
          isLoadingMoreTransactions: false,
          errorMessage: result.message,
        ),
      );
      return;
    }

    final page = (result as WalletSuccess<WalletTransactionsPage>).data;
    final items = append
        ? [...state.transactions, ...page.items]
        : page.items;

    emit(
      state.copyWith(
        isLoadingTransactions: false,
        isLoadingMoreTransactions: false,
        transactions: items,
        transactionsPage: page.currentPage,
        transactionsLastPage: page.lastPage,
      ),
    );
  }

  void _onApplyBalance(
    WalletApplyServerBalanceEvent event,
    Emitter<WalletState> emit,
  ) {
    emit(state.copyWith(balance: event.balance, clearError: true));
  }

  Future<void> _onBuyPackage(
    WalletBuyPackageEvent event,
    Emitter<WalletState> emit,
  ) async {
    if (PrefUtils().isGuestAccount()) {
      emit(state.copyWith(errorMessage: 'guest_required'));
      return;
    }
    if (state.isPurchasing) return;

    emit(
      state.copyWith(
        isPurchasing: true,
        purchasingSku: event.package.sku,
        clearError: true,
        clearPurchaseMessage: true,
      ),
    );

    if (_rc.isConfigured) {
      await _buyViaRevenueCat(event.package, emit);
      return;
    }

    final outcome = await _iap.buyConsumable(event.package);
    if (outcome.canceled) {
      emit(
        state.copyWith(
          isPurchasing: false,
          clearPurchasingSku: true,
        ),
      );
      return;
    }

    if (!outcome.ok || outcome.wallet == null) {
      emit(
        state.copyWith(
          isPurchasing: false,
          clearPurchasingSku: true,
          errorMessage: outcome.message.isNotEmpty
              ? outcome.message
              : 'Purchase could not be completed.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isPurchasing: false,
        clearPurchasingSku: true,
        balance: outcome.wallet,
        purchaseMessage: outcome.alreadyCredited
            ? (outcome.message.isNotEmpty
                ? outcome.message
                : 'Purchase already credited.')
            : (outcome.message.isNotEmpty
                ? outcome.message
                : 'Coins added successfully.'),
      ),
    );
  }

  Future<void> _buyViaRevenueCat(
    WalletPackage package,
    Emitter<WalletState> emit,
  ) async {
    final purchase = await _rc.purchaseCoinProduct(package.sku);
    if (purchase.canceled) {
      emit(
        state.copyWith(
          isPurchasing: false,
          clearPurchasingSku: true,
        ),
      );
      return;
    }
    if (!purchase.ok) {
      emit(
        state.copyWith(
          isPurchasing: false,
          clearPurchasingSku: true,
          errorMessage: purchase.message.isNotEmpty
              ? purchase.message
              : 'Purchase could not be completed.',
        ),
      );
      return;
    }

    final txnId = purchase.storeTransaction?.transactionIdentifier.trim() ?? '';
    if (txnId.isEmpty) {
      emit(
        state.copyWith(
          isPurchasing: false,
          clearPurchasingSku: true,
          errorMessage: 'Missing store transaction id. Please try again.',
        ),
      );
      return;
    }

    await _creditRevenueCatPurchase(
      productId: package.sku,
      storeTransactionId: txnId,
      emit: emit,
    );
  }

  Future<void> _onCreditRevenueCatPurchase(
    WalletCreditRevenueCatPurchaseEvent event,
    Emitter<WalletState> emit,
  ) async {
    if (PrefUtils().isGuestAccount()) {
      emit(state.copyWith(errorMessage: 'guest_required'));
      return;
    }
    emit(
      state.copyWith(
        isPurchasing: true,
        purchasingSku: event.productId,
        clearError: true,
        clearPurchaseMessage: true,
      ),
    );
    await _creditRevenueCatPurchase(
      productId: event.productId,
      storeTransactionId: event.storeTransactionId,
      emit: emit,
    );
  }

  Future<void> _creditRevenueCatPurchase({
    required String productId,
    required String storeTransactionId,
    required Emitter<WalletState> emit,
  }) async {
    final platform = (!kIsWeb && Platform.isIOS) ? 'ios' : 'android';
    final verify = await _repository.verifyRevenueCatPurchase(
      productId: productId,
      storeTransactionId: storeTransactionId,
      platform: platform,
    );

    if (verify is WalletFailure<WalletIapVerifyResult>) {
      emit(
        state.copyWith(
          isPurchasing: false,
          clearPurchasingSku: true,
          errorMessage: verify.message,
        ),
      );
      return;
    }

    final success = verify as WalletSuccess<WalletIapVerifyResult>;
    emit(
      state.copyWith(
        isPurchasing: false,
        clearPurchasingSku: true,
        balance: success.data.wallet,
        purchaseMessage: success.data.alreadyCredited
            ? (success.message ?? 'Purchase already credited.')
            : (success.message ?? 'Coins added successfully.'),
      ),
    );
  }

  void _onClearError(WalletClearErrorEvent event, Emitter<WalletState> emit) {
    emit(state.copyWith(clearError: true, clearPurchaseMessage: true));
  }

  void _onReset(WalletResetEvent event, Emitter<WalletState> emit) {
    emit(const WalletState());
  }

  /// Cost for [feature], or null when unknown / disabled.
  int? costFor(String feature) {
    for (final c in state.costs) {
      if (c.feature == feature) {
        if (!c.enabled) return null;
        return c.coins;
      }
    }
    return _fallbackCost(feature);
  }

  static int? _fallbackCost(String feature) {
    // Sensible defaults while costs load; server remains source of truth.
    switch (feature) {
      case WalletFeatureCost.aiOpenaiEditor:
      case WalletFeatureCost.aiGeminiEditor:
      case WalletFeatureCost.aiGrokEditor:
        return 3;
      case WalletFeatureCost.aiOpenaiImages:
        return 8;
      case WalletFeatureCost.removeBackground:
        return 0;
      default:
        return null;
    }
  }

  bool canAfford(String feature) {
    final cost = costFor(feature);
    if (cost == null) return true;
    final balance = state.balance?.balance ?? 0;
    return balance >= cost;
  }

  @override
  Future<void> close() async {
    await _iap.dispose();
    return super.close();
  }
}
