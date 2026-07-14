import 'package:flutter/material.dart';

import '../../core/app_export.dart';

/// Bottom sheet prompting a guest to create a free account after they hit an
/// account-only action (HTTP 403). Uses the root navigator context so it can be
/// triggered from the global API interceptor.
Future<void> showGuestUpgradePrompt([String? message]) async {
  final context = NavigatorService.navigatorKey.currentContext;
  if (context == null) return;
  if (!PrefUtils().isGuestAccount()) return;

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
                  Icons.lock_open_rounded,
                  color: theme.colorScheme.primary,
                  size: 28.adaptSize,
                ),
              ),
              SizedBox(height: AppDs.space4.v),
              Text(
                'msg_guest_locked_title'.tr,
                textAlign: TextAlign.center,
                style: AppDs.sheetTitle(theme, color: Colors.white),
              ),
              SizedBox(height: AppDs.space2.v),
              Text(
                (message != null && message.trim().isNotEmpty)
                    ? message.trim()
                    : 'msg_guest_feature_locked'.tr,
                textAlign: TextAlign.center,
                style: AppDs.sheetCaption(
                  theme,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: AppDs.space6.v),
              AppPrimaryButton(
                label: 'lbl_create_account'.tr,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  NavigatorService.pushNamed(AppRoutes.guestUpgradeScreen);
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
