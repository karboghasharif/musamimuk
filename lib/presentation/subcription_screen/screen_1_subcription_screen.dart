import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_1_subcription_bloc.dart';
import 'models/screen_1_subcription_model.dart';

class Screen1SubcriptionScreen extends StatelessWidget {
  const Screen1SubcriptionScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen1SubcriptionBloc>(
      create: (context) => Screen1SubcriptionBloc(
        Screen1SubcriptionState(
          screen1SubcriptionModelObj: const Screen1SubcriptionModel(),
        ),
      )..add(Screen1SubcriptionInitialEvent()),
      child: const Screen1SubcriptionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowDownPrimary,
            onTap: () => NavigatorService.pushNamed(AppRoutes.screen1HomeScreen),
          ),
          centerTitle: true,
          title: AppbarTitle(text: 'msg_choose_your_plan'.tr),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space4.v,
            AppDs.space4.h,
            AppDs.space8.v,
          ),
          child: Column(
            children: [
              AppPageHeader(
                title: 'msg_choose_your_plan'.tr,
                subtitle: 'msg_upgrade_to_access'.tr,
                align: TextAlign.center,
              ),
              SizedBox(height: AppDs.space6.v),
              CustomImageView(
                imagePath: ImageConstant.imgGroup16,
                height: 160.v,
                width: 240.h,
              ),
              SizedBox(height: AppDs.space8.v),
              _PlanCard(
                name: 'lbl_basic'.tr,
                price: 'lbl_free'.tr,
                features: [
                  'msg_access_to_few_design'.tr,
                  'msg_available_memory'.tr,
                ],
                primary: false,
                buttonLabel: 'lbl_subscribed'.tr,
                onPressed: null,
              ),
              SizedBox(height: AppDs.space4.v),
              _PlanCard(
                name: 'lbl_premium'.tr,
                price: 'lbl_5_month'.tr,
                features: [
                  'msg_access_to_all_design'.tr,
                  'msg_available_memory2'.tr,
                ],
                primary: true,
                buttonLabel: 'lbl_subscribe'.tr,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.features,
    required this.primary,
    required this.buttonLabel,
    this.onPressed,
  });

  final String name;
  final String price;
  final List<String> features;
  final bool primary;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(name, variant: AppTextVariant.title),
              AppText(
                price,
                variant: primary ? AppTextVariant.accent : AppTextVariant.body,
              ),
            ],
          ),
          SizedBox(height: AppDs.space4.v),
          for (final f in features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: AppDs.iconSm.adaptSize,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: AppDs.space2.h),
                Expanded(
                  child: AppText(f, variant: AppTextVariant.secondary),
                ),
              ],
            ),
            SizedBox(height: AppDs.space2.v),
          ],
          SizedBox(height: AppDs.space4.v),
          primary
              ? AppPrimaryButton(label: buttonLabel, onPressed: onPressed)
              : AppSecondaryButton(label: buttonLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}
