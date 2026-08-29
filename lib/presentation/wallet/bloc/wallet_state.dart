part of 'wallet_bloc.dart';

class WalletState extends Equatable {
  const WalletState({
    this.bootstrapped = false,
    this.balance,
    this.costs = const [],
    this.packages = const [],
    this.transactions = const [],
    this.transactionsPage = 1,
    this.transactionsLastPage = 1,
    this.isLoadingWallet = false,
    this.isLoadingPackages = false,
    this.isLoadingTransactions = false,
    this.isLoadingMoreTransactions = false,
    this.isPurchasing = false,
    this.purchasingSku,
    this.storeProductsReady = false,
    this.iapAvailable = false,
    this.errorMessage,
    this.purchaseMessage,
  });

  final bool bootstrapped;
  final WalletBalance? balance;
  final List<WalletFeatureCost> costs;
  final List<WalletPackage> packages;
  final List<WalletTransaction> transactions;
  final int transactionsPage;
  final int transactionsLastPage;
  final bool isLoadingWallet;
  final bool isLoadingPackages;
  final bool isLoadingTransactions;
  final bool isLoadingMoreTransactions;
  final bool isPurchasing;
  final String? purchasingSku;
  final bool storeProductsReady;
  final bool iapAvailable;
  final String? errorMessage;
  final String? purchaseMessage;

  int get coinBalance => balance?.balance ?? 0;

  bool get hasMoreTransactions => transactionsPage < transactionsLastPage;

  WalletState copyWith({
    bool? bootstrapped,
    WalletBalance? balance,
    List<WalletFeatureCost>? costs,
    List<WalletPackage>? packages,
    List<WalletTransaction>? transactions,
    int? transactionsPage,
    int? transactionsLastPage,
    bool? isLoadingWallet,
    bool? isLoadingPackages,
    bool? isLoadingTransactions,
    bool? isLoadingMoreTransactions,
    bool? isPurchasing,
    String? purchasingSku,
    bool clearPurchasingSku = false,
    bool? storeProductsReady,
    bool? iapAvailable,
    String? errorMessage,
    bool clearError = false,
    String? purchaseMessage,
    bool clearPurchaseMessage = false,
  }) {
    return WalletState(
      bootstrapped: bootstrapped ?? this.bootstrapped,
      balance: balance ?? this.balance,
      costs: costs ?? this.costs,
      packages: packages ?? this.packages,
      transactions: transactions ?? this.transactions,
      transactionsPage: transactionsPage ?? this.transactionsPage,
      transactionsLastPage: transactionsLastPage ?? this.transactionsLastPage,
      isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
      isLoadingPackages: isLoadingPackages ?? this.isLoadingPackages,
      isLoadingTransactions:
          isLoadingTransactions ?? this.isLoadingTransactions,
      isLoadingMoreTransactions:
          isLoadingMoreTransactions ?? this.isLoadingMoreTransactions,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchasingSku:
          clearPurchasingSku ? null : (purchasingSku ?? this.purchasingSku),
      storeProductsReady: storeProductsReady ?? this.storeProductsReady,
      iapAvailable: iapAvailable ?? this.iapAvailable,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      purchaseMessage: clearPurchaseMessage
          ? null
          : (purchaseMessage ?? this.purchaseMessage),
    );
  }

  @override
  List<Object?> get props => [
        bootstrapped,
        balance,
        costs,
        packages,
        transactions,
        transactionsPage,
        transactionsLastPage,
        isLoadingWallet,
        isLoadingPackages,
        isLoadingTransactions,
        isLoadingMoreTransactions,
        isPurchasing,
        purchasingSku,
        storeProductsReady,
        iapAvailable,
        errorMessage,
        purchaseMessage,
      ];
}
