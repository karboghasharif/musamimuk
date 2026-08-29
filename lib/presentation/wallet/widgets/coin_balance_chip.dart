import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_export.dart';
import '../../../presentation/guest_upgrade/guest_upgrade_prompt.dart';
import '../bloc/wallet_bloc.dart';
import '../wallet_cost_guard.dart';

/// Compact coin balance chip for app bars / editor chrome.
class CoinBalanceChip extends StatelessWidget {
  const CoinBalanceChip({
    super.key,
    this.compact = false,
    this.lightBackground = false,
  });

  final bool compact;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    final isGuest = PrefUtils().isGuestAccount();
    final primary = theme.colorScheme.primary;

    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (prev, next) =>
          prev.balance != next.balance ||
          prev.isLoadingWallet != next.isLoadingWallet,
      builder: (context, state) {
        final displayLabel = isGuest
            ? 'lbl_coins'.tr
            : (state.isLoadingWallet && state.balance == null
                ? '…'
                : '${state.coinBalance}');

        final bg = lightBackground
            ? const Color(0xFFF5F5F5)
            : primary.withValues(alpha: 0.14);
        final fg = lightBackground ? const Color(0xFF424242) : primary;
        final iconColor =
            lightBackground ? theme.colorScheme.primary : primary;

        return Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (isGuest) {
                showGuestUpgradePrompt('msg_guest_coins_locked'.tr);
                return;
              }
              openCoinStore();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppDs.space2.h : AppDs.space3.h,
                vertical: compact ? 4.v : 6.v,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: compact ? 16.adaptSize : 18.adaptSize,
                    color: iconColor,
                  ),
                  SizedBox(width: 4.h),
                  Text(
                    displayLabel,
                    style: TextStyle(
                      color: fg,
                      fontSize: compact ? 12.fSize : 13.fSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
