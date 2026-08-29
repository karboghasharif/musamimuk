import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

const String kSupportPhoneDisplay = '+966 576 359 762';
const String kSupportPhoneTel = '+966576359762';
const String kSupportEmail = 'Fahadgallery26@gmail.com';

/// About Musamimuk — dark layout with centered header, copy, and help contacts.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static Widget builder(BuildContext context) {
    return const AboutUsScreen();
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showAppToast(
          'msg_could_not_open_link'.tr,
          type: ToastificationType.error,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          'msg_could_not_open_link'.tr,
          type: ToastificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

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
                color: primary,
              ),
              SizedBox(height: AppDs.space5.v),
              AppText(
                'lbl_about_us_heading'.tr,
                variant: AppTextVariant.heading,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                'msg_about_subtitle'.tr,
                variant: AppTextVariant.body,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                'msg_about_intro'.tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkSecondary,
                textAlign: TextAlign.left,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText('lbl_our_mission'.tr, variant: AppTextVariant.title),
              SizedBox(height: AppDs.space2.v),
              AppText(
                'msg_about_mission_body'.tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkSecondary,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                'lbl_why_choose_musamimuk'.tr,
                variant: AppTextVariant.title,
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                'msg_about_why_body'.tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkSecondary,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                'msg_about_thanks'.tr,
                variant: AppTextVariant.secondary,
                textAlign: TextAlign.left,
              ),
              SizedBox(height: AppDs.space8.v),
              AppText(
                'lbl_help_and_support'.tr,
                variant: AppTextVariant.title,
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                'msg_help_and_support_subtitle'.tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkSecondary,
              ),
              SizedBox(height: AppDs.space4.v),
              _SupportContactTile(
                icon: Icons.phone_outlined,
                label: 'lbl_phone'.tr,
                value: kSupportPhoneDisplay,
                onTap: () => _openUri(
                  context,
                  Uri(scheme: 'tel', path: kSupportPhoneTel),
                ),
              ),
              SizedBox(height: AppDs.space3.v),
              _SupportContactTile(
                icon: Icons.email_outlined,
                label: 'lbl_email'.tr,
                value: kSupportEmail,
                onTap: () => _openUri(
                  context,
                  Uri(
                    scheme: 'mailto',
                    path: kSupportEmail,
                  ),
                ),
              ),
              SizedBox(height: AppDs.space12.v),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportContactTile extends StatelessWidget {
  const _SupportContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return Material(
      color: AppDs.surfaceElevated,
      borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4.h,
            vertical: AppDs.space4.v,
          ),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 24.adaptSize),
              SizedBox(width: AppDs.space3.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      label,
                      variant: AppTextVariant.secondary,
                    ),
                    SizedBox(height: 2.v),
                    AppText(
                      value,
                      variant: AppTextVariant.body,
                      color: AppDs.textOnDarkPrimary,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppDs.textOnDarkSecondary,
                size: 22.adaptSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
