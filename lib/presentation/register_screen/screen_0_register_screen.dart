import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import 'bloc/screen_0_register_bloc.dart';
import 'models/screen_0_register_model.dart';

/// Register — same atelier direction as login (craft studio, ink + brass).
/// Bloc / role flows unchanged; UI-only redesign.
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
          final route = switch (state.accountType) {
            Screen0RegisterBloc.accountTypeShop =>
              AppRoutes.printShopRegisterScreen,
            Screen0RegisterBloc.accountTypeRider =>
              AppRoutes.printRiderRegisterScreen,
            _ => AppRoutes.completeProfileScreen,
          };
          NavigatorService.pushReplacementNamed(route);
        }
        if (state.registerError != null && state.registerError!.isNotEmpty) {
          showAppToast(
            state.registerError!,
            type: ToastificationType.error,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppDs.atelierInk,
        resizeToAvoidBottomInset: true,
        body: BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
          buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
          builder: (context, state) {
            return AppLoadingOverlay(
              isLoading: state.isLoading,
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
                                    SizedBox(height: AppDs.space6.v),
                                    _buildAccountTypePicker(context),
                                    SizedBox(height: AppDs.space5.v),
                                    _buildUserProfile(context),
                                    SizedBox(height: AppDs.space3.v),
                                    _buildEmailOrMobileField(context),
                                    SizedBox(height: AppDs.space3.v),
                                    _buildPasswordField(context),
                                    _buildPasswordStrengthFeedback(),
                                    SizedBox(height: AppDs.space3.v),
                                    _buildPasswordConfirmationField(context),
                                    _buildConfirmMatchFeedback(),
                                    SizedBox(height: AppDs.space6.v),
                                    _buildRegisterButton(context),
                                    SizedBox(height: AppDs.space4.v),
                                    _buildLoginPrompt(context),
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
                  'msg_register_welcome'.tr,
                  style: AppTypography.secondary(theme).copyWith(
                    color: AppDs.atelierBrass,
                    fontWeight: FontWeight.w600,
                    fontSize: AppDs.fontSecondary.clamp(13.0, 15.0),
                  ),
                ),
                SizedBox(height: AppDs.space1.v),
                Text(
                  'msg_make_your_own_account'.tr,
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

  Widget _buildUserProfile(BuildContext context) {
    return BlocSelector<Screen0RegisterBloc, Screen0RegisterState,
        TextEditingController?>(
      selector: (state) => state.userProfileController,
      builder: (context, userProfileController) {
        return AppTextField(
          controller: userProfileController,
          label: 'lbl_name_or_username'.tr,
          hintText: 'lbl_name_or_username'.tr,
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          validator: (value) {
            final t = value?.trim() ?? '';
            if (t.length < 2) {
              return 'err_msg_please_enter_valid_text'.tr;
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildEmailOrMobileField(BuildContext context) {
    return BlocSelector<Screen0RegisterBloc, Screen0RegisterState,
        TextEditingController?>(
      selector: (state) => state.emailFieldController,
      builder: (context, emailFieldController) {
        return AppTextField(
          controller: emailFieldController,
          label: 'lbl_email_or_mobile'.tr,
          hintText: 'lbl_email_or_mobile'.tr,
          prefixIcon: Icons.mail_outline_rounded,
          textInputType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          onChanged: (_) => _refresh(),
          validator: (value) {
            if (!isValidEmailOrPhone(value, isRequired: true)) {
              return 'err_msg_please_enter_valid_email_or_phone'.tr;
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
      buildWhen: (prev, curr) => prev.isShowPassword != curr.isShowPassword,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: state.passwordFieldController,
              label: 'lbl_password'.tr,
              hintText: 'lbl_password'.tr,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: state.isShowPassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _refresh(),
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              suffix: Semantics(
                label: state.isShowPassword
                    ? 'Show password'
                    : 'Hide password',
                button: true,
                child: IconButton(
                  onPressed: () {
                    context.read<Screen0RegisterBloc>().add(
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
              validator: (value) {
                if (value == null ||
                    (!isValidPassword(value, isRequired: true))) {
                  return 'err_msg_please_enter_valid_password'.tr;
                }
                return null;
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: AppDs.space2.v),
              child: AppText(
                'msg_password_requirements_hint'.tr,
                variant: AppTextVariant.caption,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordStrengthFeedback() {
    final state = context.read<Screen0RegisterBloc>().state;
    final raw = state.passwordFieldController?.text ?? '';
    final level = classifyPasswordStrength(raw);
    if (level == PasswordStrengthLevel.empty) {
      return SizedBox(height: AppDs.space2.v);
    }
    final ok = level == PasswordStrengthLevel.strong;
    final label = switch (level) {
      PasswordStrengthLevel.tooShort => 'lbl_password_too_short'.tr,
      PasswordStrengthLevel.weak => 'lbl_password_needs_more'.tr,
      PasswordStrengthLevel.strong => 'lbl_password_strength_strong'.tr,
      PasswordStrengthLevel.empty => '',
    };
    final color = ok ? const Color(0xFF7DCEA0) : Theme.of(context).colorScheme.error;
    return Padding(
      padding: EdgeInsets.only(top: AppDs.space2.v),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline_rounded,
            size: AppDs.iconSm.adaptSize,
            color: color,
          ),
          SizedBox(width: AppDs.space2.h),
          Expanded(
            child: AppText(
              label,
              variant: AppTextVariant.caption,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordConfirmationField(BuildContext context) {
    return BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
      buildWhen: (prev, curr) => prev.isShowPassword != curr.isShowPassword,
      builder: (context, state) {
        return AppTextField(
          controller: state.passwordConfirmationController,
          label: 'lbl_confirm_password'.tr,
          hintText: 'lbl_confirm_password'.tr,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: state.isShowPassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _refresh(),
          onFieldSubmitted: (_) => _onTapRegister(context),
          suffix: Semantics(
            label: state.isShowPassword ? 'Show password' : 'Hide password',
            button: true,
            child: IconButton(
              onPressed: () {
                context.read<Screen0RegisterBloc>().add(
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'err_msg_please_enter_valid_password'.tr;
            }
            final password = context
                    .read<Screen0RegisterBloc>()
                    .state
                    .passwordFieldController
                    ?.text ??
                '';
            if (value != password) {
              return 'err_msg_passwords_do_not_match'.tr;
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildConfirmMatchFeedback() {
    final state = context.read<Screen0RegisterBloc>().state;
    final a = state.passwordFieldController?.text ?? '';
    final b = state.passwordConfirmationController?.text ?? '';
    if (b.isEmpty) {
      return SizedBox(height: AppDs.space2.v);
    }
    final match = a == b;
    final color =
        match ? const Color(0xFF7DCEA0) : Theme.of(context).colorScheme.error;
    return Padding(
      padding: EdgeInsets.only(top: AppDs.space2.v),
      child: Row(
        children: [
          Icon(
            match ? Icons.check_circle_outline : Icons.error_outline_rounded,
            size: AppDs.iconSm.adaptSize,
            color: color,
          ),
          SizedBox(width: AppDs.space2.h),
          Expanded(
            child: AppText(
              match
                  ? 'lbl_passwords_match'.tr
                  : 'lbl_passwords_do_not_match'.tr,
              variant: AppTextVariant.caption,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypePicker(BuildContext context) {
    return BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
      buildWhen: (prev, curr) => prev.accountType != curr.accountType,
      builder: (context, state) {
        void select(String type) {
          context.read<Screen0RegisterBloc>().add(
                ChangeRegisterAccountTypeEvent(accountType: type),
              );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              'lbl_register_as'.tr,
              variant: AppTextVariant.caption,
            ),
            SizedBox(height: AppDs.space3.v),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AccountTypeOption(
                    title: 'lbl_register_as_designer'.tr,
                    icon: Icons.palette_outlined,
                    selected: state.accountType ==
                        Screen0RegisterBloc.accountTypeDesigner,
                    onTap: () =>
                        select(Screen0RegisterBloc.accountTypeDesigner),
                  ),
                ),
                SizedBox(width: AppDs.space2.h),
                Expanded(
                  child: _AccountTypeOption(
                    title: 'lbl_register_as_shop'.tr,
                    icon: Icons.storefront_outlined,
                    selected: state.accountType ==
                        Screen0RegisterBloc.accountTypeShop,
                    onTap: () => select(Screen0RegisterBloc.accountTypeShop),
                  ),
                ),
                SizedBox(width: AppDs.space2.h),
                Expanded(
                  child: _AccountTypeOption(
                    title: 'lbl_register_as_rider'.tr,
                    icon: Icons.two_wheeler_outlined,
                    selected: state.accountType ==
                        Screen0RegisterBloc.accountTypeRider,
                    onTap: () => select(Screen0RegisterBloc.accountTypeRider),
                  ),
                ),
              ],
            ),
            if (state.accountType != Screen0RegisterBloc.accountTypeDesigner)
              Padding(
                padding: EdgeInsets.only(top: AppDs.space3.v),
                child: Container(
                  padding: EdgeInsets.all(AppDs.space3.h),
                  decoration: BoxDecoration(
                    color: AppDs.atelierBrass.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDs.radiusMd),
                    border: Border.all(
                      color: AppDs.atelierBrass.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: AppDs.iconSm.adaptSize,
                        color: AppDs.atelierBrass,
                      ),
                      SizedBox(width: AppDs.space2.h),
                      Expanded(
                        child: AppText(
                          state.accountType ==
                                  Screen0RegisterBloc.accountTypeShop
                              ? 'msg_register_as_shop_hint'.tr
                              : 'msg_register_as_rider_hint'.tr,
                          variant: AppTextVariant.caption,
                          color: AppDs.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return BlocBuilder<Screen0RegisterBloc, Screen0RegisterState>(
      buildWhen: (prev, curr) =>
          prev.isLoading != curr.isLoading ||
          prev.accountType != curr.accountType ||
          prev.registerError != curr.registerError,
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final label = switch (state.accountType) {
          Screen0RegisterBloc.accountTypeShop =>
            'lbl_register_continue_shop'.tr,
          Screen0RegisterBloc.accountTypeRider =>
            'lbl_register_continue_rider'.tr,
          _ => 'lbl_register'.tr,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.registerError != null &&
                state.registerError!.isNotEmpty)
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
                            state.registerError!,
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
              label: label,
              isLoading: state.isLoading,
              onPressed: () => _onTapRegister(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TextButton(
        onPressed: () {
          NavigatorService.pushNamed(AppRoutes.screen0LoginScreen);
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
              TextSpan(text: 'msg_already_have_an2'.tr),
              const TextSpan(text: ' '),
              TextSpan(
                text: 'lbl_login'.tr,
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

  void _onTapRegister(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<Screen0RegisterBloc>();
    if (bloc.state.isLoading) return;
    GlobalLoadingController.instance.reset();
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

class _AccountTypeOption extends StatelessWidget {
  const _AccountTypeOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          constraints: BoxConstraints(minHeight: AppDs.minTap.v * 1.6),
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space2.h,
            vertical: AppDs.space3.v,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppDs.accentYellow.withValues(alpha: 0.1)
                : AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: selected
                  ? AppDs.accentYellow.withValues(alpha: 0.55)
                  : AppDs.atelierHairline(0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? AppDs.accentYellow
                    : AppDs.textOnDarkSecondary,
                size: AppDs.iconMd.adaptSize,
              ),
              SizedBox(height: AppDs.space2.v),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(theme).copyWith(
                  color: selected
                      ? AppDs.textOnDarkPrimary
                      : AppDs.textOnDarkSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
