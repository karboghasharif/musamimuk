import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/guest_upgrade_bloc.dart';

/// Converts a guest session into a full account. Reuses the register fields but
/// calls `/user/upgrade` with the guest token so guest data is preserved.
class GuestUpgradeScreen extends StatelessWidget {
  const GuestUpgradeScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<GuestUpgradeBloc>(
      create: (_) => GuestUpgradeBloc(GuestUpgradeState())
        ..add(const GuestUpgradeInitialEvent()),
      child: const GuestUpgradeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _GuestUpgradeView();
  }
}

class _GuestUpgradeView extends StatefulWidget {
  const _GuestUpgradeView();

  @override
  State<_GuestUpgradeView> createState() => _GuestUpgradeViewState();
}

class _GuestUpgradeViewState extends State<_GuestUpgradeView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _onSubmit(BuildContext context) {
    final bloc = context.read<GuestUpgradeBloc>();
    if (bloc.state.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = bloc.state.nameController?.text.trim() ?? '';
    final email = bloc.state.emailController?.text.trim() ?? '';
    final password = bloc.state.passwordController?.text ?? '';
    final confirm = bloc.state.confirmController?.text ?? '';
    bloc.add(GuestUpgradeSubmitEvent(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: confirm,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GuestUpgradeBloc, GuestUpgradeState>(
      listenWhen: (prev, curr) =>
          prev.upgradeSuccess != curr.upgradeSuccess ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.upgradeSuccess) {
          showAppToast(
            'msg_account_created'.tr,
            type: ToastificationType.success,
          );
          NavigatorService.pushNamedAndRemoveUntil(
            AppRoutes.screen1HomeScreen,
            routePredicate: false,
          );
        } else if (state.errorMessage != null &&
            state.errorMessage!.isNotEmpty) {
          showAppToast(state.errorMessage!, type: ToastificationType.error);
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppDs.surfaceBase,
          appBar: CustomAppBar(
            leading: AppbarLeadingImage(
              imagePath: ImageConstant.imgArrowLeftPrimary,
              onTap: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: AppbarTitle(text: 'lbl_create_account'.tr),
          ),
          body: BlocBuilder<GuestUpgradeBloc, GuestUpgradeState>(
            builder: (context, state) {
              return AppLoadingOverlay(
                isLoading: state.isLoading,
                message: 'msg_creating_account'.tr,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppDs.space4.h,
                      AppDs.space4.v,
                      AppDs.space4.h,
                      AppDs.space8.v,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText(
                          'msg_upgrade_headline'.tr,
                          variant: AppTextVariant.heading,
                          color: AppDs.textOnDarkPrimary,
                        ),
                        SizedBox(height: AppDs.space2.v),
                        AppText(
                          'msg_upgrade_subtitle'.tr,
                          variant: AppTextVariant.secondary,
                          color: AppDs.textOnDarkSecondary,
                        ),
                        SizedBox(height: AppDs.space6.v),
                        _label('lbl_full_name'.tr),
                        SizedBox(height: AppDs.space2.v),
                        TextFormField(
                          controller: state.nameController,
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('lbl_full_name'.tr),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'err_msg_required'.tr
                                  : null,
                        ),
                        SizedBox(height: AppDs.space4.v),
                        _label('lbl_email'.tr),
                        SizedBox(height: AppDs.space2.v),
                        TextFormField(
                          controller: state.emailController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('lbl_email'.tr),
                          validator: (v) =>
                              isValidEmail(v, isRequired: true)
                                  ? null
                                  : 'err_msg_please_enter_valid_email'.tr,
                        ),
                        SizedBox(height: AppDs.space4.v),
                        _label('lbl_password'.tr),
                        SizedBox(height: AppDs.space2.v),
                        TextFormField(
                          controller: state.passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: state.isShowPassword,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('lbl_password'.tr).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                state.isShowPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppDs.textOnDarkSecondary,
                              ),
                              onPressed: () => context
                                  .read<GuestUpgradeBloc>()
                                  .add(GuestUpgradePasswordVisibilityEvent(
                                    !state.isShowPassword,
                                  )),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 8)
                              ? 'err_msg_password_min'.tr
                              : null,
                        ),
                        SizedBox(height: AppDs.space4.v),
                        _label('lbl_confirm_password'.tr),
                        SizedBox(height: AppDs.space2.v),
                        TextFormField(
                          controller: state.confirmController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: state.isShowPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onSubmit(context),
                          decoration: _decoration('lbl_confirm_password'.tr),
                          validator: (v) =>
                              (v != state.passwordController?.text)
                                  ? 'err_msg_passwords_do_not_match'.tr
                                  : null,
                        ),
                        SizedBox(height: AppDs.space6.v),
                        AppPrimaryButton(
                          label: 'lbl_create_account'.tr,
                          isLoading: state.isLoading,
                          onPressed: () => _onSubmit(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => AppText(
        text,
        variant: AppTextVariant.caption,
        color: AppDs.textOnDarkSecondary,
      );

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppDs.textOnDarkSecondary),
      filled: true,
      fillColor: AppDs.surfaceElevated,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDs.space4.h,
        vertical: AppDs.space3.v,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
        borderSide: BorderSide.none,
      ),
    );
  }
}
