import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

/// About Musamimuk — dark layout with centered header and scrollable copy.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static Widget builder(BuildContext context) {
    return const AboutUsScreen();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space6.h,
            vertical: AppDs.space2.v,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppDs.space3.v),
              Icon(
                Icons.groups_outlined,
                size: 72.adaptSize,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: AppDs.space5.v),
              AppText(
                "lbl_about_us_heading".tr,
                variant: AppTextVariant.heading,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                "msg_about_subtitle".tr,
                variant: AppTextVariant.body,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                "msg_about_intro".tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkSecondary,
                textAlign: TextAlign.left,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                "lbl_our_mission".tr,
                variant: AppTextVariant.title,
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                "msg_about_mission_body".tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkSecondary,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                "lbl_why_choose_musamimuk".tr,
                variant: AppTextVariant.title,
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                "msg_about_why_body".tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkSecondary,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                "msg_about_thanks".tr,
                variant: AppTextVariant.secondary,
                textAlign: TextAlign.left,
              ),
              SizedBox(height: AppDs.space12.v),
            ],
          ),
        ),
      ),
    );
  }
}
