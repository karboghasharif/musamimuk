import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_text_form_field.dart';

/// Requests a password reset email from the API (`POST /forgot-password`).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static Widget builder(BuildContext context) => const ForgotPasswordScreen();

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final result = await AuthRepository().requestPasswordReset(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      if (result is ForgotPasswordSuccess) {
        showAppToast(result.message, type: ToastificationType.success);
        NavigatorService.goBack();
      } else if (result is ForgotPasswordFailure) {
        showAppToast(result.message, type: ToastificationType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space4.h,
              vertical: AppDs.space6.v,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: 'lbl_forgot_password'.tr,
                  subtitle: 'msg_forgot_password_hint'.tr,
                ),
                SizedBox(height: AppDs.space6.v),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'lbl_email'.tr,
                  hintStyle: CustomTextStyles.titleMediumOnError,
                  textInputType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  prefix: Container(
                    margin: EdgeInsets.fromLTRB(28.h, 21.v, 25.h, 20.v),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgCheckmark,
                      height: 22.adaptSize,
                      width: 22.adaptSize,
                    ),
                  ),
                  prefixConstraints: BoxConstraints(maxHeight: 63.v),
                  validator: (value) {
                    if (value == null ||
                        (!isValidEmail(value, isRequired: true))) {
                      return 'err_msg_please_enter_valid_email'.tr;
                    }
                    return null;
                  },
                  borderDecoration: TextFormFieldStyleHelper.fillBlueGray,
                  fillColor: appTheme.blueGray90001,
                ),
                SizedBox(height: AppDs.space6.v),
                AppPrimaryButton(
                  label: 'lbl_send_reset_link'.tr,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
