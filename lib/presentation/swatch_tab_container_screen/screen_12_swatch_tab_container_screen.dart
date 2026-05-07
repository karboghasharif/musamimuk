import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_text_form_field.dart';
import '../swatch_page/screen_12_swatch_page.dart';
import 'bloc/screen_12_swatch_tab_container_bloc.dart';
import 'models/screen_12_swatch_tab_container_model.dart';

class Screen12SwatchTabContainerScreen extends StatefulWidget {
  const Screen12SwatchTabContainerScreen({super.key});
  @override
  Screen12SwatchTabContainerScreenState createState() =>
      Screen12SwatchTabContainerScreenState();
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen12SwatchTabContainerBloc>(
      create:
          (context) => Screen12SwatchTabContainerBloc(
            Screen12SwatchTabContainerState(
              screen12SwatchTabContainerModelObj:
                  const Screen12SwatchTabContainerModel(),
            ),
          )..add(Screen12SwatchTabContainerInitialEvent()),
      child: const Screen12SwatchTabContainerScreen(),
    );
  }
}

class Screen12SwatchTabContainerScreenState
    extends State<Screen12SwatchTabContainerScreen>
    with TickerProviderStateMixin {
  late TabController tabviewController;
  @override
  void initState() {
    super.initState();
    tabviewController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                  SizedBox(
                    height: 608.v,
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
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 20.v),
                            decoration: AppDecoration.fillPrimary.copyWith(
                              borderRadius: BorderRadiusStyle.roundedBorder33,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 3.v),
                                CustomImageView(
                                  imagePath: ImageConstant.imgArrowRight,
                                  height: 9.adaptSize,
                                  width: 9.adaptSize,
                                  alignment: Alignment.centerRight,
                                  margin: EdgeInsets.only(right: 30.h),
                                  onTap: () {
                                    onTapImgArrowrightone(context);
                                  },
                                ),
                                SizedBox(height: 18.v),
                                _buildStackViewThree(context),
                                _buildRowView1(context),
                                _buildRowView2(context),
                                SizedBox(height: 14.v),
                                _buildRow(context),
                                SizedBox(height: 60.v),
                                _buildRowView3(context),
                              ],
                            ),
                          ),
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgRectangle5562,
                          height: 50.v,
                          width: 426.h,
                          alignment: Alignment.bottomCenter,
                          margin: EdgeInsets.only(bottom: 108.v),
                        ),
                        Container(
                          height: 66.v,
                          width: 320.h,
                          margin: EdgeInsets.only(bottom: 85.v),
                          child: TabBar(
                            controller: tabviewController,
                            labelPadding: EdgeInsets.zero,
                            labelColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              fontSize: 8.fSize,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                            unselectedLabelColor: appTheme.blueGray90004,
                            unselectedLabelStyle: TextStyle(
                              fontSize: 8.fSize,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                            indicatorPadding: EdgeInsets.all(0.5.h),
                            indicator: BoxDecoration(
                              color: appTheme.blueGray90004,
                              borderRadius: BorderRadius.circular(10.h),
                            ),
                            tabs: [
                              Tab(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.h,
                                    vertical: 10.v,
                                  ),
                                  decoration: AppDecoration.fillYellow.copyWith(
                                    borderRadius:
                                        BorderRadiusStyle.roundedBorder10,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CustomImageView(
                                        imagePath:
                                            ImageConstant
                                                .imgColorPickerSvgrepoCom,
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
                                    borderRadius:
                                        BorderRadiusStyle.roundedBorder10,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomImageView(
                                        imagePath:
                                            ImageConstant.imgColorWheelBla,
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
                                  decoration: AppDecoration.fillBluegray90004
                                      .copyWith(
                                        borderRadius:
                                            BorderRadiusStyle.roundedBorder10,
                                      ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CustomImageView(
                                        imagePath:
                                            ImageConstant
                                                .imgColorSwatchSvgrepoComPrimary,
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
                                    borderRadius:
                                        BorderRadiusStyle.roundedBorder10,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomImageView(
                                        imagePath:
                                            ImageConstant.imgOpacitySvgrepoCom,
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
                                    borderRadius:
                                        BorderRadiusStyle.roundedBorder10,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomImageView(
                                        imagePath:
                                            ImageConstant.imgRecentSvgrepoCom,
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
                  _buildTabBarView(context),
                ],
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildStackViewThree(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 28.h, right: 32.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 58.v,
            width: 64.h,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 37.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.red900,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.red700),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 37.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.pink900,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.pink700),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 37.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.purple900,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.purple700),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 37.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.deepPurple900,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 37.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue900,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.blue700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowView1(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 28.h, right: 32.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 29.v,
            width: 64.h,
            decoration: BoxDecoration(color: appTheme.red500),
          ),
          Container(
            height: 29.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            decoration: BoxDecoration(color: appTheme.pink500),
          ),
          Container(
            height: 29.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            decoration: BoxDecoration(color: appTheme.purple500),
          ),
          Container(
            height: 29.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            decoration: BoxDecoration(color: appTheme.deepPurple500),
          ),
          Container(
            height: 29.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            decoration: BoxDecoration(color: appTheme.blue500),
          ),
        ],
      ),
    );
  }

  Widget _buildRowView2(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 28.h, right: 32.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 58.v,
            width: 64.h,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 42.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.red100,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.red300),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 42.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.pink100,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.pink300),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 42.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.purple100,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.purple300),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 42.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.deepPurple100,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.deepPurple300),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 42.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue100,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 29.v,
                    width: 64.h,
                    decoration: BoxDecoration(color: appTheme.blue300),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 28.h, right: 32.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 37.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.cyan900,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.cyan700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 37.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.green900,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.green700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 37.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.lime90001,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.lime700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 37.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.gray90003,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.pink90001,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 29.v,
                      width: 64.h,
                      decoration: BoxDecoration(color: appTheme.cyan500),
                    ),
                    Container(
                      height: 29.v,
                      width: 64.h,
                      decoration: BoxDecoration(color: appTheme.green500),
                    ),
                    Container(
                      height: 29.v,
                      width: 64.h,
                      decoration: BoxDecoration(color: appTheme.lime500),
                    ),
                    Container(
                      height: 29.v,
                      width: 64.h,
                      decoration: BoxDecoration(color: appTheme.purple400),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 42.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.cyan100,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.cyan300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 42.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.greenA100,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.green300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 42.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.yellow200,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.lime300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 58.v,
                      width: 64.h,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 42.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.pink50,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 29.v,
                              width: 64.h,
                              decoration: BoxDecoration(
                                color: appTheme.purpleA200,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 145.v,
            width: 64.h,
            margin: EdgeInsets.only(left: 12.h),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 42.v,
                    width: 64.h,
                    decoration: BoxDecoration(
                      color: appTheme.gray300,
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 58.v,
                        width: 64.h,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: 37.v,
                                width: 64.h,
                                decoration: BoxDecoration(
                                  color: appTheme.gray80002,
                                  borderRadius: BorderRadius.circular(4.h),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 29.v,
                                width: 64.h,
                                decoration: BoxDecoration(
                                  color: appTheme.gray70001,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 29.v,
                        width: 64.h,
                        decoration: BoxDecoration(color: appTheme.gray500),
                      ),
                      Container(
                        height: 29.v,
                        width: 64.h,
                        decoration: BoxDecoration(color: appTheme.gray400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdittext(BuildContext context) {
    return BlocSelector<
      Screen12SwatchTabContainerBloc,
      Screen12SwatchTabContainerState,
      TextEditingController?
    >(
      selector: (state) => state.edittextController,
      builder: (context, edittextController) {
        return CustomTextFormField(
          width: 46.h,
          controller: edittextController,
          borderDecoration: TextFormFieldStyleHelper.fillBlack,
          fillColor: appTheme.black900,
        );
      },
    );
  }

  Widget _buildEdittextone(BuildContext context) {
    return BlocSelector<
      Screen12SwatchTabContainerBloc,
      Screen12SwatchTabContainerState,
      TextEditingController?
    >(
      selector: (state) => state.edittextoneController,
      builder: (context, edittextoneController) {
        return CustomTextFormField(
          width: 45.h,
          controller: edittextoneController,
        );
      },
    );
  }

  Widget _buildEdittexttwo(BuildContext context) {
    return BlocSelector<
      Screen12SwatchTabContainerBloc,
      Screen12SwatchTabContainerState,
      TextEditingController?
    >(
      selector: (state) => state.edittexttwoController,
      builder: (context, edittexttwoController) {
        return CustomTextFormField(
          width: 46.h,
          controller: edittexttwoController,
          borderDecoration: TextFormFieldStyleHelper.fillGrayTL10,
          fillColor: appTheme.gray40002,
        );
      },
    );
  }

  Widget _buildEdittextthree(BuildContext context) {
    return BlocSelector<
      Screen12SwatchTabContainerBloc,
      Screen12SwatchTabContainerState,
      TextEditingController?
    >(
      selector: (state) => state.edittextthreeController,
      builder: (context, edittextthreeController) {
        return CustomTextFormField(
          width: 46.h,
          controller: edittextthreeController,
        );
      },
    );
  }

  Widget _buildEdittextfour(BuildContext context) {
    return BlocSelector<
      Screen12SwatchTabContainerBloc,
      Screen12SwatchTabContainerState,
      TextEditingController?
    >(
      selector: (state) => state.edittextfourController,
      builder: (context, edittextfourController) {
        return CustomTextFormField(
          width: 45.h,
          controller: edittextfourController,
          textInputAction: TextInputAction.done,
          borderDecoration: TextFormFieldStyleHelper.fillRedA,
          fillColor: appTheme.redA70002,
        );
      },
    );
  }

  Widget _buildRowView3(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: double.maxFinite,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgRectangle5489,
                    height: 51.v,
                    width: 46.h,
                    radius: BorderRadius.circular(10.h),
                  ),
                  _buildEdittext(context),
                  _buildEdittextone(context),
                  Container(
                    height: 51.v,
                    width: 46.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10.h),
                    ),
                  ),
                  _buildEdittexttwo(context),
                  _buildEdittextthree(context),
                  Container(
                    height: 51.v,
                    width: 46.h,
                    decoration: BoxDecoration(
                      color: appTheme.red90001,
                      borderRadius: BorderRadius.circular(10.h),
                    ),
                  ),
                  _buildEdittextfour(context),
                ],
              ),
            ),
            Container(
              height: 51.v,
              width: 46.h,
              margin: EdgeInsets.only(left: 2.h),
              decoration: BoxDecoration(
                color: appTheme.redA700,
                borderRadius: BorderRadius.circular(10.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context) {
    return SizedBox(
      height: 237.v,
      child: TabBarView(
        controller: tabviewController,
        children: [
          Screen12SwatchPage.builder(context),
          Screen12SwatchPage.builder(context),
          Screen12SwatchPage.builder(context),
          Screen12SwatchPage.builder(context),
          Screen12SwatchPage.builder(context),
        ],
      ),
    );
  }

  onTapImgArrowrightone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen9BackgroundColorTabContainerScreen,
    );
  }
}
