import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/contest_user_context.dart';

typedef ContestActionCallback = void Function(String actionKey);

class ContestPrimaryActionButton extends StatelessWidget {
  const ContestPrimaryActionButton({
    super.key,
    required this.user,
    required this.onAction,
    this.isLoading = false,
    this.fallbackUser,
  });

  final ContestUserContext? user;
  final ContestUserContext? fallbackUser;
  final ContestActionCallback onAction;
  final bool isLoading;

  ContestUserContext? get _effectiveUser {
    final merged = ContestUserContext.merge(user, fallbackUser);
    if (merged != null) return merged;
    if (PrefUtils().isLoggedIn() && !PrefUtils().isGuestAccount()) {
      return const ContestUserContext(canJoin: true);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _effectiveUser;
    if (ctx == null) {
      return AppPrimaryButton(
        label: 'lbl_sign_in'.tr,
        isLoading: isLoading,
        onPressed: () => NavigatorService.pushNamed(AppRoutes.screen0LoginScreen),
      );
    }

    final primary = ctx.actionKey;
    if (primary.isEmpty) return const SizedBox.shrink();

    return AppPrimaryButton(
      label: _labelFor(primary) ?? primary,
      isLoading: isLoading,
      onPressed: () => onAction(primary),
    );
  }

  String? _labelFor(String action) {
    return switch (action) {
      'join' => 'lbl_join_contest'.tr,
      'submit' => 'lbl_submit_design'.tr,
      'gallery' => 'lbl_browse_gallery'.tr,
      'winners' => 'lbl_view_winners'.tr,
      'results' => 'lbl_view_results'.tr,
      'notify' => 'lbl_notify_upcoming'.tr,
      _ => null,
    };
  }
}
