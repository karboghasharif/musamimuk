import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/repositories/auth_repository.dart';

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
  static const Color _pageBackground = Color(0xFF282C31);
  static const Color _fieldBackground = Color(0xFF343A40);

  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;

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
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return SafeArea(
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(
            'lbl_change_password'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.v),
              Text(
                'msg_change_password_hint'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                ),
              ),
              SizedBox(height: 28.v),
              _LabeledPasswordField(
                label: 'lbl_current_password'.tr,
                controller: _current,
                obscure: _obscureCurrent,
                fieldBg: _fieldBackground,
                onToggleObscure: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              SizedBox(height: 18.v),
              _LabeledPasswordField(
                label: 'lbl_new_password'.tr,
                controller: _next,
                obscure: _obscureNext,
                fieldBg: _fieldBackground,
                onToggleObscure: () =>
                    setState(() => _obscureNext = !_obscureNext),
              ),
              SizedBox(height: 18.v),
              _LabeledPasswordField(
                label: 'lbl_confirm_new_password'.tr,
                controller: _confirm,
                obscure: _obscureConfirm,
                fieldBg: _fieldBackground,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              SizedBox(height: 36.v),
              SizedBox(
                height: 52.v,
                child: FilledButton(
                  onPressed: () async => _submit(),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.h),
                    ),
                  ),
                  child: Text(
                    'lbl_save'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.v),
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
    required this.fieldBg,
    required this.onToggleObscure,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final Color fieldBg;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.v),
        Container(
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.h,
                vertical: 16.v,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white54,
                  size: 22.adaptSize,
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
