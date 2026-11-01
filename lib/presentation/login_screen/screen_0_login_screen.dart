import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/google_brand_logo.dart';
import 'bloc/screen_0_login_bloc.dart';

/// Login — atelier visual direction (craft studio, calm ink + brass).
/// Bloc / auth flows unchanged; UI-only redesign for a later full-app pass.
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
      child: Scaffold(
        backgroundColor: AppDs.atelierInk,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const AppAtelierAtmosphere(),
                  SafeArea(
                    child: Form(
                      key: _formKey,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              AppDs.space5.h,
                              AppDs.space6.v,
                              AppDs.space5.h,
                              AppDs.space8.v,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight -
                                    AppDs.space6.v -
                                    AppDs.space8.v,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildBrandBlock(context),
                                    SizedBox(height: AppDs.space8.v),
                                    _buildEmailField(context),
                                    SizedBox(height: AppDs.space3.v),
                                    _buildPasswordField(context),
                                    SizedBox(height: AppDs.space1.v),
                                    _buildForgotAndRemember(context),
                                    SizedBox(height: AppDs.space5.v),
                                    _buildLoginButton(context),
                                    SizedBox(height: AppDs.space6.v),
                                    _buildSocialSection(context),
                                    SizedBox(height: AppDs.space5.v),
                                    _buildGuestLink(context),
                                    const Spacer(),
                                    SizedBox(height: AppDs.space4.v),
                                    _buildSignUpPrompt(context),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Brand → value. Memorable: start-edge brass spine (RTL-aware).
  Widget _buildBrandBlock(BuildContext context) {
    final theme = Theme.of(context);
    return AppFadeIn(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3.h,
            height: 88.v,
            margin: EdgeInsetsDirectional.only(end: AppDs.space4.h),
            decoration: BoxDecoration(
              color: AppDs.atelierBrass,
              borderRadius: BorderRadius.circular(AppDs.radiusFull),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgMusammimuk02,
                  height: 56.adaptSize,
                  width: 56.adaptSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: AppDs.space3.v),
                Text(
                  'lbl_musamimuk_brand'.tr,
                  style: AppDs.screenTitle(theme).copyWith(
                    fontSize: AppDs.fontDisplay.clamp(28.0, 36.0),
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Text(
                  'msg_login_welcome'.tr,
                  style: AppTypography.secondary(theme).copyWith(
                    color: AppDs.atelierBrass,
                    fontWeight: FontWeight.w600,
                    fontSize: AppDs.fontSecondary.clamp(13.0, 15.0),
                  ),
                ),
                SizedBox(height: AppDs.space1.v),
                Text(
                  'msg_login_to_musamimuk'.tr,
                  style: AppTypography.secondary(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    height: 1.45,
                    fontSize: AppDs.fontSecondary.clamp(13.0, 15.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildForgotAndRemember(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildRememberMe(context)),
        _buildForgotPassword(context),
      ],
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return TextButton(
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
                    activeColor: AppDs.accentYellow,
                    checkColor: AppDs.onAccent,
                    side: BorderSide(
                      color: AppDs.atelierHairline(0.28),
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
        final cs = Theme.of(context).colorScheme;
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
                  child: Container(
                    padding: EdgeInsets.all(AppDs.space3.h),
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      border: Border.all(
                        color: cs.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: AppDs.iconSm.adaptSize,
                          color: cs.error,
                        ),
                        SizedBox(width: AppDs.space2.h),
                        Expanded(
                          child: AppText(
                            state.loginError!,
                            variant: AppTextVariant.caption,
                            color: cs.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            AppPrimaryButton(
              label: 'lbl_login'.tr,
              isLoading: state.isLoading,
              onPressed: socialBusy ? null : () => onTapLogin(context),
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

    return Column(
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
            return Row(
              children: [
                Expanded(
                  child: _SocialLabelButton(
                    semanticsLabel: 'lbl_continue_with_google'.tr,
                    label: 'Google',
                    isLoading: state.isLoadingGoogle,
                    onPressed: authBusy
                        ? null
                        : () {
                            context.read<Screen0LoginBloc>().add(
                                  LoginWithGoogleEvent(),
                                );
                          },
                    leading: GoogleBrandLogo(size: AppDs.iconMd.adaptSize),
                  ),
                ),
                if (showApple) ...[
                  SizedBox(width: AppDs.space3.h),
                  Expanded(
                    child: _SocialLabelButton(
                      semanticsLabel: 'lbl_continue_with_apple'.tr,
                      label: 'Apple',
                      isLoading: state.isLoadingApple,
                      onPressed: authBusy
                          ? null
                          : () {
                              context.read<Screen0LoginBloc>().add(
                                    LoginWithAppleEvent(),
                                  );
                            },
                      leading: Icon(
                        Icons.apple,
                        size: AppDs.iconMd.adaptSize,
                        color: AppDs.textOnDarkPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGuestLink(BuildContext context) {
    return BlocBuilder<Screen0LoginBloc, Screen0LoginState>(
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
          children: [
            TextButton(
              onPressed: authBusy || state.isLoadingGuest
                  ? null
                  : () {
                      context.read<Screen0LoginBloc>().add(
                            ContinueAsGuestEvent(),
                          );
                    },
              style: TextButton.styleFrom(
                minimumSize: Size(AppDs.minTap, AppDs.minTap),
                padding: EdgeInsets.symmetric(
                  horizontal: AppDs.space3.h,
                  vertical: AppDs.space2.v,
                ),
              ),
              child: state.isLoadingGuest
                  ? SizedBox(
                      width: AppDs.iconSm.adaptSize,
                      height: AppDs.iconSm.adaptSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppDs.accentYellow,
                      ),
                    )
                  : AppText(
                      'lbl_continue_as_guest'.tr,
                      variant: AppTextVariant.secondary,
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
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
                  color: AppDs.accentYellow,
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

/// Full-width social action with brand logo + label (Google logo unchanged).
class _SocialLabelButton extends StatelessWidget {
  const _SocialLabelButton({
    required this.semanticsLabel,
    required this.label,
    required this.onPressed,
    required this.leading,
    this.isLoading = false,
  });

  final String semanticsLabel;
  final String label;
  final VoidCallback? onPressed;
  final Widget leading;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = !isLoading && onPressed != null;

    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: enabled,
      child: AppScaleTap(
        enabled: enabled,
        onTap: onPressed,
        child: Container(
          height: AppDs.buttonHeight.v,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(color: AppDs.atelierHairline(0.12)),
          ),
          child: isLoading
              ? SizedBox(
                  width: AppDs.iconMd.adaptSize,
                  height: AppDs.iconMd.adaptSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppDs.accentYellow,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    leading,
                    SizedBox(width: AppDs.space2.h),
                    Text(
                      label,
                      style: AppTypography.secondary(theme).copyWith(
                        color: AppDs.textOnDarkPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
