import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_drop_down.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/screen_7_resize_paper_bloc.dart';
import 'models/screen_7_resize_paper_model.dart';

class Screen7ResizePaperScreen extends StatelessWidget {
  const Screen7ResizePaperScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen7ResizePaperBloc>(
      create: (context) => Screen7ResizePaperBloc(
        Screen7ResizePaperState(
          valueoneController: TextEditingController(text: '200'),
          valuetwoController: TextEditingController(text: '200'),
          screen7ResizePaperModelObj: Screen7ResizePaperModel(),
        ),
      )..add(Screen7ResizePaperInitialEvent()),
      child: const Screen7ResizePaperScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        resizeToAvoidBottomInset: false,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRowView(context),
            SizedBox(height: AppDs.space1.v),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 3.v,
                width: 19.h,
                margin: EdgeInsets.only(left: AppDs.space6.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(
                    1.h,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppDs.space1.v),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: AppDs.space5.h),
                child: AppText(
                  "lbl_save".tr,
                  variant: AppTextVariant.caption,
                ),
              ),
            ),
            SizedBox(height: 81.v),
            SizedBox(
              height: 653.v,
              width: double.maxFinite,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 409.adaptSize,
                      width: 409.adaptSize,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onPrimaryContainer.withOpacity(1),
                        boxShadow: [
                          BoxShadow(
                            color: appTheme.black900.withOpacity(0.25),
                            spreadRadius: 2.h,
                            blurRadius: 2.h,
                            offset: const Offset(
                              0,
                              4,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  _buildColumnSelectSize(context),
                  CustomImageView(
                    imagePath: ImageConstant.imgPolygon1,
                    height: 47.v,
                    width: 103.h,
                    alignment: Alignment.bottomLeft,
                    margin: EdgeInsets.only(left: 110.h),
                  )
                ],
              ),
            ),
            SizedBox(height: 5.v),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDs.space6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      NavigatorService.pushNamed(AppRoutes.screen3AddNewScreen);
                    },
                    child: Column(
                      children: [
                        CustomIconButton(
                          height: 24.adaptSize,
                          width: 24.adaptSize,
                          child: CustomImageView(
                            imagePath: ImageConstant
                                .imgPlusSvgrepoComOnprimarycontainer,
                          ),
                        ),
                        SizedBox(height: 11.v),
                        Text(
                          "lbl_add_new".tr,
                          style: theme.textTheme.bodySmall,
                        )
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgSlideSizeSvgrepoComPrimary,
                        height: 30.adaptSize,
                        width: 30.adaptSize,
                      ),
                      SizedBox(height: 9.v),
                      Text(
                        "lbl_resize_paper".tr,
                        style: CustomTextStyles.bodySmallPrimary,
                      )
                    ],
                  ),
                  Column(
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgBlockchainSvgrepoCom,
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
    );
  }

  Widget _buildRowView(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 3.v,
            width: 30.h,
            margin: EdgeInsets.only(
              top: 11.v,
              bottom: 5.v,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(
                1.h,
              ),
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgReply,
            height: 19.adaptSize,
            width: 19.adaptSize,
          )
        ],
      ),
    );
  }

  Widget _buildColumnSelectSize(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AppCard(
        margin: EdgeInsets.only(bottom: AppDs.space6.v),
        padding: EdgeInsets.symmetric(
          horizontal: AppDs.space6.h,
          vertical: AppDs.space5.v,
        ),
        elevated: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              "lbl_select_size2".tr,
              variant: AppTextVariant.title,
            ),
            SizedBox(height: AppDs.space3.v),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: AppDs.space4.h),
                child: AppText(
                  "lbl_custom_size".tr,
                  variant: AppTextVariant.secondary,
                ),
              ),
            ),
            SizedBox(height: AppDs.space2.v),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocSelector<Screen7ResizePaperBloc, Screen7ResizePaperState,
                    TextEditingController?>(
                  selector: (state) => state.valueoneController,
                  builder: (context, valueoneController) {
                    return CustomTextFormField(
                      width: 115.h,
                      controller: valueoneController,
                      hintText: "lbl_200".tr,
                      textInputType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 30.h,
                        vertical: 14.v,
                      ),
                      borderDecoration: TextFormFieldStyleHelper.fillYellow,
                      fillColor: appTheme.yellow500,
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 17.v,
                    bottom: 14.v,
                  ),
                  child: AppText(
                    "lbl_x".tr,
                    variant: AppTextVariant.secondary,
                  ),
                ),
                BlocSelector<Screen7ResizePaperBloc, Screen7ResizePaperState,
                    TextEditingController?>(
                  selector: (state) => state.valuetwoController,
                  builder: (context, valuetwoController) {
                    return CustomTextFormField(
                      width: 115.h,
                      controller: valuetwoController,
                      hintText: "lbl_200".tr,
                      textInputType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 30.h,
                        vertical: 14.v,
                      ),
                      borderDecoration: TextFormFieldStyleHelper.fillYellow,
                      fillColor: appTheme.yellow500,
                    );
                  },
                ),
                BlocSelector<Screen7ResizePaperBloc, Screen7ResizePaperState,
                    Screen7ResizePaperModel?>(
                  selector: (state) => state.screen7ResizePaperModelObj,
                  builder: (context, screen7ResizePaperModelObj) {
                    return BlocBuilder<Screen7ResizePaperBloc,
                        Screen7ResizePaperState>(
                      buildWhen: (prev, curr) =>
                          prev.selectedDropDownValue !=
                          curr.selectedDropDownValue,
                      builder: (context, state) {
                        final items =
                            screen7ResizePaperModelObj?.dropdownItemList ?? [];
                        return CustomDropDown(
                          width: 122.h,
                          value: state.selectedDropDownValue,
                          icon: Container(
                            margin: EdgeInsets.symmetric(horizontal: 14.h),
                            child: CustomImageView(
                              imagePath: ImageConstant.imgArrowdownGray9001,
                              height: 16.adaptSize,
                              width: 16.adaptSize,
                            ),
                          ),
                          hintText: "lbl_pixels_px".tr,
                          items: items,
                          onChanged: (unit) {
                            context.read<Screen7ResizePaperBloc>().add(
                                  ResizePaperUnitSelectedEvent(unit: unit),
                                );
                          },
                        );
                      },
                    );
                  },
                )
              ],
            ),
            SizedBox(height: AppDs.space3.v),
            Container(
              padding: EdgeInsets.all(AppDs.space3.h),
              decoration: AppDecoration.fillYellow.copyWith(
                borderRadius: BorderRadiusStyle.roundedBorder10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowDownGray900,
                    height: 18.adaptSize,
                    width: 18.adaptSize,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12.h,
                        top: 3.v,
                        bottom: 3.v,
                      ),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackShape: const RoundedRectSliderTrackShape(),
                          activeTrackColor: appTheme.blueGray90004,
                          inactiveTrackColor:
                              appTheme.black900.withOpacity(0.08),
                          thumbColor: appTheme.blueGray90004,
                          thumbShape: const RoundSliderThumbShape(),
                        ),
                        child: Slider(
                          value: 4.51,
                          min: 0.0,
                          max: 100.0,
                          onChanged: (value) {},
                        ),
                      ),
                    ),
                  ),
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowLeft,
                    height: 17.adaptSize,
                    width: 17.adaptSize,
                    margin: EdgeInsets.only(left: 11.h),
                  )
                ],
              ),
            ),
            SizedBox(height: 10.v),
            Container(
              padding: EdgeInsets.all(15.h),
              decoration: AppDecoration.fillYellow.copyWith(
                borderRadius: BorderRadiusStyle.roundedBorder10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowDownGray900,
                    height: 18.adaptSize,
                    width: 18.adaptSize,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12.h,
                        top: 3.v,
                        bottom: 3.v,
                      ),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackShape: const RoundedRectSliderTrackShape(),
                          activeTrackColor: appTheme.blueGray90004,
                          inactiveTrackColor:
                              appTheme.black900.withOpacity(0.08),
                          thumbColor: appTheme.blueGray90004,
                          thumbShape: const RoundSliderThumbShape(),
                        ),
                        child: Slider(
                          value: 4.51,
                          min: 0.0,
                          max: 100.0,
                          onChanged: (value) {},
                        ),
                      ),
                    ),
                  ),
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowLeft,
                    height: 17.adaptSize,
                    width: 17.adaptSize,
                    margin: EdgeInsets.only(left: 11.h),
                  )
                ],
              ),
            ),
            SizedBox(height: AppDs.space12.v)
          ],
        ),
      ),
    );
  }

  /// Navigates to the screen8TransperantBgScreen when the action is triggered.
  onTapImgBlockchainone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen8TransperantBgScreen,
    );
  }

  /// Navigates to the screen8TransperantBgScreen when the action is triggered.
  onTapTxtTransparentbg(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen8TransperantBgScreen,
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
