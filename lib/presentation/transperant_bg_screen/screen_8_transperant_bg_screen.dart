import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';
import 'bloc/screen_8_transperant_bg_bloc.dart';
import 'models/screen_8_transperant_bg_model.dart';

class Screen8TransperantBgScreen extends StatelessWidget {
  const Screen8TransperantBgScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen8TransperantBgBloc>(
      create: (context) => Screen8TransperantBgBloc(Screen8TransperantBgState(
        screen8TransperantBgModelObj: const Screen8TransperantBgModel(),
      ))
        ..add(Screen8TransperantBgInitialEvent()),
      child: const Screen8TransperantBgScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Screen8TransperantBgBloc, Screen8TransperantBgState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: AppDs.surfaceBase,
            body: Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(
                horizontal: AppDs.space2.h,
                vertical: AppDs.space6.v,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRowtelevision(context),
                  SizedBox(height: 81.v),
                  CustomImageView(
                    imagePath: ImageConstant.imgRectangle6,
                    height: 409.adaptSize,
                    width: 409.adaptSize,
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppDs.space6.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            CustomIconButton(
                              height: 24.adaptSize,
                              width: 24.adaptSize,
                              onTap: () {
                                onTapBtnPlussvgrepoone(context);
                              },
                              child: CustomImageView(
                                imagePath: ImageConstant
                                    .imgPlusSvgrepoComOnprimarycontainer,
                              ),
                            ),
                            SizedBox(height: 11.v),
                            GestureDetector(
                              onTap: () {
                                onTapTxtAddnew(context);
                              },
                              child: Text(
                                "lbl_add_new".tr,
                                style: theme.textTheme.bodySmall,
                              ),
                            )
                          ],
                        ),
                        Column(
                          children: [
                            CustomImageView(
                              imagePath: ImageConstant.imgSlideSizeSvgrepoCom,
                              height: 30.adaptSize,
                              width: 30.adaptSize,
                              onTap: () {
                                onTapImgSlidesizeone(context);
                              },
                            ),
                            SizedBox(height: 9.v),
                            GestureDetector(
                              onTap: () {
                                onTapTxtResizepaper(context);
                              },
                              child: Text(
                                "lbl_resize_paper".tr,
                                style: theme.textTheme.bodySmall,
                              ),
                            )
                          ],
                        ),
                        Column(
                          children: [
                            CustomImageView(
                              imagePath:
                                  ImageConstant.imgBlockchainSvgrepoComPrimary,
                              height: 24.adaptSize,
                              width: 24.adaptSize,
                            ),
                            SizedBox(height: 14.v),
                            Text(
                              "lbl_transparent_bg".tr,
                              style: CustomTextStyles.bodySmallPrimary,
                            )
                          ],
                        ),
                        Column(
                          children: [
                            CustomImageView(
                              imagePath: ImageConstant.imgColorFillSvgrepoCom,
                              height: 26.adaptSize,
                              width: 26.adaptSize,
                              onTap: () {
                                NavigatorService.pushNamed(
                                    AppRoutes.screen10ColorPickerScreen);
                              },
                            ),
                            SizedBox(height: 10.v),
                            GestureDetector(
                              onTap: () {
                                NavigatorService.pushNamed(
                                    AppRoutes.screen10ColorPickerScreen);
                              },
                              child: Text(
                                "lbl_bg_color".tr,
                                style: theme.textTheme.bodySmall,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildRowtelevision(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgTelevision,
            height: 13.v,
            width: 30.h,
            margin: EdgeInsets.only(
              top: 11.v,
              bottom: 17.v,
            ),
          ),
          Column(
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgReply,
                height: 19.adaptSize,
                width: 19.adaptSize,
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                "lbl_save".tr,
                variant: AppTextVariant.caption,
              )
            ],
          )
        ],
      ),
    );
  }

  /// Navigates to the screen3AddNewScreen when the action is triggered.
  onTapBtnPlussvgrepoone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
    );
  }

  /// Navigates to the screen3AddNewScreen when the action is triggered.
  onTapTxtAddnew(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
    );
  }

  /// Navigates to the screen7ResizePaperScreen when the action is triggered.
  onTapImgSlidesizeone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen7ResizePaperScreen,
    );
  }

  /// Navigates to the screen7ResizePaperScreen when the action is triggered.
  onTapTxtResizepaper(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen7ResizePaperScreen,
    );
  }

  /// Navigates to the screen9BackgroundColorTabContainerScreen when the action is triggered.
  onTapImgColorfillone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen9BackgroundColorTabContainerScreen,
    );
  }

  /// Navigates to the screen9BackgroundColorTabContainerScreen when the action is triggered.
  onTapTxtBgcolor(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen9BackgroundColorTabContainerScreen,
    );
  }
}
