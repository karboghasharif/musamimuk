import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

/// About Musamimuk — dark layout with centered header and scrollable copy.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const Color _background = Color(0xFF1E1E26);

  static Widget builder(BuildContext context) {
    return const AboutUsScreen();
  }

  @override
  Widget build(BuildContext context) {
    final bodyMuted = appTheme.blueGray300;

    return SafeArea(
      child: Scaffold(
        backgroundColor: _background,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 8.v),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.v),
              Icon(
                Icons.groups_outlined,
                size: 72.adaptSize,
                color: appTheme.blueGray400,
              ),
              SizedBox(height: 20.v),
              Text(
                "lbl_about_us_heading".tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 10.v),
              Text(
                "msg_about_subtitle".tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 28.v),
              Text(
                "msg_about_intro".tr,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyMuted,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28.v),
              Text(
                "lbl_our_mission".tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.v),
              Text(
                "msg_about_mission_body".tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyMuted,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28.v),
              Text(
                "lbl_why_choose_musamimuk".tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.v),
              Text(
                "msg_about_why_body".tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyMuted,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.v),
              Text(
                "msg_about_thanks".tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyMuted,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 40.v),
            ],
          ),
        ),
      ),
    );
  }
}
