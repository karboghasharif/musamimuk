import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/wallet_models.dart';
import '../guest_upgrade/guest_upgrade_prompt.dart';
import 'bloc/wallet_bloc.dart';
import 'widgets/insufficient_coins_sheet.dart';

/// Pre-flight checks before spending coins on a costly feature.
///
/// Returns `true` when the caller may proceed with the API call.
/// Never mutates local balance — spend happens only on the server.
Future<bool> ensureCanSpendCoins({
  required BuildContext context,
  required String feature,
  bool showFeedback = true,
}) async {
  final prefs = PrefUtils();
  if (!prefs.isLoggedIn()) {
    SessionManager.instance.requireAuthenticated();
    return false;
  }
  if (prefs.isGuestAccount()) {
    if (showFeedback) {
      await showGuestUpgradePrompt('msg_guest_coins_locked'.tr);
    }
    return false;
  }

  final bloc = context.read<WalletBloc>();
  if (!bloc.state.bootstrapped || bloc.state.costs.isEmpty) {
    bloc.add(const WalletRefreshEvent());
    // Brief wait for costs/balance; still proceed to server if slow.
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  final cost = bloc.costFor(feature);
  // Free features (cost 0) skip the insufficient-coins sheet.
  if (cost != null && cost > 0 && !bloc.canAfford(feature)) {
    if (showFeedback) {
      await showInsufficientCoinsSheet(
        InsufficientCoinsInfo(
          balance: bloc.state.coinBalance,
          required: cost,
          shortage: cost - bloc.state.coinBalance,
          feature: feature,
          message: 'msg_insufficient_coins'.tr,
        ),
      );
    }
    return false;
  }
  return true;
}

/// Apply wallet snapshot from a successful costly API response body.
void applyWalletFromApiEnvelope(
  BuildContext context,
  Map<String, dynamic>? envelope,
) {
  if (envelope == null || !context.mounted) return;
  final payload = apiExtractPayloadMap(envelope) ?? envelope;
  final wallet = walletBalanceFromPayload(payload) ??
      walletBalanceFromPayload(envelope);
  if (wallet == null) return;
  context.read<WalletBloc>().add(WalletApplyServerBalanceEvent(wallet));
}

/// Open coin store (or guest upgrade).
void openCoinStore({String? feature}) {
  if (PrefUtils().isGuestAccount()) {
    showGuestUpgradePrompt('msg_guest_coins_locked'.tr);
    return;
  }
  if (!SessionManager.instance.requireAuthenticated(
    routeName: AppRoutes.coinStoreScreen,
  )) {
    return;
  }
  NavigatorService.pushNamed(
    AppRoutes.coinStoreScreen,
    arguments: feature == null ? null : {'feature': feature},
  );
}

void toastWalletError(String message) {
  if (message.trim().isEmpty) return;
  showAppToast(message, type: ToastificationType.error);
}
