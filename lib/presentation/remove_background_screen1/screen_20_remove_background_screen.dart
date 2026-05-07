import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/screen_20_remove_background_bloc.dart';
import 'models/listrectangle_item_model.dart';
import 'models/screen_20_remove_background_model.dart';
import 'widgets/listrectangle_item_widget.dart';

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
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(
            horizontal: 28.h,
            vertical: 24.v,
          ),
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
                  style: theme.textTheme.headlineMedium!.copyWith(
                    height: 1.20,
                  ),
                ),
              ),
              Text(
                "msg_100_automatically".tr,
                style: CustomTextStyles.bodyMedium15,
              ),
              SizedBox(height: 51.v),
              _buildUploadingColumn(context),
              SizedBox(height: 38.v),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 128.h,
                  child: Text(
                    "msg_no_image_try_one".tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyles.bodyMedium15.copyWith(
                      height: 1.57,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 13.v),
              _buildListRectangle(context)
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

  Widget _buildUploadingColumn(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 52.h,
        vertical: 53.v,
      ),
      decoration: AppDecoration.fillBluegray90001.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder7,
      ),
      child: CustomElevatedButton(
        onPressed: () {
          NavigatorService.pushNamed(AppRoutes.screen21RemoveBackgroundScreen);
        },
        text: "lbl_uploading".tr,
        buttonStyle: CustomButtonStyles.fillGray,
        buttonTextStyle: CustomTextStyles.bodyMedium15,
      ),
    );
  }

  Widget _buildListRectangle(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 61.v,
        child: BlocSelector<Screen20RemoveBackgroundBloc,
            Screen20RemoveBackgroundState, Screen20RemoveBackgroundModel?>(
          selector: (state) => state.screen20RemoveBackgroundModelObj,
          builder: (context, screen20RemoveBackgroundModelObj) {
            return ListView.separated(
              padding: EdgeInsets.only(right: 27.h),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) {
                return SizedBox(
                  width: 10.h,
                );
              },
              itemCount: screen20RemoveBackgroundModelObj
                      ?.listrectangleItemList.length ??
                  0,
              itemBuilder: (context, index) {
                ListrectangleItemModel model = screen20RemoveBackgroundModelObj
                        ?.listrectangleItemList[index] ??
                    ListrectangleItemModel();
                return ListrectangleItemWidget(
                  model,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
