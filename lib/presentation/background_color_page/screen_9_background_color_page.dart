import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';
import 'bloc/screen_9_background_color_bloc.dart';
import 'models/screen_9_background_color_model.dart'; // ignore_for_file: must_be_immutable

class Screen9BackgroundColorPage extends StatefulWidget {
  const Screen9BackgroundColorPage({super.key});
  @override
  Screen9BackgroundColorPageState createState() =>
      Screen9BackgroundColorPageState();
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen9BackgroundColorBloc>(
      create: (context) => Screen9BackgroundColorBloc(
        Screen9BackgroundColorState(
          screen9BackgroundColorModelObj: const Screen9BackgroundColorModel(),
        ),
      )..add(Screen9BackgroundColorInitialEvent()),
      child: const Screen9BackgroundColorPage(),
    );
  }
}

class Screen9BackgroundColorPageState extends State<Screen9BackgroundColorPage>
    with AutomaticKeepAliveClientMixin<Screen9BackgroundColorPage> {
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
                      // Row(
                      //   children: [
                      // Expanded(
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       CustomImageView(
                      //         imagePath: ImageConstant.imgRectangle5489,
                      //         height: 51.v,
                      //         width: 46.h,
                      //         radius: BorderRadius.circular(
                      //           10.h,
                      //         ),
                      //       ),
                      //       BlocSelector<
                      //           Screen9BackgroundColorBloc,
                      //           Screen9BackgroundColorState,
                      //           TextEditingController?>(
                      //         selector: (state) => state.edittextController,
                      //         builder: (context, edittextController) {
                      //           return CustomTextFormField(
                      //             width: 46.h,
                      //             controller: edittextController,
                      //             borderDecoration:
                      //                 TextFormFieldStyleHelper.fillBlack,
                      //             fillColor: appTheme.black900,
                      //           );
                      //         },
                      //       ),
                      //       BlocSelector<
                      //           Screen9BackgroundColorBloc,
                      //           Screen9BackgroundColorState,
                      //           TextEditingController?>(
                      //         selector: (state) =>
                      //             state.edittextoneController,
                      //         builder: (context, edittextoneController) {
                      //           return CustomTextFormField(
                      //             width: 45.h,
                      //             controller: edittextoneController,
                      //           );
                      //         },
                      //       ),
                      //       Container(
                      //         height: 51.v,
                      //         width: 46.h,
                      //         decoration: BoxDecoration(
                      //           color: theme.colorScheme.errorContainer,
                      //           borderRadius: BorderRadius.circular(
                      //             10.h,
                      //           ),
                      //         ),
                      //       ),
                      //           BlocSelector<
                      //               Screen9BackgroundColorBloc,
                      //               Screen9BackgroundColorState,
                      //               TextEditingController?>(
                      //             selector: (state) =>
                      //                 state.edittexttwoController,
                      //             builder: (context, edittexttwoController) {
                      //               return CustomTextFormField(
                      //                 width: 46.h,
                      //                 controller: edittexttwoController,
                      //                 borderDecoration:
                      //                     TextFormFieldStyleHelper.fillGrayTL10,
                      //                 fillColor: appTheme.gray40002,
                      //               );
                      //             },
                      //           ),
                      //           BlocSelector<
                      //               Screen9BackgroundColorBloc,
                      //               Screen9BackgroundColorState,
                      //               TextEditingController?>(
                      //             selector: (state) =>
                      //                 state.edittextthreeController,
                      //             builder: (context, edittextthreeController) {
                      //               return CustomTextFormField(
                      //                 width: 46.h,
                      //                 controller: edittextthreeController,
                      //               );
                      //             },
                      //           ),
                      //           Container(
                      //             height: 51.v,
                      //             width: 46.h,
                      //             decoration: BoxDecoration(
                      //               color: appTheme.red90001,
                      //               borderRadius: BorderRadius.circular(
                      //                 10.h,
                      //               ),
                      //             ),
                      //           ),
                      //           BlocSelector<
                      //               Screen9BackgroundColorBloc,
                      //               Screen9BackgroundColorState,
                      //               TextEditingController?>(
                      //             selector: (state) =>
                      //                 state.edittextfourController,
                      //             builder: (context, edittextfourController) {
                      //               return CustomTextFormField(
                      //                 width: 45.h,
                      //                 controller: edittextfourController,
                      //                 textInputAction: TextInputAction.done,
                      //                 borderDecoration:
                      //                     TextFormFieldStyleHelper.fillRedA,
                      //                 fillColor: appTheme.redA70002,
                      //               );
                      //             },
                      //           )
                      //         ],
                      //       ),
                      //     ),
                      //     Container(
                      //       height: 51.v,
                      //       width: 46.h,
                      //       margin: EdgeInsets.only(left: 2.h),
                      //       decoration: BoxDecoration(
                      //         color: appTheme.redA700,
                      //         borderRadius: BorderRadius.circular(
                      //           10.h,
                      //         ),
                      //       ),
                      //     ),
                      //     Container(
                      //       height: 51.v,
                      //       width: 46.h,
                      //       margin: EdgeInsets.only(left: 2.h),
                      //       decoration: BoxDecoration(
                      //         color: appTheme.redA400,
                      //         borderRadius: BorderRadius.circular(
                      //           10.h,
                      //         ),
                      //       ),
                      //     ),
                      //     Container(
                      //       height: 51.v,
                      //       width: 46.h,
                      //       margin: EdgeInsets.only(left: 2.h),
                      //       decoration: BoxDecoration(
                      //         color: appTheme.redA400,
                      //         borderRadius: BorderRadius.circular(
                      //           4.h,
                      //         ),
                      //       ),
                      //     )
                      //   ],
                      // ),
                      // SizedBox(height: 15.v),
                      // CustomImageView(
                      //   imagePath: ImageConstant.imgPolygon1,
                      //   height: 47.v,
                      //   width: 103.h,
                      //   alignment: Alignment.centerRight,
                      //   margin: EdgeInsets.only(right: 25.h),
                      // ),
                      // SizedBox(height: 8.v),
                      Padding(
                        padding: EdgeInsets.only(left: 28.h, right: 50.h),
                        child: Row(
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
                                ),
                              ],
                            ),
                            Column(
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
                                ),
                              ],
                            ),
                            Column(
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
                                ),
                              ],
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
                                  ),
                                ],
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
        ),
      ),
    );
  }

  onTapBtnPlussvgrepoone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen3AddNewScreen);
  }

  /// Navigates to the screen3AddNewScreen when the action is triggered.
  onTapTxtAddnew(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen3AddNewScreen);
  }

  /// Navigates to the screen7ResizePaperScreen when the action is triggered.
  onTapImgSlidesizeone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen7ResizePaperScreen);
  }

  /// Navigates to the screen7ResizePaperScreen when the action is triggered.
  onTapTxtResizepaper(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen7ResizePaperScreen);
  }

  /// Navigates to the screen8TransperantBgScreen when the action is triggered.
  onTapImgBlockchainone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen8TransperantBgScreen);
  }

  /// Navigates to the screen8TransperantBgScreen when the action is triggered.
  onTapTxtTransparentbg(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen8TransperantBgScreen);
  }
}
