import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/screen_1_subcription_bloc.dart';
import 'models/screen_1_subcription_model.dart';

class Screen1SubcriptionScreen extends StatelessWidget {
  const Screen1SubcriptionScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen1SubcriptionBloc>(
      create: (context) => Screen1SubcriptionBloc(Screen1SubcriptionState(
        screen1SubcriptionModelObj: const Screen1SubcriptionModel(),
      ))
        ..add(Screen1SubcriptionInitialEvent()),
      child: const Screen1SubcriptionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Screen1SubcriptionBloc, Screen1SubcriptionState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor:
                theme.colorScheme.onPrimaryContainer.withOpacity(1),
            body: Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(
                horizontal: 22.h,
                vertical: 46.v,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgArrowDown,
                        height: 32.adaptSize,
                        width: 32.adaptSize,
                        onTap: () {
                          onTapImgArrowdownone(context);
                        },
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        child: Text(
                          "msg_choose_your_plan".tr,
                          style: CustomTextStyles.titleMediumBluegray90002,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 48.v),
                  CustomImageView(
                    imagePath: ImageConstant.imgGroup16,
                    height: 185.v,
                    width: 270.h,
                  ),
                  SizedBox(height: 50.v),
                  _buildBasicRow(context),
                  SizedBox(height: 22.v),
                  _buildPremiumRow(context),
                  SizedBox(height: 5.v)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasicRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.h,
        vertical: 12.v,
      ),
      decoration: AppDecoration.fillGray.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 9.v),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 17.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "lbl_basic".tr,
                    style: CustomTextStyles.titleMediumBluegray90004Bold,
                  ),
                  Text(
                    "lbl_free".tr,
                    style: CustomTextStyles.titleMediumBluegray90004,
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 24.v),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgTickCircleSvgrepoCom,
                  height: 14.adaptSize,
                  width: 14.adaptSize,
                ),
                SizedBox(width: 9.h),
                Expanded(
                  child: Text(
                    "msg_access_to_few_design".tr,
                    style: CustomTextStyles.bodySmallInterGray90005,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.v),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgTickCircleSvgrepoCom,
                  height: 14.adaptSize,
                  width: 14.adaptSize,
                ),
                SizedBox(width: 9.h),
                Expanded(
                  child: Text(
                    "msg_available_memory".tr,
                    style: CustomTextStyles.bodySmallInterGray90005,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.v),
          CustomElevatedButton(
            height: 44.v,
            text: "lbl_subscribed".tr,
            buttonStyle: CustomButtonStyles.fillOnError,
            buttonTextStyle: CustomTextStyles.titleSmallBluegray90004,
          )
        ],
      ),
    );
  }

  Widget _buildPremiumRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.h,
        vertical: 13.v,
      ),
      decoration: AppDecoration.fillGray.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.v),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "lbl_premium".tr,
                    style: CustomTextStyles.titleMediumBluegray90004Bold,
                  ),
                  Text(
                    "lbl_5_month".tr,
                    style: CustomTextStyles.titleMediumBluegray90004,
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 21.v),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgTickCircleSvgrepoCom,
                  height: 14.adaptSize,
                  width: 14.adaptSize,
                ),
                SizedBox(width: 9.h),
                Expanded(
                  child: Text(
                    "msg_access_to_all_design".tr,
                    style: CustomTextStyles.bodySmallInterGray90005,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.v),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgTickCircleSvgrepoCom,
                  height: 14.adaptSize,
                  width: 14.adaptSize,
                ),
                SizedBox(width: 9.h),
                Expanded(
                  child: Text(
                    "msg_available_memory2".tr,
                    style: CustomTextStyles.bodySmallInterGray90005,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.v),
          CustomElevatedButton(
            height: 44.v,
            text: "lbl_subscribe".tr,
            buttonStyle: CustomButtonStyles.fillPrimaryTL10,
            buttonTextStyle: CustomTextStyles.titleSmallBluegray90004,
          )
        ],
      ),
    );
  }

  onTapImgArrowdownone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen1HomeScreen,
    );
  }
}
