import 'package:flutter/material.dart';

import 'package:musamimuk/core/utils/navigator_service.dart';

/// Legacy global progress dialog — prefer [runWithLoadingDialog] for new code.
class ProgressDialogUtils {
  ProgressDialogUtils._();

  static bool isProgressVisible = false;

  static void showProgressDialog({
    BuildContext? context,
    bool isCancellable = false,
  }) {
    if (isProgressVisible) return;

    final nav = NavigatorService.navigatorKey.currentState;
    final dialogContext = context ?? nav?.overlay?.context;
    if (dialogContext == null || !dialogContext.mounted) return;

    isProgressVisible = true;
    showDialog<void>(
      barrierDismissible: isCancellable,
      context: dialogContext,
      useRootNavigator: true,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    ).whenComplete(() {
      isProgressVisible = false;
    });
  }

  static void hideProgressDialog() {
    if (!isProgressVisible) return;
    final nav = NavigatorService.navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    isProgressVisible = false;
  }
}
