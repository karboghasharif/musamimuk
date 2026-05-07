import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/screen_11_color_wheel_bloc.dart';
import 'models/screen_11_color_wheel_model.dart';

class Screen11ColorWheelPage extends StatefulWidget {
  const Screen11ColorWheelPage({super.key});
  @override
  Screen11ColorWheelPageState createState() => Screen11ColorWheelPageState();
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen11ColorWheelBloc>(
      create: (context) => Screen11ColorWheelBloc(Screen11ColorWheelState(
        screen11ColorWheelModelObj: const Screen11ColorWheelModel(),
      ))
        ..add(Screen11ColorWheelInitialEvent()),
      child: const Screen11ColorWheelPage(),
    );
  }
}

class Screen11ColorWheelPageState extends State<Screen11ColorWheelPage>
    with AutomaticKeepAliveClientMixin<Screen11ColorWheelPage> {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.maxFinite,
          decoration: AppDecoration.fillBlueGray,
          child: Column(
            children: [
              SizedBox(height: 14.v),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(left: 22.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.maxFinite,
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomImageView(
                                    imagePath: ImageConstant.imgRectangle5489,
                                    height: 51.v,
                                    width: 46.h,
                                    radius: BorderRadius.circular(
                                      10.h,
                                    ),
                                  ),
                                  BlocSelector<
                                      Screen11ColorWheelBloc,
                                      Screen11ColorWheelState,
                                      TextEditingController?>(
                                    selector: (state) =>
                                        state.edittextController,
                                    builder: (context, edittextController) {
                                      return CustomTextFormField(
                                        width: 46.h,
                                        controller: edittextController,
                                        borderDecoration:
                                            TextFormFieldStyleHelper.fillBlack,
                                        fillColor: appTheme.black900,
                                      );
                                    },
                                  ),
                                  BlocSelector<
                                      Screen11ColorWheelBloc,
                                      Screen11ColorWheelState,
                                      TextEditingController?>(
                                    selector: (state) =>
                                        state.edittextoneController,
                                    builder: (context, edittextoneController) {
                                      return CustomTextFormField(
                                        width: 45.h,
                                        controller: edittextoneController,
                                      );
                                    },
                                  ),
                                  Container(
                                    height: 51.v,
                                    width: 46.h,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(
                                        10.h,
                                      ),
                                    ),
                                  ),
                                  BlocSelector<
                                      Screen11ColorWheelBloc,
                                      Screen11ColorWheelState,
                                      TextEditingController?>(
                                    selector: (state) =>
                                        state.edittexttwoController,
                                    builder: (context, edittexttwoController) {
                                      return CustomTextFormField(
                                        width: 46.h,
                                        controller: edittexttwoController,
                                        borderDecoration:
                                            TextFormFieldStyleHelper
                                                .fillGrayTL10,
                                        fillColor: appTheme.gray40002,
                                      );
                                    },
                                  ),
                                  BlocSelector<
                                      Screen11ColorWheelBloc,
                                      Screen11ColorWheelState,
                                      TextEditingController?>(
                                    selector: (state) =>
                                        state.edittextthreeController,
                                    builder:
                                        (context, edittextthreeController) {
                                      return CustomTextFormField(
                                        width: 46.h,
                                        controller: edittextthreeController,
                                      );
                                    },
                                  ),
                                  Container(
                                    height: 51.v,
                                    width: 46.h,
                                    decoration: BoxDecoration(
                                      color: appTheme.red90001,
                                      borderRadius: BorderRadius.circular(
                                        10.h,
                                      ),
                                    ),
                                  ),
                                  BlocSelector<
                                      Screen11ColorWheelBloc,
                                      Screen11ColorWheelState,
                                      TextEditingController?>(
                                    selector: (state) =>
                                        state.edittextfourController,
                                    builder: (context, edittextfourController) {
                                      return CustomTextFormField(
                                        width: 45.h,
                                        controller: edittextfourController,
                                        textInputAction: TextInputAction.done,
                                        borderDecoration:
                                            TextFormFieldStyleHelper.fillRedA,
                                        fillColor: appTheme.redA70002,
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                            Container(
                              height: 51.v,
                              width: 46.h,
                              margin: EdgeInsets.only(left: 2.h),
                              decoration: BoxDecoration(
                                color: appTheme.redA700,
                                borderRadius: BorderRadius.circular(
                                  10.h,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 15.v),
                      CustomImageView(
                        imagePath: ImageConstant.imgPolygon1,
                        height: 47.v,
                        width: 103.h,
                        alignment: Alignment.centerRight,
                        margin: EdgeInsets.only(right: 47.h),
                      ),
                      SizedBox(height: 8.v),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 28.h,
                          right: 72.h,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: 3.v,
                                bottom: 2.v,
                              ),
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
                              padding: EdgeInsets.only(
                                left: 26.h,
                                bottom: 1.v,
                              ),
                              child: Column(
                                children: [
                                  CustomImageView(
                                    imagePath:
                                        ImageConstant.imgSlideSizeSvgrepoCom,
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
                                left: 23.h,
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
                                left: 24.h,
                                top: 1.v,
                                bottom: 2.v,
                              ),
                              child: Column(
                                children: [
                                  CustomImageView(
                                    imagePath: ImageConstant
                                        .imgColorFillSvgrepoComPrimary,
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
              )
            ],
          ),
        ),
      ),
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
