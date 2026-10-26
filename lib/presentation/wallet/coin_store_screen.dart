import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/revenue_cat/revenue_cat_service.dart';
import '../../presentation/guest_upgrade/guest_upgrade_prompt.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/wallet_bloc.dart';
import 'widgets/coin_balance_chip.dart';

class CoinStoreScreen extends StatelessWidget {
  const CoinStoreScreen({super.key});

  static Widget builder(BuildContext context) {
    // WalletBloc is provided at app root.
    return const CoinStoreScreen();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = PrefUtils().isGuestAccount();

    return Scaffold(
      backgroundColor: AppDs.surfaceBase,
      appBar: CustomAppBar(
        leading: AppbarLeadingImage(
          imagePath: ImageConstant.imgArrowDownPrimary,
          onTap: () => NavigatorService.goBack(),
        ),
        centerTitle: true,
        title: AppbarTitle(text: 'lbl_coin_store'.tr),
        actions: [
          if (!isGuest)
            Padding(
              padding: EdgeInsetsDirectional.only(end: AppDs.space3.h),
              child: const Center(child: CoinBalanceChip()),
            ),
        ],
      ),
      body: isGuest ? const _GuestCoinsLockedBody() : const _CoinStoreBody(),
    );
  }
}

class _GuestCoinsLockedBody extends StatelessWidget {
  const _GuestCoinsLockedBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppDs.space6.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.monetization_on_outlined,
            size: 64.adaptSize,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: AppDs.space4.v),
          AppText(
            'msg_guest_coins_locked'.tr,
            variant: AppTextVariant.body,
            color: AppDs.textOnDarkSecondary,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDs.space6.v),
          AppPrimaryButton(
            label: 'lbl_create_account'.tr,
            onPressed: () {
              showGuestUpgradePrompt('msg_guest_coins_locked'.tr);
            },
          ),
        ],
      ),
    );
  }
}

class _CoinStoreBody extends StatefulWidget {
  const _CoinStoreBody();

  @override
  State<_CoinStoreBody> createState() => _CoinStoreBodyState();
}

