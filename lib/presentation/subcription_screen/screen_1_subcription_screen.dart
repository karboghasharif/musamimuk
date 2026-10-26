import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/config/revenue_cat_config.dart';
import '../../core/utils/app_toast.dart';
import '../../data/services/revenue_cat/revenue_cat_service.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_1_subcription_bloc.dart';
import 'models/screen_1_subcription_model.dart';

class Screen1SubcriptionScreen extends StatelessWidget {
  const Screen1SubcriptionScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<Screen1SubcriptionBloc>(
      create: (context) => Screen1SubcriptionBloc(
        Screen1SubcriptionState(
          screen1SubcriptionModelObj: const Screen1SubcriptionModel(),
        ),
      )..add(Screen1SubcriptionInitialEvent()),
      child: const Screen1SubcriptionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _SubscriptionView();
  }
}

class _SubscriptionView extends StatefulWidget {
  const _SubscriptionView();

  @override
  State<_SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<_SubscriptionView> {
  final _rc = RevenueCatService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // ignore: unawaited_futures
    _rc.refreshCustomerInfo();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPaywall() async {
    await _runBusy(() async {
      if (!_rc.isConfigured) {
        showAppToast(
          'msg_subscription_unavailable'.tr,
          type: ToastificationType.warning,
        );
        return;
      }
      final result = await _rc.presentPaywall(onlyIfNeeded: true);
      if (!mounted) return;
      switch (result) {
        case PaywallResult.purchased:
        case PaywallResult.restored:
          showAppToast(
            'msg_subscription_unlocked'.tr,
            type: ToastificationType.success,
          );
        case PaywallResult.cancelled:
        case PaywallResult.notPresented:
          break;
        case PaywallResult.error:
          showAppToast(
            'msg_subscription_error'.tr,
            type: ToastificationType.error,
          );
      }
      await _rc.refreshCustomerInfo();
    });
  }

  Future<void> _restore() async {
    await _runBusy(() async {
      final outcome = await _rc.restorePurchases();
      if (!mounted) return;
      if (outcome.canceled) return;
      if (!outcome.ok) {
        showAppToast(
          outcome.message.isNotEmpty
              ? outcome.message
              : 'msg_subscription_restore_failed'.tr,
          type: ToastificationType.error,
        );
        return;
      }
      showAppToast(
        outcome.unlockedPro
            ? 'msg_subscription_unlocked'.tr
            : 'msg_subscription_restore_none'.tr,
        type: outcome.unlockedPro
            ? ToastificationType.success
            : ToastificationType.info,
      );
    });
  }

  Future<void> _openCustomerCenter() async {
    await _runBusy(() async {
      await _rc.presentCustomerCenter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowDownPrimary,
            onTap: () => NavigatorService.goBack(),
          ),
          centerTitle: true,
          title: AppbarTitle(text: 'msg_choose_your_plan'.tr),
        ),
        body: ValueListenableBuilder(
          valueListenable: _rc.customerInfo,
          builder: (context, info, _) {
            final isPro = RevenueCatService.isProEntitlementActive(info);
            final entitlement = _rc.proEntitlement(info);
            final productId = entitlement?.productIdentifier;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space4.v,
                AppDs.space4.h,
                AppDs.space8.v,
              ),
              child: Column(
                children: [
                  AppPageHeader(
                    title: isPro
                        ? 'msg_subscription_active_title'.tr
                        : 'msg_choose_your_plan'.tr,
                    subtitle: isPro
                        ? 'msg_subscription_active_subtitle'.tr
                        : 'msg_upgrade_to_access'.tr,
                    align: TextAlign.center,
                  ),
                  SizedBox(height: AppDs.space6.v),
                  CustomImageView(
                    imagePath: ImageConstant.imgGroup16,
                    height: 160.v,
                    width: 240.h,
                  ),
                  SizedBox(height: AppDs.space8.v),
                  _StatusCard(
                    isPro: isPro,
                    productId: productId,
                    entitlementId: RevenueCatConfig.entitlementPro,
                  ),
                  SizedBox(height: AppDs.space4.v),
                  if (!isPro) ...[
                    AppPrimaryButton(
                      label: 'lbl_subscribe'.tr,
                      onPressed: _busy ? null : _openPaywall,
                    ),
                    SizedBox(height: AppDs.space3.v),
                    AppSecondaryButton(
                      label: 'lbl_restore_purchases'.tr,
                      onPressed: _busy ? null : _restore,
                    ),
                  ] else ...[
                    AppPrimaryButton(
                      label: 'lbl_manage_subscription'.tr,
                      onPressed: _busy ? null : _openCustomerCenter,
                    ),
                    SizedBox(height: AppDs.space3.v),
                    AppSecondaryButton(
                      label: 'lbl_view_plans'.tr,
                      onPressed: _busy
                          ? null
                          : () => _runBusy(() async {
                                await _rc.presentPaywall(onlyIfNeeded: false);
                                await _rc.refreshCustomerInfo();
                              }),
                    ),
                  ],
                  if (_busy) ...[
                    SizedBox(height: AppDs.space6.v),
                    const CircularProgressIndicator(),
                  ],
                  SizedBox(height: AppDs.space6.v),
                  AppText(
                    'msg_subscription_products_hint'.tr,
                    variant: AppTextVariant.secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isPro,
    required this.entitlementId,
    this.productId,
  });

  final bool isPro;
  final String entitlementId;
  final String? productId;

  String get _planLabel {
    switch (productId) {
      case RevenueCatConfig.productLifetime:
        return 'lbl_plan_lifetime'.tr;
      case RevenueCatConfig.productYearly:
        return 'lbl_plan_yearly'.tr;
      case RevenueCatConfig.productMonthly:
        return 'lbl_plan_monthly'.tr;
      default:
        return isPro ? 'lbl_pro'.tr : 'lbl_free'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: isPro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                isPro ? 'lbl_premium'.tr : 'lbl_basic'.tr,
                variant: AppTextVariant.title,
              ),
              AppText(
                _planLabel,
                variant: isPro ? AppTextVariant.accent : AppTextVariant.body,
              ),
            ],
          ),
          SizedBox(height: AppDs.space3.v),
          AppText(
            isPro
                ? 'msg_access_to_all_design'.tr
                : 'msg_access_to_few_design'.tr,
            variant: AppTextVariant.secondary,
          ),
          SizedBox(height: AppDs.space2.v),
          AppText(
            '${'lbl_entitlement'.tr}: $entitlementId',
            variant: AppTextVariant.secondary,
          ),
        ],
      ),
    );
  }
}
