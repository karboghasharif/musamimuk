import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_text_form_field.dart';

/// Optional details after sign-up: country, photo, bio. Skip continues to home.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  static Widget builder(BuildContext context) => const CompleteProfileScreen();

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();
  String? _photoPath;

  @override
  void dispose() {
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _photoPath = file.path);
    }
  }

  Future<void> _finish({required bool skipped}) async {
    final sessionMap = PrefUtils().getUserSession();
    if (sessionMap == null) {
      if (mounted) {
        await NavigatorService.pushReplacementNamed(
          AppRoutes.screen1HomeScreen,
        );
      }
      return;
    }
    final session = UserSession.fromJson(sessionMap);
    final updated = <String, dynamic>{
      ...session.toJson(),
      if (!skipped) ...{
        'country': _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        'bio':
            _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        if (_photoPath != null && _photoPath!.isNotEmpty)
          'image': 'file://$_photoPath',
      },
    };
    await PrefUtils().setUserSession(updated);
    if (mounted) {
      await NavigatorService.pushReplacementNamed(AppRoutes.screen1HomeScreen);
    }
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
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space3.v,
            AppDs.space4.h,
            AppDs.space8.v,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'lbl_complete_profile'.tr,
                subtitle: 'msg_complete_profile_subtitle'.tr,
              ),
              SizedBox(height: AppDs.space6.v),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: _photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(53),
                          child: Image.file(
                            File(_photoPath!),
                            height: 106.adaptSize,
                            width: 106.adaptSize,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 106.adaptSize,
                          width: 106.adaptSize,
                          decoration: AppDecoration.fillBluegray90002.copyWith(
                            borderRadius: BorderRadiusStyle.circleBorder53,
                          ),
                          child: CustomImageView(
                            imagePath: ImageConstant.imgCamera,
                            height: 35.v,
                            width: 40.h,
                            alignment: Alignment.center,
                          ),
                        ),
                ),
              ),
              SizedBox(height: AppDs.space3.v),
              AppText(
                'msg_upload_a_photo_optional'.tr,
                variant: AppTextVariant.secondary,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDs.space6.v),
              AppCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextFormField(
                      controller: _countryController,
                      hintText: 'lbl_country'.tr,
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
                      prefixConstraints: BoxConstraints(maxHeight: 63.v),
                      borderDecoration: TextFormFieldStyleHelper.fillBlueGray,
                      fillColor: appTheme.blueGray90001,
                    ),
                    SizedBox(height: AppDs.space4.v),
                    CustomTextFormField(
                      controller: _bioController,
                      hintText: 'lbl_optional_info'.tr,
                      hintStyle: CustomTextStyles.titleMediumOnError,
                      textInputAction: TextInputAction.done,
                      maxLines: 3,
                      prefix: Container(
                        margin: EdgeInsets.fromLTRB(28.h, 20.v, 23.h, 19.v),
                        child: CustomImageView(
                          imagePath: ImageConstant.imgCheckmark,
                          height: 22.adaptSize,
                          width: 22.adaptSize,
                        ),
                      ),
                      prefixConstraints: BoxConstraints(maxHeight: 63.v),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppDs.space4.v,
                        horizontal: AppDs.space2.h,
                      ),
                      borderDecoration: TextFormFieldStyleHelper.fillBlueGray,
                      fillColor: appTheme.blueGray90001,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppDs.space6.v),
              AppPrimaryButton(
                label: 'lbl_continue'.tr,
                onPressed: () => _finish(skipped: false),
              ),
              SizedBox(height: AppDs.space3.v),
              TextButton(
                onPressed: () => _finish(skipped: true),
                child: AppText(
                  'lbl_skip_for_now'.tr,
                  variant: AppTextVariant.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
