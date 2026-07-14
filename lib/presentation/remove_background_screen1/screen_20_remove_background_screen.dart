import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_20_remove_background_bloc.dart';
import 'models/screen_20_remove_background_model.dart';

class Screen20RemoveBackgroundScreen extends StatelessWidget {
  const Screen20RemoveBackgroundScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen20RemoveBackgroundBloc>(
      create: (context) =>
          Screen20RemoveBackgroundBloc(Screen20RemoveBackgroundState(
        screen20RemoveBackgroundModelObj: Screen20RemoveBackgroundModel(),
      ))
            ..add(Screen20RemoveBackgroundInitialEvent()),
      child: const Screen20RemoveBackgroundScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: AppDs.space6.v),
              AppCard(
                elevated: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLoadingBlock(),
                    SizedBox(height: AppDs.space4.v),
                    AppText(
                      'lbl_uploading'.tr,
                      variant: AppTextVariant.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppDs.space4.v),
              AppPrimaryButton(
                label: 'lbl_uploading'.tr,
                isLoading: true,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
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
}
