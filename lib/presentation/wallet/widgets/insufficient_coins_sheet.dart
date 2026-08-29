import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/wallet_models.dart';
import '../wallet_cost_guard.dart';

/// Bottom sheet shown on HTTP 402 / insufficient coins.
Future<void> showInsufficientCoinsSheet(InsufficientCoinsInfo info) async {
  final context = NavigatorService.navigatorKey.currentContext;
  if (context == null) return;
  if (PrefUtils().isGuestAccount()) return;

  await showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56.adaptSize,
                height: 56.adaptSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on_outlined,
                  color: theme.colorScheme.primary,
                  size: 28.adaptSize,
                ),
              ),
              SizedBox(height: AppDs.space4.v),
              Text(
                'msg_insufficient_coins'.tr,
                textAlign: TextAlign.center,
                style: AppDs.sheetTitle(theme, color: Colors.white),
              ),
              SizedBox(height: AppDs.space2.v),
              Text(
                _bodyText(info),
                textAlign: TextAlign.center,
                style: AppDs.sheetCaption(
                  theme,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: AppDs.space6.v),
              AppPrimaryButton(
                label: 'lbl_get_coins'.tr,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openCoinStore(
                    feature: info.feature.isEmpty ? null : info.feature,
                  );
                },
              ),
              SizedBox(height: AppDs.space2.v),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'lbl_not_now'.tr,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _bodyText(InsufficientCoinsInfo info) {
  if (info.message.trim().isNotEmpty &&
      info.message.trim().toLowerCase() != 'not enough coins' &&
      info.message.trim().toLowerCase() != 'not enough coins.') {
    return info.message.trim();
  }
  if (info.required > 0) {
    return 'msg_insufficient_coins_detail'.tr
        .replaceAll('{required}', '${info.required}')
        .replaceAll('{balance}', '${info.balance}');
  }
  return 'msg_insufficient_coins_hint'.tr;
}
