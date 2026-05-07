import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class Screen15MenuBarDraweritem extends StatelessWidget {
  const Screen15MenuBarDraweritem({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        width: 354.h,
        padding: EdgeInsets.symmetric(
          horizontal: 37.h,
          vertical: 52.v,
        ),
        decoration: AppDecoration.outlineBlack900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 96.h),
                padding: EdgeInsets.symmetric(
                  horizontal: 33.h,
                  vertical: 14.v,
                ),
                decoration: AppDecoration.fillPrimary.copyWith(
                  borderRadius: BorderRadiusStyle.circleBorder44,
                ),
                child: Text(
                  "lbl_j".tr,
                  style: theme.textTheme.displaySmall,
                ),
              ),
            ),
            SizedBox(height: 14.v),
            Align(
              alignment: Alignment.center,
              child: Text(
                "lbl_jonathan_saul".tr,
                style: CustomTextStyles.bodyLargePoppins,
              ),
            ),
            SizedBox(height: 42.v),
            const Divider(),
            SizedBox(height: 44.v),
            Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgHomeSmileSvgrepoCom,
                    height: 28.adaptSize,
                    width: 28.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 25.h,
                      top: 2.v,
                      bottom: 3.v,
                    ),
                    child: Text(
                      "lbl_home".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 41.v),
            Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgGridSvgrepoCom,
                    height: 26.adaptSize,
                    width: 26.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 26.h,
                      top: 2.v,
                    ),
                    child: Text(
                      "lbl_online_designs2".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 37.v),
            Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgAppsAdd2,
                    height: 25.adaptSize,
                    width: 25.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 25.h,
                      top: 3.v,
                    ),
                    child: Text(
                      "lbl_my_designs".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 43.v),
            Padding(
              padding: EdgeInsets.only(
                left: 16.h,
                right: 53.h,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgQrCodeSvgrepoCom,
                    height: 28.adaptSize,
                    width: 28.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24.h,
                      top: 2.v,
                      bottom: 4.v,
                    ),
                    child: Text(
                      "msg_generate_qr_code".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 36.v),
            Padding(
              padding: EdgeInsets.only(
                left: 16.h,
                right: 37.h,
              ),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgEyeOnprimarycontainer,
                    height: 25.adaptSize,
                    width: 25.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 25.h,
                      top: 4.v,
                    ),
                    child: Text(
                      "msg_remove_background".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 41.v),
            Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgStarSvgrepoCom,
                    height: 27.adaptSize,
                    width: 27.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 25.h,
                      top: 5.v,
                    ),
                    child: Text(
                      "lbl_rate_app".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 39.v),
            Padding(
              padding: EdgeInsets.only(left: 19.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgDangerSquareSvgrepoCom,
                    height: 23.adaptSize,
                    width: 23.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 27.h),
                    child: Text(
                      "lbl_about_us".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 42.v),
            Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgTelevisionOnprimarycontainer,
                    height: 29.adaptSize,
                    width: 29.adaptSize,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24.h,
                      top: 5.v,
                    ),
                    child: Text(
                      "lbl_log_out".tr,
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 42.v)
          ],
        ),
      ),
    );
  }
}
