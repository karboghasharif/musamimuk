import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/google_brand_logo.dart';
import 'bloc/screen_0_login_bloc.dart';
import 'models/screen_0_login_model.dart';

class Screen0LoginScreen extends StatelessWidget {
  Screen0LoginScreen({super.key});
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen0LoginBloc>(
      create: (context) => Screen0LoginBloc(
        Screen0LoginState(screen0LoginModelObj: const Screen0LoginModel()),
      )..add(Screen0LoginInitialEvent()),
      child: Screen0LoginScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<Screen0LoginBloc, Screen0LoginState>(
      listener: (context, state) {
        if (state.loginSuccess) {
          NavigatorService.popAndPushNamed(AppRoutes.screen1HomeScreen);
        }
        if (state.loginError != null && state.loginError!.isNotEmpty) {
          showAppToast(
            state.loginError!,
            type: ToastificationType.error,
          );
        }
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SizedBox(
            height: SizeUtils.height,
            child: Form(
              key: _formKey,
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 43.v),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgMusammimuk02,
                          height: 250.v,
                          width: 250.h,
                        ),
                        SizedBox(height: 21.v),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 24.h),
                            child: Text(
                              "lbl_login".tr,
                              style: theme.textTheme.headlineLarge,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.v),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 247.h,
                            margin: EdgeInsets.only(left: 24.h),
                            child: Text(
                              "msg_login_to_musamimuk".tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CustomTextStyles
                                  .titleSmallVisbyRoundCFBluegray10001
                                  .copyWith(height: 1.20),
                            ),
                          ),
                        ),
                        SizedBox(height: 72.v),
                        BlocSelector<
                          Screen0LoginBloc,
                          Screen0LoginState,
                          TextEditingController?
                        >(
                          selector: (state) => state.emailController,
                          builder: (context, emailController) {
                            return CustomTextFormField(
                              controller: emailController,
                              hintText: "lbl_email".tr,
                              hintStyle: CustomTextStyles.titleMediumOnError,
                              textInputType: TextInputType.emailAddress,
                              prefix: Container(
                                margin: EdgeInsets.fromLTRB(
                                  28.h,
                                  21.v,
                                  25.h,
                                  20.v,
                                ),
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
                                if (value == null ||
                                    (!isValidEmail(value, isRequired: true))) {
                                  return "err_msg_please_enter_valid_email".tr;
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).nextFocus();
                              },
                              borderDecoration:
                                  TextFormFieldStyleHelper.fillBlueGray,
                              fillColor: appTheme.blueGray90001,
                            );
                          },
                        ),
                        SizedBox(height: 22.v),
                        BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
                          builder: (context, state) {
                            return CustomTextFormField(
                              controller: state.passwordController,
                              hintText: "lbl_password".tr,
                              hintStyle: CustomTextStyles.titleMediumOnError,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => onTapLogin(context),
                              textInputType: TextInputType.visiblePassword,
                              prefix: Container(
                                margin: EdgeInsets.fromLTRB(
                                  28.h,
                                  19.v,
                                  25.h,
                                  22.v,
                                ),
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
                                  context.read<Screen0LoginBloc>().add(
                                    ChangePasswordVisibilityEvent(
                                      value: !state.isShowPassword,
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.fromLTRB(
                                    30.h,
                                    21.v,
                                    24.h,
                                    22.v,
                                  ),
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
                              // validator: (value) {
                              //   if (value == null ||
                              //       (!isValidPassword(value, isRequired: true))) {
                              //     return "err_msg_please_enter_valid_password".tr;
                              //   }
                              //   return null;
                              // },
                              obscureText: state.isShowPassword,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 21.v,
                              ),
                              borderDecoration:
                                  TextFormFieldStyleHelper.fillBlueGray,
                              fillColor: appTheme.blueGray90001,
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(top: 8.v, right: 4.h),
                            child: InkWell(
                              onTap: () {
                                NavigatorService.pushNamed(
                                  AppRoutes.forgotPasswordScreen,
                                );
                              },
                              child: Text(
                                "lbl_forgot_password".tr,
                                style: CustomTextStyles
                                    .titleSmallVisbyRoundCFPrimary,
                              ),
                            ),
                          ),
                        ),
                        BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
                          buildWhen: (prev, curr) =>
                              prev.rememberMe != curr.rememberMe,
                          builder: (context, state) {
                            return Padding(
                              padding: EdgeInsets.only(top: 12.v),
                              child: InkWell(
                                onTap: () {
                                  context.read<Screen0LoginBloc>().add(
                                    RememberMeChangedEvent(
                                      value: !state.rememberMe,
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 48.v,
                                      width: 48.h,
                                      child: Checkbox(
                                        value: state.rememberMe,
                                        activeColor:
                                            theme.colorScheme.primary,
                                        onChanged: (v) {
                                          if (v == null) return;
                                          context.read<Screen0LoginBloc>().add(
                                            RememberMeChangedEvent(value: v),
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "lbl_remember_me".tr,
                                        style: CustomTextStyles
                                            .titleSmallVisbyRoundCFBluegray10001,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16.v),
                        BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
                          buildWhen: (prev, curr) =>
                              prev.loginError != curr.loginError ||
                              prev.isLoading != curr.isLoading ||
                              prev.isLoadingGoogle != curr.isLoadingGoogle ||
                              prev.isLoadingGuest != curr.isLoadingGuest,
                          builder: (context, state) {
                            final socialBusy =
                                state.isLoadingGoogle || state.isLoadingGuest;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (state.loginError != null &&
                                    state.loginError!.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 12.v),
                                    child: Text(
                                      state.loginError!,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                state.isLoading
                                    ? Container(
                                        height: 58.v,
                                        margin: EdgeInsets.only(
                                          left: 5.h,
                                          right: 4.h,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: SizedBox(
                                          height: 24.v,
                                          width: 24.h,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                        ),
                                      )
                                    : CustomElevatedButton(
                                        text: "lbl_login".tr,
                                        margin: EdgeInsets.only(
                                          left: 5.h,
                                          right: 4.h,
                                        ),
                                        buttonStyle:
                                            CustomButtonStyles.fillPrimary,
                                        isDisabled: socialBusy,
                                        onPressed: () {
                                          onTapLogin(context);
                                        },
                                      ),
                              ],
                            );
                          },
                        ),
                        _buildSocialSection(context),
                        SizedBox(height: 16.v),
                        InkWell(
                          onTap: () {
                            NavigatorService.pushNamed(
                              AppRoutes.screen0RegisterScreen,
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "msg_don_t_have_an_account2".tr,
                                  style: CustomTextStyles
                                      .titleSmallVisbyRoundCFBluegray300,
                                ),
                                const TextSpan(text: " "),
                                TextSpan(
                                  text: "lbl_sign_up_now".tr,
                                  style: CustomTextStyles
                                      .titleSmallVisbyRoundCFPrimary,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        SizedBox(height: 41.v),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onTapLogin(BuildContext context) {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;
    final bloc = context.read<Screen0LoginBloc>();
    final email = bloc.state.emailController?.text.trim() ?? '';
    final password = bloc.state.passwordController?.text ?? '';
    if (email.isEmpty || password.isEmpty) return;
    bloc.add(
      LoginSubmitEvent(
        email: email,
        password: password,
        rememberMe: bloc.state.rememberMe,
      ),
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    final showApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    return Padding(
      padding: EdgeInsets.only(top: 24.v),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: appTheme.blueGray700)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.h),
                child: Text(
                  "msg_or_continue_with".tr,
                  style: CustomTextStyles.titleSmallVisbyRoundCFBluegray300,
                ),
              ),
              Expanded(child: Divider(color: appTheme.blueGray700)),
            ],
          ),
          SizedBox(height: 16.v),
          BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
            buildWhen: (prev, curr) =>
                prev.isLoadingGoogle != curr.isLoadingGoogle ||
                prev.isLoadingGuest != curr.isLoadingGuest,
            builder: (context, state) {
              final socialBusy =
                  state.isLoadingGoogle || state.isLoadingGuest;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: socialBusy && !state.isLoadingGoogle
                          ? null
                          : () {
                              context.read<Screen0LoginBloc>().add(
                                    LoginWithGoogleEvent(),
                                  );
                            },
                      child: SizedBox(
                        width: double.maxFinite,
                        height: 50.v,
                        child: state.isLoadingGoogle
                            ? Center(
                                child: SizedBox(
                                  height: 22.v,
                                  width: 22.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GoogleBrandLogo(size: 22.adaptSize),
                                  SizedBox(width: 12.h),
                                  Text(
                                    "lbl_continue_with_google".tr,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: const Color(0xFF3C4043),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.v),
                  SizedBox(
                    width: double.maxFinite,
                    height: 50.v,
                    child: OutlinedButton(
                      onPressed: socialBusy && !state.isLoadingGuest
                          ? null
                          : () {
                              context.read<Screen0LoginBloc>().add(
                                    ContinueAsGuestEvent(),
                                  );
                            },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: appTheme.blueGray700),
                        foregroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.92),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: state.isLoadingGuest
                          ? SizedBox(
                              height: 22.v,
                              width: 22.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 22,
                                  color: theme.colorScheme.primary,
                                ),
                                SizedBox(width: 10.h),
                                Text(
                                  "lbl_continue_as_guest".tr,
                                  style: CustomTextStyles
                                      .titleSmallVisbyRoundCFBluegray10001,
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (showApple) ...[
                    SizedBox(height: 12.v),
                    OutlinedButton.icon(
                      onPressed: socialBusy
                          ? null
                          : () => _showSocialComingSoon(context),
                      icon: Icon(
                        Icons.apple,
                        color: theme.colorScheme.onSurface,
                      ),
                      label: Text(
                        "lbl_continue_with_apple".tr,
                        style: CustomTextStyles
                            .titleSmallVisbyRoundCFBluegray10001,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.maxFinite, 50.v),
                        side: BorderSide(color: appTheme.blueGray700),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSocialComingSoon(BuildContext context) {
    showAppToast("msg_social_login_coming_soon".tr);
  }
}
