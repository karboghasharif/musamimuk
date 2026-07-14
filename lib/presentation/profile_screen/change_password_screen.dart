import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

/// Change password form (client-side validation). Wire [AuthRepository] when
/// a backend endpoint is available.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static Widget builder(BuildContext context) {
    return const ChangePasswordScreen();
  }

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cur = _current.text;
    final nw = _next.text;
    final cf = _confirm.text;
    if (cur.isEmpty || nw.isEmpty || cf.isEmpty) {
      showAppToast(
        'msg_fill_all_password_fields'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    if (nw.length < 8) {
      showAppToast(
        'lbl_password_too_short'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    if (nw != cf) {
      showAppToast(
        'err_msg_passwords_do_not_match'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    if (!PrefUtils().isLoggedIn()) {
      showAppToast(
        'msg_profile_requires_login'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await AuthRepository().changePassword(
        currentPassword: cur,
        newPassword: nw,
        confirmPassword: cf,
      );
      if (!mounted) return;
      if (result is ChangePasswordSuccess) {
        showAppToast(
          (result.message?.trim().isNotEmpty == true)
              ? result.message!.trim()
              : 'lbl_save'.tr,
          type: ToastificationType.success,
        );
        Navigator.pop(context);
      } else if (result is ChangePasswordFailure) {
        showAppToast(result.message, type: ToastificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space3.v,
            AppDs.space4.h,
            AppDs.space6.v,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'lbl_change_password'.tr,
                subtitle: 'msg_change_password_hint'.tr,
              ),
              SizedBox(height: AppDs.space6.v),
              AppCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LabeledPasswordField(
                      label: 'lbl_current_password'.tr,
                      controller: _current,
                      obscure: _obscureCurrent,
                      onToggleObscure: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    SizedBox(height: AppDs.space4.v),
                    _LabeledPasswordField(
                      label: 'lbl_new_password'.tr,
                      controller: _next,
                      obscure: _obscureNext,
                      onToggleObscure: () =>
                          setState(() => _obscureNext = !_obscureNext),
                    ),
                    SizedBox(height: AppDs.space4.v),
                    _LabeledPasswordField(
                      label: 'lbl_confirm_new_password'.tr,
                      controller: _confirm,
                      obscure: _obscureConfirm,
                      onToggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppDs.space6.v),
              AppPrimaryButton(
                label: 'lbl_save'.tr,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledPasswordField extends StatelessWidget {
  const _LabeledPasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, variant: AppTextVariant.caption),
        SizedBox(height: AppDs.space2.v),
        Container(
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: AppTypography.body(theme),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppDs.space4.h,
                vertical: AppDs.space4.v,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppDs.textOnDarkSecondary,
                  size: AppDs.iconMd.adaptSize,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
