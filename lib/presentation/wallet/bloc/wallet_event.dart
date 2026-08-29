part of 'wallet_bloc.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Load wallet + costs on app start / after login (non-guest only).
class WalletBootstrapEvent extends WalletEvent {
  const WalletBootstrapEvent();
}

class WalletRefreshEvent extends WalletEvent {
  const WalletRefreshEvent();
}

class WalletLoadPackagesEvent extends WalletEvent {
  const WalletLoadPackagesEvent();
}

class WalletLoadTransactionsEvent extends WalletEvent {
  const WalletLoadTransactionsEvent({this.page = 1, this.perPage = 20});

  final int page;
  final int perPage;

  @override
  List<Object?> get props => [page, perPage];
}

/// Apply balance returned by a costly API or IAP verify (server truth).
class WalletApplyServerBalanceEvent extends WalletEvent {
  const WalletApplyServerBalanceEvent(this.balance);

  final WalletBalance balance;

  @override
  List<Object?> get props => [balance];
}

class WalletBuyPackageEvent extends WalletEvent {
  const WalletBuyPackageEvent(this.package);

  final WalletPackage package;

  @override
  List<Object?> get props => [package.sku];
}

class WalletClearErrorEvent extends WalletEvent {
  const WalletClearErrorEvent();
}

class WalletResetEvent extends WalletEvent {
  const WalletResetEvent();
}
