import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
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
    final result = await AuthRepository().requestPasswordReset(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result is ForgotPasswordSuccess) {
      showAppToast(result.message, type: ToastificationType.success);
      NavigatorService.goBack();
    } else if (result is ForgotPasswordFailure) {
      showAppToast(result.message, type: ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('lbl_forgot_password'.tr),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 24.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'msg_forgot_password_hint'.tr,
                  style: CustomTextStyles.titleSmallVisbyRoundCFBluegray10001
                      .copyWith(height: 1.35),
                ),
                SizedBox(height: 24.v),
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
                SizedBox(height: 28.v),
                _loading
                    ? Center(
                        child: SizedBox(
                          height: 48.v,
                          width: 48.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : CustomElevatedButton(
                        text: 'lbl_send_reset_link'.tr,
                        buttonStyle: CustomButtonStyles.fillPrimary,
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
