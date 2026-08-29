import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/google_brand_logo.dart';
import 'bloc/screen_0_login_bloc.dart';

class Screen0LoginScreen extends StatelessWidget {
  Screen0LoginScreen({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static Widget builder(BuildContext context) {
    return BlocProvider<Screen0LoginBloc>(
      create: (context) =>
          Screen0LoginBloc()..add(Screen0LoginInitialEvent()),
      child: Screen0LoginScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<Screen0LoginBloc, Screen0LoginState>(
      listener: (context, state) {
        if (state.loginSuccess) {
          SessionManager.instance.navigateAfterLogin();
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
          backgroundColor: AppDs.surfaceBase,
          resizeToAvoidBottomInset: true,
          body: BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
            buildWhen: (prev, curr) =>
                prev.isLoading != curr.isLoading ||
                prev.isLoadingGoogle != curr.isLoadingGoogle ||
                prev.isLoadingApple != curr.isLoadingApple ||
                prev.isLoadingGuest != curr.isLoadingGuest,
            builder: (context, state) {
              final authBusy = state.isLoading ||
                  state.isLoadingGoogle ||
                  state.isLoadingApple ||
                  state.isLoadingGuest;
              return AppLoadingOverlay(
                isLoading: authBusy,
                message: 'msg_signing_in'.tr,
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          AppDs.space4.h,
                          AppDs.space4.v,
                          AppDs.space4.h,
                          AppDs.space8.v,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight -
                                AppDs.space4.v -
                                AppDs.space8.v,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHero(context),
                                SizedBox(height: AppDs.space6.v),
                                _buildHeader(context),
                                SizedBox(height: AppDs.space6.v),
                                _buildEmailField(context),
                                SizedBox(height: AppDs.space3.v),
                                _buildPasswordField(context),
                                _buildForgotPassword(context),
                                _buildRememberMe(context),
                                SizedBox(height: AppDs.space4.v),
                                _buildLoginButton(context),
                                _buildSocialSection(context),
                                SizedBox(height: AppDs.space6.v),
                                _buildSignUpPrompt(context),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return AppFadeIn(
      child: Center(
        child: Container(
          padding: EdgeInsets.all(AppDs.space4.h),
          decoration: AppDs.cardDecoration(),
          child: CustomImageView(
            imagePath: ImageConstant.imgMusammimuk02,
            height: 120.adaptSize,
            width: 120.adaptSize,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppPageHeader(
      title: 'lbl_login'.tr,
      subtitle: 'msg_login_to_musamimuk'.tr,
      align: TextAlign.start,
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return BlocSelector<Screen0LoginBloc, Screen0LoginState,
        TextEditingController?>(
      selector: (state) => state.emailController,
      builder: (context, emailController) {
        return AppTextField(
          controller: emailController,
          label: 'lbl_email'.tr,
          hintText: 'lbl_email'.tr,
          prefixIcon: Icons.mail_outline_rounded,
          textInputType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          validator: (value) {
            if (value == null || (!isValidEmail(value, isRequired: true))) {
              return 'err_msg_please_enter_valid_email'.tr;
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
      buildWhen: (prev, curr) => prev.isShowPassword != curr.isShowPassword,
      builder: (context, state) {
        return AppTextField(
          controller: state.passwordController,
          label: 'lbl_password'.tr,
          hintText: 'lbl_password'.tr,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: state.isShowPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onTapLogin(context),
          suffix: Semantics(
            label: state.isShowPassword
                ? 'Show password'
                : 'Hide password',
            button: true,
            child: IconButton(
              onPressed: () {
                context.read<Screen0LoginBloc>().add(
                      ChangePasswordVisibilityEvent(
                        value: !state.isShowPassword,
                      ),
                    );
              },
              icon: Icon(
                state.isShowPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: AppDs.iconSm.adaptSize,
                color: AppDs.textOnDarkSecondary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: () {
          NavigatorService.pushNamed(AppRoutes.forgotPasswordScreen);
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space2.h,
            vertical: AppDs.space1.v,
          ),
          minimumSize: Size(AppDs.minTap, AppDs.minTap),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: AppText(
          'lbl_forgot_password'.tr,
          variant: AppTextVariant.accent,
        ),
      ),
    );
  }

  Widget _buildRememberMe(BuildContext context) {
    return BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
      buildWhen: (prev, curr) => prev.rememberMe != curr.rememberMe,
      builder: (context, state) {
        return InkWell(
          onTap: () {
            context.read<Screen0LoginBloc>().add(
                  RememberMeChangedEvent(value: !state.rememberMe),
                );
          },
          borderRadius: BorderRadius.circular(AppDs.radiusSm),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppDs.space1.v),
            child: Row(
              children: [
                SizedBox(
                  height: AppDs.minTap.v,
                  width: AppDs.minTap.h,
                  child: Checkbox(
                    value: state.rememberMe,
                    activeColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      context.read<Screen0LoginBloc>().add(
                            RememberMeChangedEvent(value: v),
                          );
                    },
                  ),
                ),
                Expanded(
                  child: AppText(
                    'lbl_remember_me'.tr,
                    variant: AppTextVariant.body,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
      buildWhen: (prev, curr) =>
          prev.loginError != curr.loginError ||
          prev.isLoading != curr.isLoading ||
          prev.isLoadingGoogle != curr.isLoadingGoogle ||
          prev.isLoadingApple != curr.isLoadingApple ||
          prev.isLoadingGuest != curr.isLoadingGuest,
      builder: (context, state) {
        final socialBusy = state.isLoadingGoogle ||
            state.isLoadingApple ||
            state.isLoadingGuest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.loginError != null && state.loginError!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: AppDs.space3.v),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: AppDs.iconSm.adaptSize,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(width: AppDs.space2.h),
                      Expanded(
                        child: AppText(
                          state.loginError!,
                          variant: AppTextVariant.caption,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            AppPrimaryButton(
              label: 'lbl_login'.tr,
              isLoading: state.isLoading,
              onPressed:
                  socialBusy ? null : () => onTapLogin(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    final showApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Padding(
      padding: EdgeInsets.only(top: AppDs.space6.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLabeledDivider(label: 'msg_or_continue_with'.tr),
          SizedBox(height: AppDs.space4.v),
          BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
            buildWhen: (prev, curr) =>
                prev.isLoading != curr.isLoading ||
                prev.isLoadingGoogle != curr.isLoadingGoogle ||
                prev.isLoadingApple != curr.isLoadingApple ||
                prev.isLoadingGuest != curr.isLoadingGuest,
            builder: (context, state) {
              final authBusy = state.isLoading ||
                  state.isLoadingGoogle ||
                  state.isLoadingApple ||
                  state.isLoadingGuest;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppSocialIconButton(
                        semanticsLabel: 'lbl_continue_with_google'.tr,
                        isLoading: state.isLoadingGoogle,
                        onPressed: authBusy
                            ? null
                            : () {
                                context.read<Screen0LoginBloc>().add(
                                      LoginWithGoogleEvent(),
                                    );
                              },
                        child: GoogleBrandLogo(size: AppDs.iconMd.adaptSize),
                      ),
                      SizedBox(width: AppDs.space4.h),
                      AppSocialIconButton(
                        semanticsLabel: 'lbl_continue_as_guest'.tr,
                        icon: Icons.person_outline_rounded,
                        isLoading: state.isLoadingGuest,
                        onPressed: authBusy
                            ? null
                            : () {
                                context.read<Screen0LoginBloc>().add(
                                      ContinueAsGuestEvent(),
                                    );
                              },
                      ),
                      if (showApple) ...[
                        SizedBox(width: AppDs.space4.h),
                        AppSocialIconButton(
                          semanticsLabel: 'lbl_continue_with_apple'.tr,
                          icon: Icons.apple,
                          isLoading: state.isLoadingApple,
                          onPressed: authBusy
                              ? null
                              : () {
                                  context.read<Screen0LoginBloc>().add(
                                        LoginWithAppleEvent(),
                                      );
                                },
                        ),
                      ],
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: AppDs.space3.v),
                    child: AppText(
                      'msg_guest_feature_locked'.tr,
                      variant: AppTextVariant.caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TextButton(
        onPressed: () {
          NavigatorService.pushNamed(AppRoutes.screen0RegisterScreen);
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space3.h,
            vertical: AppDs.space2.v,
          ),
          minimumSize: Size(AppDs.minTap, AppDs.minTap),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.secondary(theme),
            children: [
              TextSpan(text: 'msg_don_t_have_an_account2'.tr),
              const TextSpan(text: ' '),
              TextSpan(
                text: 'lbl_sign_up_now'.tr,
                style: AppTypography.secondary(theme).copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onTapLogin(BuildContext context) {
    final bloc = context.read<Screen0LoginBloc>();
    if (bloc.state.isLoading ||
        bloc.state.isLoadingGoogle ||
        bloc.state.isLoadingApple ||
        bloc.state.isLoadingGuest) {
      return;
    }
    // Never let a stuck global overlay swallow the tap / block the request.
    GlobalLoadingController.instance.reset();
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;
    final email = bloc.state.emailController?.text.trim() ?? '';
    final password = bloc.state.passwordController?.text ?? '';
    if (email.isEmpty || password.isEmpty) {
      showAppToast(
        'err_msg_please_enter_valid_email'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    bloc.add(
      LoginSubmitEvent(
        email: email,
        password: password,
        rememberMe: bloc.state.rememberMe,
      ),
    );
  }
}
