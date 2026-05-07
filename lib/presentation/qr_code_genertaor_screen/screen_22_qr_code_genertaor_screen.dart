import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/screen_22_qr_code_genertaor_bloc.dart';
import 'models/screen_22_qr_code_genertaor_model.dart';

class Screen22QrCodeGenertaorScreen extends StatelessWidget {
  const Screen22QrCodeGenertaorScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen22QrCodeGenertaorBloc>(
      create:
          (context) => Screen22QrCodeGenertaorBloc(
            Screen22QrCodeGenertaorState(
              screen22QrCodeGenertaorModelObj:
                  const Screen22QrCodeGenertaorModel(),
            ),
          )..add(Screen22QrCodeGenertaorInitialEvent()),
      child: const Screen22QrCodeGenertaorScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      Screen22QrCodeGenertaorBloc,
      Screen22QrCodeGenertaorState
    >(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 45.v),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgArrowDownPrimary,
                      height: 32.adaptSize,
                      width: 32.adaptSize,
                      margin: EdgeInsets.only(left: 2.h),
                      onTap: () {
                        onTapImgArrowdownone(context);
                      },
                    ),
                    SizedBox(height: 36.v),
                    CustomImageView(
                      imagePath: ImageConstant.imgQrCodeSvgrepoComBlueGray70002,
                      height: 70.adaptSize,
                      width: 70.adaptSize,
                      alignment: Alignment.center,
                    ),
                    SizedBox(height: 41.v),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 147.h,
                        child: Text(
                          "msg_qr_code_generator".tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium!.copyWith(
                            height: 1.20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5.v),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 225.h,
                        child: Text(
                          "msg_generate_your_customize".tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: CustomTextStyles.bodyMedium15.copyWith(
                            height: 1.29,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 31.v),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.only(left: 70.h, right: 56.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "lbl_content".tr,
                              style: CustomTextStyles.titleSmallPrimary,
                            ),
                            Text(
                              "lbl_customization".tr,
                              style: CustomTextStyles.bodyMedium15,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.v),
                    Container(
                      height: 5.v,
                      width: 35.h,
                      margin: EdgeInsets.only(left: 85.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2.h),
                      ),
                    ),
                    SizedBox(height: 39.v),
                    Padding(
                      padding: EdgeInsets.only(left: 29.h),
                      child: Text(
                        "lbl_website_url".tr,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    SizedBox(height: 95.v),
                    Padding(
                      padding: EdgeInsets.only(left: 29.h),
                      child: Text(
                        "msg_choose_a_template".tr,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    SizedBox(height: 10.v),
                    _buildEnhancedQrButton(context),
                    SizedBox(height: 20.v),
                    _buildRowGridOne(context),
                    SizedBox(height: 5.v),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedQrButton(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: theme.colorScheme.primary,
                size: 24.adaptSize,
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Advanced QR Generator",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      "Create custom QR codes with logos, colors, and advanced options",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.v),
          SizedBox(
            width: double.maxFinite,
            child: CustomElevatedButton(
              height: 50.v,
              text: "Open Advanced Generator",
              buttonStyle: CustomButtonStyles.fillPrimary,
              buttonTextStyle: CustomTextStyles.titleMediumBold,
              onPressed: () {
                NavigatorService.pushNamed(AppRoutes.enhancedQrGeneratorScreen);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowGridOne(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.v),
      decoration: AppDecoration.fillGray90002.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder7,
      ),
      child: Row(
        children: [
          Container(
            height: 77.v,
            width: 82.h,
            margin: EdgeInsets.only(bottom: 1.v),
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 11.v),
            decoration: AppDecoration.fillOnPrimaryContainer1.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder7,
            ),
            child: CustomImageView(
              imagePath: ImageConstant.imgGrid,
              height: 50.v,
              width: 48.h,
              alignment: Alignment.topCenter,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgPrinter,
            height: 52.adaptSize,
            width: 52.adaptSize,
            margin: EdgeInsets.only(left: 16.h, top: 11.v, bottom: 13.v),
          ),
          const Spacer(),
          CustomImageView(
            imagePath: ImageConstant.imgPrinterOnprimarycontainer,
            height: 54.adaptSize,
            width: 54.adaptSize,
            margin: EdgeInsets.only(top: 11.v, bottom: 12.v),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(28.h, 11.v, 21.h, 11.v),
            child: QrImageView(
              data: 'https://www.google.com',
              size: 55.adaptSize,
            ),
          ),
        ],
      ),
    );
  }

  // Navigates to the screen1HomeScreen when the action is triggered.
  onTapImgArrowdownone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen1HomeScreen);
  }
}
