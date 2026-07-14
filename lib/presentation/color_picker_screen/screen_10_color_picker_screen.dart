import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_outlined_button.dart';
import 'bloc/screen_10_color_picker_bloc.dart';
import 'models/screen_10_color_picker_model.dart';

class Screen10ColorPickerScreen extends StatelessWidget {
  const Screen10ColorPickerScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen10ColorPickerBloc>(
      create: (context) => Screen10ColorPickerBloc(Screen10ColorPickerState(
        screen10ColorPickerModelObj: const Screen10ColorPickerModel(),
      ))
        ..add(Screen10ColorPickerInitialEvent()),
      child: const Screen10ColorPickerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Screen10ColorPickerBloc, Screen10ColorPickerState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: AppDs.surfaceBase,
            body: Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(vertical: AppDs.space6.v),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRowview(context),
                  SizedBox(height: 81.v),
                  _buildStacklinefive(context),
                  SizedBox(height: 90.v),
                  _buildRow(context),
                  CustomImageView(
                    imagePath: ImageConstant.imgPolygon1,
                    height: 47.v,
                    width: 103.h,
                    alignment: Alignment.centerRight,
                    margin: EdgeInsets.only(right: 25.h),
                  ),
                  SizedBox(height: 8.v),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppDs.space6.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 3.v),
                          child: Column(
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
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 25.h),
                          child: Column(
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
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 22.h,
                            top: 2.v,
                          ),
                          child: Column(
                            children: [
                              CustomImageView(
                                imagePath:
                                    ImageConstant.imgBlockchainSvgrepoCom,
                                height: 24.adaptSize,
                                width: 24.adaptSize,
                                onTap: () {
                                  onTapImgBlockchainone(context);
                                },
                              ),
                              SizedBox(height: 14.v),
                              GestureDetector(
                                onTap: () {
                                  onTapTxtTransparentbg(context);
                                },
                                child: Text(
                                  "lbl_transparent_bg".tr,
                                  style: theme.textTheme.bodySmall,
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 23.h,
                            top: 1.v,
                            bottom: 2.v,
                          ),
                          child: Column(
                            children: [
                              CustomImageView(
                                imagePath:
                                    ImageConstant.imgColorFillSvgrepoComPrimary,
                                height: 26.adaptSize,
                                width: 26.adaptSize,
                              ),
                              SizedBox(height: 10.v),
                              Text(
                                "lbl_bg_color".tr,
                                style: CustomTextStyles.bodySmallPrimary,
                              )
                            ],
                          ),
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

  Widget _buildRowview(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space6.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 11.v,
              bottom: 17.v,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.v,
                  width: 30.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(
                      1.h,
                    ),
                  ),
                ),
                SizedBox(height: 7.v),
                Container(
                  height: 3.v,
                  width: 19.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(
                      1.h,
                    ),
                  ),
                )
              ],
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

  Widget _buildStacklinefive(BuildContext context) {
    return SizedBox(
      height: 409.adaptSize,
      width: 409.adaptSize,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgRectangle6409x409,
            height: 409.adaptSize,
            width: 409.adaptSize,
            alignment: Alignment.center,
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                left: 81.h,
                top: 13.v,
                right: 13.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgEllipse12,
                    height: 61.adaptSize,
                    width: 61.adaptSize,
                    radius: BorderRadius.circular(
                      30.h,
                    ),
                    alignment: Alignment.centerRight,
                  ),
                  SizedBox(height: 183.v),
                  Container(
                    width: 55.h,
                    margin: EdgeInsets.only(right: 260.h),
                    padding: EdgeInsets.all(13.h),
                    decoration: AppDecoration.outlineBlack.copyWith(
                      borderRadius: BorderRadiusStyle.roundedBorder27,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgLine5,
                          height: 7.v,
                          width: 1.h,
                          margin: EdgeInsets.only(right: 9.h),
                        ),
                        SizedBox(height: 4.v),
                        CustomImageView(
                          imagePath: ImageConstant.imgLine7,
                          height: 1.v,
                          width: 7.h,
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgLine7,
                          height: 1.v,
                          width: 7.h,
                          alignment: Alignment.centerLeft,
                        ),
                        SizedBox(height: 2.v),
                        CustomImageView(
                          imagePath: ImageConstant.imgLine5,
                          height: 7.v,
                          width: 1.h,
                          margin: EdgeInsets.only(right: 9.h),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space4.h,
        vertical: AppDs.space5.v,
      ),
      elevated: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgEllipse12,
            height: 61.adaptSize,
            width: 61.adaptSize,
            radius: BorderRadius.circular(
              30.h,
            ),
            margin: EdgeInsets.only(
              left: 3.h,
              top: 4.v,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 11.v,
              bottom: 6.v,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomOutlinedButton(
                  width: 121.h,
                  text: "lbl_cancel".tr,
                ),
                SizedBox(width: AppDs.space3.h),
                AppPrimaryButton(
                  label: "lbl_apply".tr,
                  expandWidth: false,
                  onPressed: () {
                    onTapApply(context);
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  onTapApply(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
    );
  }

  onTapBtnPlussvgrepoone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
    );
  }

  onTapTxtAddnew(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
    );
  }

  onTapImgSlidesizeone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen7ResizePaperScreen,
    );
  }

  onTapTxtResizepaper(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen7ResizePaperScreen,
    );
  }

  onTapImgBlockchainone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen8TransperantBgScreen,
    );
  }

  onTapTxtTransparentbg(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen8TransperantBgScreen,
    );
  }
}
