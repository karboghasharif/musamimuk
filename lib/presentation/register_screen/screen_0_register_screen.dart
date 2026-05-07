import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/screen_0_register_bloc.dart';
import 'models/screen_0_register_model.dart';

class Screen0RegisterScreen extends StatefulWidget {
  const Screen0RegisterScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<Screen0RegisterBloc>(
      create: (context) => Screen0RegisterBloc(Screen0RegisterState(
        screen0RegisterModelObj: const Screen0RegisterModel(),
      ))
        ..add(Screen0RegisterInitialEvent()),
      child: const Screen0RegisterScreen(),
    );
  }

  @override
  State<Screen0RegisterScreen> createState() => _Screen0RegisterScreenState();
}

class _Screen0RegisterScreenState extends State<Screen0RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<Screen0RegisterBloc, Screen0RegisterState>(
      listener: (context, state) {
        if (state.registerSuccess) {
          NavigatorService.pushReplacementNamed(
            AppRoutes.completeProfileScreen,
          );
        }
        if (state.registerError != null && state.registerError!.isNotEmpty) {
          showAppToast(
            state.registerError!,
            type: ToastificationType.error,
          );
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: appTheme.blueGray90004,
          resizeToAvoidBottomInset: false,
          body: Form(
            key: _formKey,
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  SizedBox(height: 43.v),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        margin: EdgeInsets.only(bottom: 85.v),
                        padding: EdgeInsets.symmetric(horizontal: 20.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomImageView(
                              imagePath: ImageConstant.imgMusammimuk02,
                              height: 269.v,
                              width: 276.h,
                              alignment: Alignment.center,
                            ),
                            SizedBox(height: 21.v),
                            Padding(
                              padding: EdgeInsets.only(left: 24.h),
                              child: Text(
                                "lbl_register".tr,
                                style: theme.textTheme.headlineLarge,
                              ),
                            ),
                            SizedBox(height: 9.v),
                            Padding(
                              padding: EdgeInsets.only(left: 24.h),
                              child: Text(
                                "msg_make_your_own_account".tr,
                                style: CustomTextStyles
                                    .titleSmallVisbyRoundCFBluegray10001,
                              ),
                            ),
                            SizedBox(height: 69.v),
                            _buildUserProfile(context),
                            SizedBox(height: 22.v),
                            _buildEmailOrMobileField(context),
                            SizedBox(height: 22.v),
                            _buildPasswordField(context),
                            _buildPasswordStrengthFeedback(),
                            SizedBox(height: 22.v),
                            _buildPasswordConfirmationField(context),
                            _buildConfirmMatchFeedback(),
                            SizedBox(height: 84.v),
                            _buildRegisterButton(context),
                            SizedBox(height: 16.v),
                            InkWell(
                              onTap: () {
                                NavigatorService.pushNamed(
                                  AppRoutes.screen0LoginScreen,
                                );
                              },
                              child: Align(
                                alignment: Alignment.center,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "msg_already_have_an2".tr,
                                        style: CustomTextStyles
                                            .titleSmallVisbyRoundCFBluegray300,
                                      ),
                                      const TextSpan(text: " "),
                                      TextSpan(
                                        text: "lbl_login".tr,
                                        style: CustomTextStyles
                                            .titleSmallVisbyRoundCFPrimary,
                                      )
                                    ],
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 1.h),
      child: BlocSelector<Screen0RegisterBloc, Screen0RegisterState,
          TextEditingController?>(
        selector: (state) => state.userProfileController,
        builder: (context, userProfileController) {
          return CustomTextFormField(
            controller: userProfileController,
            hintText: "lbl_name_or_username".tr,
            hintStyle: CustomTextStyles.titleMediumOnError,
            textInputAction: TextInputAction.next,
            prefix: Container(
              margin: EdgeInsets.fromLTRB(28.h, 20.v, 23.h, 19.v),
              child: CustomImageView(
                imagePath: ImageConstant.imgLock,
                height: 24.adaptSize,
                width: 24.adaptSize,
              ),
            ),
            prefixConstraints: BoxConstraints(
              maxHeight: 63.v,
            ),
            validator: (value) {
              final t = value?.trim() ?? '';
              if (t.length < 2) {
                return "err_msg_please_enter_valid_text".tr;
              }
              return null;
            },
            borderDecoration: TextFormFieldStyleHelper.fillBlueGray,
            fillColor: appTheme.blueGray90001,
          );
        },
      ),
    );
  }

  Widget _buildEmailOrMobileField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 1.h),
      child: BlocSelector<Screen0RegisterBloc, Screen0RegisterState,
          TextEditingController?>(
        selector: (state) => state.emailFieldController,
        builder: (context, emailFieldController) {
          return CustomTextFormField(
            controller: emailFieldController,
            hintText: "lbl_email_or_mobile".tr,
            hintStyle: CustomTextStyles.titleMediumOnError,
            textInputAction: TextInputAction.next,
            textInputType: TextInputType.text,
            prefix: Container(
              margin: EdgeInsets.fromLTRB(28.h, 21.v, 25.h, 20.v),
              child: CustomImageView(
                imagePath: ImageConstant.imgCheckmark,
                height: 22.adaptSize,
                width: 22.adaptSize,
              ),
            ),
            prefixConstraints: BoxConstraints(
              maxHeight: 63.v,
            ),
            validator: (value) {
              if (!isValidEmailOrPhone(value, isRequired: true)) {
                return "err_msg_please_enter_valid_email_or_phone".tr;
              }
              return null;
            },
            borderDecoration: TextFormFieldStyleHelper.fillBlueGray,
            fillColor: appTheme.blueGray90001,
          );
        },
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 1.h),
      child: BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFormField(
                controller: state.passwordFieldController,
                hintText: "lbl_password".tr,
                hintStyle: CustomTextStyles.titleMediumOnError,
                textInputAction: TextInputAction.next,
                textInputType: TextInputType.visiblePassword,
                onChanged: (_) => _refresh(),
                prefix: Container(
                  margin: EdgeInsets.fromLTRB(28.h, 19.v, 25.h, 22.v),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgLocation,
                    height: 22.adaptSize,
                    width: 22.adaptSize,
                  ),
                ),
                prefixConstraints: BoxConstraints(
                  maxHeight: 63.v,
                ),
                suffix: InkWell(
                  onTap: () {
                    context.read<Screen0RegisterBloc>().add(
                        ChangePasswordVisibilityEvent(
                            value: !state.isShowPassword));
                  },
                  child: Container(
                    margin: EdgeInsets.fromLTRB(30.h, 21.v, 24.h, 22.v),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgEye,
                      height: 20.adaptSize,
                      width: 20.adaptSize,
                    ),
                  ),
                ),
                suffixConstraints: BoxConstraints(
                  maxHeight: 63.v,
                ),
                validator: (value) {
                  if (value == null ||
                      (!isValidPassword(value, isRequired: true))) {
                    return "err_msg_please_enter_valid_password".tr;
                  }
                  return null;
                },
                obscureText: state.isShowPassword,
                contentPadding: EdgeInsets.symmetric(vertical: 21.v),
                borderDecoration: TextFormFieldStyleHelper.fillBlueGray,
                fillColor: appTheme.blueGray90001,
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.h, top: 8.v, right: 8.h),
                child: Text(
                  'msg_password_requirements_hint'.tr,
                  style: CustomTextStyles.titleSmallVisbyRoundCFBluegray300
                      .copyWith(height: 1.35, fontSize: 12.fSize),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordStrengthFeedback() {
    final state = context.read<Screen0RegisterBloc>().state;
    final raw = state.passwordFieldController?.text ?? '';
    final level = classifyPasswordStrength(raw);
    if (level == PasswordStrengthLevel.empty) {
      return SizedBox(height: 8.v);
    }
    final ok = level == PasswordStrengthLevel.strong;
    final label = switch (level) {
      PasswordStrengthLevel.tooShort => 'lbl_password_too_short'.tr,
      PasswordStrengthLevel.weak => 'lbl_password_needs_more'.tr,
      PasswordStrengthLevel.strong => 'lbl_password_strength_strong'.tr,
      PasswordStrengthLevel.empty => '',
    };
    return Padding(
      padding: EdgeInsets.only(left: 4.h, top: 6.v),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 18.adaptSize,
            color: ok ? Colors.greenAccent : theme.colorScheme.error,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: Text(
              label,
              style: CustomTextStyles.titleSmallVisbyRoundCFBluegray10001
                  .copyWith(
                color: ok ? Colors.greenAccent : theme.colorScheme.error,
                fontSize: 13.fSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordConfirmationField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 1.h),
      child: BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
        builder: (context, state) {
          return CustomTextFormField(
            controller: state.passwordConfirmationController,
            hintText: "lbl_confirm_password".tr,
            hintStyle: CustomTextStyles.titleMediumOnError,
            textInputAction: TextInputAction.done,
            textInputType: TextInputType.visiblePassword,
            onChanged: (_) => _refresh(),
            prefix: Container(
              margin: EdgeInsets.fromLTRB(28.h, 19.v, 25.h, 22.v),
              child: CustomImageView(
                imagePath: ImageConstant.imgLocation,
                height: 22.adaptSize,
                width: 22.adaptSize,
              ),
            ),
            prefixConstraints: BoxConstraints(maxHeight: 63.v),
            suffix: InkWell(
              onTap: () {
                context.read<Screen0RegisterBloc>().add(
                    ChangePasswordVisibilityEvent(
                        value: !state.isShowPassword));
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(30.h, 21.v, 24.h, 22.v),
                child: CustomImageView(
                  imagePath: ImageConstant.imgEye,
                  height: 20.adaptSize,
                  width: 20.adaptSize,
                ),
              ),
            ),
            suffixConstraints: BoxConstraints(maxHeight: 63.v),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "err_msg_please_enter_valid_password".tr;
              }
              final password =
                  context.read<Screen0RegisterBloc>().state.passwordFieldController?.text ?? '';
              if (value != password) {
                return "err_msg_passwords_do_not_match".tr;
              }
              return null;
            },
            obscureText: state.isShowPassword,
            contentPadding: EdgeInsets.symmetric(vertical: 21.v),
            borderDecoration: TextFormFieldStyleHelper.fillBlueGray,
            fillColor: appTheme.blueGray90001,
          );
        },
      ),
    );
  }

  Widget _buildConfirmMatchFeedback() {
    final state = context.read<Screen0RegisterBloc>().state;
    final a = state.passwordFieldController?.text ?? '';
    final b = state.passwordConfirmationController?.text ?? '';
    if (b.isEmpty) {
      return SizedBox(height: 8.v);
    }
    final match = a == b;
    return Padding(
      padding: EdgeInsets.only(left: 4.h, top: 6.v),
      child: Row(
        children: [
          Icon(
            match ? Icons.check_circle : Icons.cancel,
            size: 18.adaptSize,
            color: match ? Colors.greenAccent : theme.colorScheme.error,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: Text(
              match
                  ? 'lbl_passwords_match'.tr
                  : 'lbl_passwords_do_not_match'.tr,
              style: CustomTextStyles.titleSmallVisbyRoundCFBluegray10001
                  .copyWith(
                color: match ? Colors.greenAccent : theme.colorScheme.error,
                fontSize: 13.fSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
      buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          return Container(
            height: 58.v,
            margin: EdgeInsets.only(left: 5.h, right: 4.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: 24.v,
              width: 24.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }
        return CustomElevatedButton(
          text: "lbl_register".tr,
          margin: EdgeInsets.only(left: 5.h, right: 4.h),
          buttonStyle: CustomButtonStyles.fillPrimary,
          onPressed: () => _onTapRegister(context),
        );
      },
    );
  }

  void _onTapRegister(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<Screen0RegisterBloc>();
    final name = bloc.state.userProfileController?.text.trim() ?? '';
    final email = bloc.state.emailFieldController?.text.trim() ?? '';
    final password = bloc.state.passwordFieldController?.text ?? '';
    final passwordConfirmation =
        bloc.state.passwordConfirmationController?.text ?? '';
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return;
    }
    bloc.add(RegisterSubmitEvent(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    ));
  }
}
