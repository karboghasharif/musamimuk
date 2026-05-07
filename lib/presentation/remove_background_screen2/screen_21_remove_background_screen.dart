import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/screen_21_remove_background_bloc.dart';
import 'models/screen_21_remove_background_model.dart';

class Screen21RemoveBackgroundScreen extends StatelessWidget {
  const Screen21RemoveBackgroundScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen21RemoveBackgroundBloc>(
      create: (context) =>
          Screen21RemoveBackgroundBloc(Screen21RemoveBackgroundState(
        screen21RemoveBackgroundModelObj: const Screen21RemoveBackgroundModel(),
      ))
            ..add(Screen21RemoveBackgroundInitialEvent()),
      child: const Screen21RemoveBackgroundScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Screen21RemoveBackgroundBloc,
        Screen21RemoveBackgroundState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            appBar: _buildAppBar(context),
            body: Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(
                horizontal: 28.h,
                vertical: 24.v,
              ),
              child: Column(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgGalleryRemoveSvgrepoCom,
                    height: 72.adaptSize,
                    width: 72.adaptSize,
                  ),
                  SizedBox(height: 41.v),
                  SizedBox(
                    width: 178.h,
                    child: Text(
                      "msg_remove_background2".tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium!.copyWith(
                        height: 1.20,
                      ),
                    ),
                  ),
                  Text(
                    "msg_100_automatically".tr,
                    style: CustomTextStyles.bodyMedium15,
                  ),
                  SizedBox(height: 44.v),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 52.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "msg_remove_background".tr,
                          style: CustomTextStyles.titleSmallPrimary,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 39.h),
                          child: Text(
                            "lbl_original".tr,
                            style: CustomTextStyles.bodyMedium15,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 5.v),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 181.h,
                      child: Divider(
                        color: theme.colorScheme.primary,
                        indent: 82.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 29.v),
                  CustomImageView(
                    imagePath: ImageConstant.imgRectangle5484,
                    height: 282.v,
                    width: 372.h,
                    radius: BorderRadius.circular(
                      7.h,
                    ),
                  ),
                  SizedBox(height: 29.v),
                  CustomElevatedButton(
                    text: "lbl_download".tr,
                    onPressed: () {
                      onTapDownload(context);
                    },
                  ),
                  SizedBox(height: 5.v)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        margin: EdgeInsets.fromLTRB(29.h, 20.v, 378.h, 19.v),
      ),
    );
  }

  onTapDownload(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen19RemoveBackgroundScreen,
    );
  }
}
