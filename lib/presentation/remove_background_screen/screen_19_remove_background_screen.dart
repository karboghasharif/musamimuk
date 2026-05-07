import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/screen_19_remove_background_bloc.dart';
import 'models/imagelist_item_model.dart';
import 'models/screen_19_remove_background_model.dart';
import 'widgets/imagelist_item_widget.dart';

class Screen19RemoveBackgroundScreen extends StatelessWidget {
  const Screen19RemoveBackgroundScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen19RemoveBackgroundBloc>(
      create:
          (context) => Screen19RemoveBackgroundBloc(
            Screen19RemoveBackgroundState(
              screen19RemoveBackgroundModelObj: Screen19RemoveBackgroundModel(),
            ),
          )..add(Screen19RemoveBackgroundInitialEvent()),
      child: const Screen19RemoveBackgroundScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: 28.h, vertical: 24.v),
          child: Column(
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgGalleryRemoveSvgrepoCom,
                height: 72.adaptSize,
                width: 72.adaptSize,
              ),
              SizedBox(height: 41.v),
              SizedBox(
                width: 178.h,
                child: Text(
                  "msg_remove_background2".tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium!.copyWith(height: 1.20),
                ),
              ),
              Text(
                "msg_100_automatically".tr,
                style: CustomTextStyles.bodyMedium15,
              ),
              SizedBox(height: 20.v),
              // _buildAIButtons(context),
              // SizedBox(height: 20.v),
              _buildUploadButton(context),
              SizedBox(height: 38.v),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 128.h,
                  child: Text(
                    "msg_no_image_try_one".tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyles.bodyMedium15.copyWith(height: 1.57),
                  ),
                ),
              ),
              SizedBox(height: 13.v),
              _buildImageList(context),
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
        margin: EdgeInsets.fromLTRB(29.h, 20.v, 378.h, 19.v),
      ),
    );
  }

  Widget _buildAIButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.h),
            child: CustomElevatedButton(
              height: 50.v,
              text: "AI Remove Background",
              buttonStyle: CustomButtonStyles.fillPrimary,
              buttonTextStyle: CustomTextStyles.titleMediumBold,
              onPressed: () {
                NavigatorService.pushNamed(
                  AppRoutes.enhancedRemoveBackgroundScreen,
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.h),
            child: CustomElevatedButton(
              height: 50.v,
              text: "Settings",
              buttonStyle: CustomButtonStyles.outlineBlackTL24,
              buttonTextStyle: CustomTextStyles.titleMediumBold,
              onPressed: () {
                NavigatorService.pushNamed(
                  AppRoutes.backgroundRemovalSettingsScreen,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 52.h, vertical: 53.v),
      decoration: AppDecoration.fillBluegray90001.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder7,
      ),
      child: CustomElevatedButton(
        text: "lbl_upload_image".tr,
        onPressed: () {
          NavigatorService.pushNamed(AppRoutes.enhancedRemoveBackgroundScreen);
        },
      ),
    );
  }

  Widget _buildImageList(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 61.v,
        child: BlocSelector<
          Screen19RemoveBackgroundBloc,
          Screen19RemoveBackgroundState,
          Screen19RemoveBackgroundModel?
        >(
          selector: (state) => state.screen19RemoveBackgroundModelObj,
          builder: (context, screen19RemoveBackgroundModelObj) {
            return ListView.separated(
              padding: EdgeInsets.only(right: 27.h),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) {
                return SizedBox(width: 10.h);
              },
              itemCount:
                  screen19RemoveBackgroundModelObj?.imagelistItemList.length ??
                  0,
              itemBuilder: (context, index) {
                ImagelistItemModel model =
                    screen19RemoveBackgroundModelObj
                        ?.imagelistItemList[index] ??
                    ImagelistItemModel();
                return ImagelistItemWidget(model);
              },
            );
          },
        ),
      ),
    );
  }

  onTapUploadimage(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen20RemoveBackgroundScreen);
  }
}
