import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/navigator_service.dart';
import '../../core/utils/pref_utils.dart';
import '../../data/models/wallet_models.dart';
import 'bloc/wallet_bloc.dart';

/// Sync [WalletBloc] after login / register / upgrade / logout.
void syncWalletAfterAuth({
  WalletBalance? walletFromAuth,
  bool forceReset = false,
}) {
  final context = NavigatorService.navigatorKey.currentContext;
  if (context == null) return;

  final prefs = PrefUtils();
  final bloc = context.read<WalletBloc>();

  if (forceReset || !prefs.isLoggedIn() || prefs.isGuestAccount()) {
    bloc.add(const WalletResetEvent());
    return;
  }

  if (walletFromAuth != null) {
    bloc.add(WalletApplyServerBalanceEvent(walletFromAuth));
  }
  bloc.add(const WalletBootstrapEvent());
}
