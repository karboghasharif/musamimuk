import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_21_remove_background_bloc.dart';
import 'models/screen_21_remove_background_model.dart';

class Screen21RemoveBackgroundScreen extends StatelessWidget {
  const Screen21RemoveBackgroundScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen21RemoveBackgroundBloc>(
      create: (context) =>
          Screen21RemoveBackgroundBloc(Screen21RemoveBackgroundState(
        screen21RemoveBackgroundModelObj: const Screen21RemoveBackgroundModel(),
      ))
            ..add(Screen21RemoveBackgroundInitialEvent()),
      child: const Screen21RemoveBackgroundScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Screen21RemoveBackgroundBloc,
        Screen21RemoveBackgroundState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: AppDs.surfaceBase,
            appBar: _buildAppBar(context),
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space3.v,
                AppDs.space4.h,
                AppDs.space6.v,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    title: 'msg_remove_background2'.tr,
                    subtitle: 'msg_100_automatically'.tr,
                    align: TextAlign.center,
                  ),
                  SizedBox(height: AppDs.space4.v),
                  Center(
                    child: CustomImageView(
                      imagePath: ImageConstant.imgGalleryRemoveSvgrepoCom,
                      height: 72.adaptSize,
                      width: 72.adaptSize,
                    ),
                  ),
                  SizedBox(height: AppDs.space4.v),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        'msg_remove_background'.tr,
                        variant: AppTextVariant.accent,
                      ),
                      SizedBox(width: AppDs.space6.h),
                      AppText(
                        'lbl_original'.tr,
                        variant: AppTextVariant.secondary,
                      ),
                    ],
                  ),
                  SizedBox(height: AppDs.space1.v),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 181.h,
                      margin: EdgeInsets.only(left: 82.h),
                      height: 3.v,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(1.h),
                      ),
                    ),
                  ),
                  SizedBox(height: AppDs.space4.v),
                  AppCard(
                    elevated: true,
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 282.v,
                      width: double.infinity,
                      child: AppEmptyState(
                        title: 'lbl_original'.tr,
                        message: 'lbl_upload_image'.tr,
                        icon: Icons.image_outlined,
                      ),
                    ),
                  ),
                  SizedBox(height: AppDs.space4.v),
                  AppPrimaryButton(
                    label: 'lbl_download'.tr,
                    onPressed: () {
                      onTapDownload(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        margin: EdgeInsets.only(left: AppDs.space4.h),
      ),
    );
  }

  onTapDownload(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen19RemoveBackgroundScreen,
    );
  }
}
