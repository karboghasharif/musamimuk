import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../background_color_page/screen_9_background_color_page.dart';
import 'bloc/screen_9_background_color_tab_container_bloc.dart';
import 'models/screen_9_background_color_tab_container_model.dart';

class Screen9BackgroundColorTabContainerScreen extends StatefulWidget {
  const Screen9BackgroundColorTabContainerScreen({super.key});
  @override
  Screen9BackgroundColorTabContainerScreenState createState() =>
      Screen9BackgroundColorTabContainerScreenState();
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen9BackgroundColorTabContainerBloc>(
      create:
          (context) => Screen9BackgroundColorTabContainerBloc(
            Screen9BackgroundColorTabContainerState(
              screen9BackgroundColorTabContainerModelObj:
                  const Screen9BackgroundColorTabContainerModel(),
            ),
          )..add(Screen9BackgroundColorTabContainerInitialEvent()),
      child: const Screen9BackgroundColorTabContainerScreen(),
    );
  }
} // ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable

class Screen9BackgroundColorTabContainerScreenState
    extends State<Screen9BackgroundColorTabContainerScreen>
    with TickerProviderStateMixin {
  late TabController tabviewController;
  @override
  void initState() {
    super.initState();
    tabviewController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      Screen9BackgroundColorTabContainerBloc,
      Screen9BackgroundColorTabContainerState
    >(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  SizedBox(height: 43.v),
                  Column(
                    children: [
                      _buildRowView(context),
                      SizedBox(height: 2.v),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 3.v,
                          width: 19.h,
                          margin: EdgeInsets.only(left: 28.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(1.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.v),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 26.h),
                          child: Text(
                            "lbl_save".tr,
                            style: CustomTextStyles.bodySmall10,
                          ),
                        ),
                      ),
                      SizedBox(height: 81.v),
                      Container(
                        height: 409.adaptSize,
                        width: 409.adaptSize,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(1),
                          boxShadow: [
                            BoxShadow(
                              color: appTheme.black900.withOpacity(0.25),
                              spreadRadius: 2.h,
                              blurRadius: 2.h,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.v),
                      _buildStackCreateFrom(context),
                      _buildTabBarView(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRowView(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 3.v,
            width: 30.h,
            margin: EdgeInsets.only(top: 11.v, bottom: 5.v),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(1.h),
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgReply,
            height: 19.adaptSize,
            width: 19.adaptSize,
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildStackCreateFrom(BuildContext context) {
    return SizedBox(
      height: 185.v,
      width: double.maxFinite,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 185.v,
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(33.h),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(left: 54.h, top: 19.v, right: 27.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowRight,
                    height: 9.adaptSize,
                    width: 9.adaptSize,
                    alignment: Alignment.centerRight,
                  ),
                  SizedBox(height: 10.v),
                  SizedBox(
                    height: 66.v,
                    width: 320.h,
                    child: TabBar(
                      controller: tabviewController,
                      labelPadding: EdgeInsets.zero,
                      tabs: [
                        Tab(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.h,
                              vertical: 10.v,
                            ),
                            decoration: AppDecoration.fillYellow.copyWith(
                              borderRadius: BorderRadiusStyle.roundedBorder10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath:
                                      ImageConstant.imgColorPickerSvgrepoCom,
                                  height: 26.adaptSize,
                                  width: 26.adaptSize,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 5.v,
                                    bottom: 1.v,
                                  ),
                                  child: Text("lbl_picker".tr),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 17.h,
                              vertical: 10.v,
                            ),
                            decoration: AppDecoration.fillYellow.copyWith(
                              borderRadius: BorderRadiusStyle.roundedBorder10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomImageView(
                                  imagePath: ImageConstant.imgColorWheelBla,
                                  height: 22.adaptSize,
                                  width: 22.adaptSize,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 9.v),
                                  child: Text("lbl_wheel".tr),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.h,
                              vertical: 9.v,
                            ),
                            decoration: AppDecoration.fillYellow.copyWith(
                              borderRadius: BorderRadiusStyle.roundedBorder10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath:
                                      ImageConstant.imgColorSwatchSvgrepoCom,
                                  height: 24.adaptSize,
                                  width: 24.adaptSize,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 9.v,
                                    bottom: 1.v,
                                  ),
                                  child: Text("lbl_swatch".tr),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.h,
                              vertical: 9.v,
                            ),
                            decoration: AppDecoration.fillYellow.copyWith(
                              borderRadius: BorderRadiusStyle.roundedBorder10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomImageView(
                                  imagePath: ImageConstant.imgOpacitySvgrepoCom,
                                  height: 26.adaptSize,
                                  width: 26.adaptSize,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 10.v),
                                  child: Text("lbl_transparency".tr),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.h,
                              vertical: 3.v,
                            ),
                            decoration: AppDecoration.fillYellow.copyWith(
                              borderRadius: BorderRadiusStyle.roundedBorder10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomImageView(
                                  imagePath: ImageConstant.imgRecentSvgrepoCom,
                                  height: 38.adaptSize,
                                  width: 38.adaptSize,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 1.v,
                                    bottom: 7.v,
                                  ),
                                  child: Text("lbl_recent".tr),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTabBarView(BuildContext context) {
    return SizedBox(
      height: 237.v,
      child: TabBarView(
        controller: tabviewController,
        children: [
          Screen9BackgroundColorPage.builder(context),
          Screen9BackgroundColorPage.builder(context),
          Screen9BackgroundColorPage.builder(context),
          Screen9BackgroundColorPage.builder(context),
          Screen9BackgroundColorPage.builder(context),
        ],
      ),
    );
  }
}
