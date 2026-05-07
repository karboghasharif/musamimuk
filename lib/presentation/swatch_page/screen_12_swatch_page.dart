import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';
import 'bloc/screen_12_swatch_bloc.dart';
import 'models/screen_12_swatch_model.dart';

class Screen12SwatchPage extends StatefulWidget {
  const Screen12SwatchPage({super.key});
  @override
  Screen12SwatchPageState createState() => Screen12SwatchPageState();
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen12SwatchBloc>(
      create: (context) => Screen12SwatchBloc(Screen12SwatchState(
        screen12SwatchModelObj: const Screen12SwatchModel(),
      ))
        ..add(Screen12SwatchInitialEvent()),
      child: const Screen12SwatchPage(),
    );
  }
}

class Screen12SwatchPageState extends State<Screen12SwatchPage>
    with AutomaticKeepAliveClientMixin<Screen12SwatchPage> {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Screen12SwatchBloc, Screen12SwatchState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: Container(
              width: double.maxFinite,
              decoration: AppDecoration.fillBlueGray,
              child: Column(
                children: [
                  SizedBox(height: 80.v),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 50.h,
                        right: 25.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomImageView(
                            imagePath: ImageConstant.imgPolygon1,
                            height: 47.v,
                            width: 103.h,
                            alignment: Alignment.centerRight,
                          ),
                          SizedBox(height: 8.v),
                          Padding(
                            padding: EdgeInsets.only(right: 25.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  padding: EdgeInsets.only(bottom: 1.v),
                                  child: Column(
                                    children: [
                                      CustomImageView(
                                        imagePath: ImageConstant
                                            .imgSlideSizeSvgrepoCom,
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
                                  padding: EdgeInsets.only(top: 2.v),
                                  child: Column(
                                    children: [
                                      CustomImageView(
                                        imagePath: ImageConstant
                                            .imgBlockchainSvgrepoCom,
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
                                        style:
                                            CustomTextStyles.bodySmallPrimary,
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
      },
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