class _CoinStoreBodyState extends State<_CoinStoreBody> {
  bool _openingPaywall = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<WalletBloc>();
    bloc.add(const WalletRefreshEvent());
    bloc.add(const WalletLoadPackagesEvent());
  }

  Future<void> _openCoinsPaywall() async {
    if (_openingPaywall) return;
    final bloc = context.read<WalletBloc>();
    if (bloc.state.isPurchasing) return;

    setState(() => _openingPaywall = true);
    try {
      final result = await RevenueCatService.instance.presentCoinsPaywall(
        onPurchaseCompleted: (info, transaction) {
          final productId = transaction.productIdentifier.trim();
          final txnId = transaction.transactionIdentifier.trim();
          if (productId.isEmpty || txnId.isEmpty) return;
          bloc.add(
            WalletCreditRevenueCatPurchaseEvent(
              productId: productId,
              storeTransactionId: txnId,
            ),
          );
        },
      );
      if (!mounted) return;
      if (result == PaywallResult.error) {
        showAppToast(
          'msg_coin_paywall_error'.tr,
          type: ToastificationType.error,
        );
      }
      bloc.add(const WalletRefreshEvent());
    } finally {
      if (mounted) setState(() => _openingPaywall = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage ||
          prev.purchaseMessage != next.purchaseMessage,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          if (state.errorMessage == 'guest_required') {
            showGuestUpgradePrompt('msg_guest_coins_locked'.tr);
          } else {
            showAppToast(state.errorMessage!, type: ToastificationType.error);
          }
          context.read<WalletBloc>().add(const WalletClearErrorEvent());
        } else if (state.purchaseMessage != null &&
            state.purchaseMessage!.isNotEmpty) {
          showAppToast(
            state.purchaseMessage!,
            type: ToastificationType.success,
          );
          context.read<WalletBloc>().add(const WalletClearErrorEvent());
        }
      },
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state.isLoadingPackages && state.packages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<WalletBloc>();
              bloc.add(const WalletRefreshEvent());
              bloc.add(const WalletLoadPackagesEvent());
              await bloc.stream.firstWhere((s) => !s.isLoadingPackages);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space4.v,
                AppDs.space4.h,
                AppDs.space8.v,
              ),
              children: [
                _BalanceHeader(balance: state.coinBalance),
                SizedBox(height: AppDs.space2.v),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => NavigatorService.pushNamed(
                      AppRoutes.walletTransactionsScreen,
                    ),
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      color: theme.colorScheme.primary,
                      size: 18.adaptSize,
                    ),
                    label: Text(
                      'lbl_wallet_transactions'.tr,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space3.v),
                AppText(
                  'msg_coin_store_subtitle'.tr,
                  variant: AppTextVariant.secondary,
                  color: AppDs.textOnDarkSecondary,
                ),
                SizedBox(height: AppDs.space4.v),
                if (RevenueCatService.instance.isConfigured) ...[
                  AppPrimaryButton(
                    label: 'lbl_buy_coins'.tr,
                    isLoading: _openingPaywall || state.isPurchasing,
                    onPressed: (_openingPaywall || state.isPurchasing)
                        ? null
                        : _openCoinsPaywall,
                  ),
                  SizedBox(height: AppDs.space4.v),
                ],
                if (state.packages.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppDs.space8.v),
                    child: AppText(
                      'msg_coin_packages_empty'.tr,
                      variant: AppTextVariant.body,
                      color: AppDs.textOnDarkSecondary,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...state.packages.map(
                    (pkg) => Padding(
                      padding: EdgeInsets.only(bottom: AppDs.space3.v),
                      child: _PackageTile(
                        package: pkg,
                        product: context
                            .read<WalletBloc>()
                            .iapService
                            .productForSku(pkg.sku),
                        rcPriceLabel: state.rcPriceLabels[pkg.sku],
                        purchasing: state.isPurchasing &&
                            state.purchasingSku == pkg.sku,
                        disabled: state.isPurchasing,
                        onBuy: () {
                          context
                              .read<WalletBloc>()
                              .add(WalletBuyPackageEvent(pkg));
                        },
                      ),
                    ),
                  ),
                if (!state.iapAvailable && state.storeProductsReady) ...[
                  SizedBox(height: AppDs.space4.v),
                  AppText(
                    'msg_iap_unavailable'.tr,
                    variant: AppTextVariant.caption,
                    color: AppDs.textOnDarkSecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDs.space4.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: theme.colorScheme.primary,
            size: 28.adaptSize,
          ),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'lbl_your_balance'.tr,
                  variant: AppTextVariant.caption,
                  color: AppDs.textOnDarkSecondary,
                ),
                AppText(
                  '$balance ${'lbl_coins'.tr}',
                  variant: AppTextVariant.title,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.onBuy,
    this.product,
    this.rcPriceLabel,
    this.purchasing = false,
    this.disabled = false,
  });

  final WalletPackage package;
  final ProductDetails? product;
  final String? rcPriceLabel;
  final VoidCallback onBuy;
  final bool purchasing;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final priceLabel = (rcPriceLabel != null && rcPriceLabel!.isNotEmpty)
        ? rcPriceLabel!
        : (product?.price ??
            _formatMicros(package.priceMicros, package.currency));
    final bonus = package.bonusCoins;

    return Container(
      padding: EdgeInsets.all(AppDs.space4.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.adaptSize,
            height: 48.adaptSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  package.title.isNotEmpty
                      ? package.title
                      : package.sku,
                  variant: AppTextVariant.title,
                  color: Colors.white,
                ),
                SizedBox(height: 2.v),
                AppText(
                  bonus > 0
                      ? 'msg_coins_with_bonus'
                          .tr
                          .replaceAll('{coins}', '${package.coins}')
                          .replaceAll('{bonus}', '$bonus')
                      : 'msg_coins_amount'
                          .tr
                          .replaceAll('{coins}', '${package.displayTotalCoins}'),
                  variant: AppTextVariant.caption,
                  color: AppDs.textOnDarkSecondary,
                ),
              ],
            ),
          ),
          SizedBox(width: AppDs.space2.h),
          SizedBox(
            height: 40.v,
            child: ElevatedButton(
              onPressed: disabled ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: AppDs.onAccent,
                disabledBackgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.4),
                padding: EdgeInsets.symmetric(horizontal: AppDs.space3.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
                ),
              ),
              child: purchasing
                  ? SizedBox(
                      width: 18.adaptSize,
                      height: 18.adaptSize,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      priceLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.fSize,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMicros(int micros, String currency) {
    if (micros <= 0) return 'lbl_buy'.tr;
    final amount = micros / 1000000.0;
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}
