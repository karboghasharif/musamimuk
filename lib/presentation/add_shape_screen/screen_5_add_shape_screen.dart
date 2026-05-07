import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_pin_code_text_field.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/screen_5_add_shape_bloc.dart';
import 'models/screen_5_add_shape_model.dart';

class Screen5AddShapeScreen extends StatelessWidget {
  const Screen5AddShapeScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen5AddShapeBloc>(
      create: (context) => Screen5AddShapeBloc(Screen5AddShapeState(
        screen5AddShapeModelObj: const Screen5AddShapeModel(),
      ))
        ..add(Screen5AddShapeInitialEvent()),
      child: const Screen5AddShapeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(vertical: 5.v),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 23.h,
                  right: 22.h,
                ),
                child: BlocSelector<Screen5AddShapeBloc, Screen5AddShapeState,
                    TextEditingController?>(
                  selector: (state) => state.searchController,
                  builder: (context, searchController) {
                    return CustomSearchView(
                      controller: searchController,
                      hintText: "lbl_search".tr,
                    );
                  },
                ),
              ),
              SizedBox(height: 25.v),
              _buildStackHomeOne(context),
              SizedBox(height: 42.v),
              _buildRowBasicOne(context),
              SizedBox(height: 18.v),
              _buildRowView(context),
              SizedBox(height: 31.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 26.h,
                  right: 17.h,
                ),
                child: _buildRowBadgesOne(
                  context,
                  badgeText: "lbl_blob".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 24.v),
              Padding(
                padding: EdgeInsets.only(left: 26.h),
                child: BlocSelector<Screen5AddShapeBloc, Screen5AddShapeState,
                    TextEditingController?>(
                  selector: (state) => state.otpController,
                  builder: (context, otpController) {
                    return CustomPinCodeTextField(
                      context: context,
                      controller: otpController,
                      onChanged: (value) {
                        otpController?.text = value;
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 26.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 26.h,
                  right: 17.h,
                ),
                child: _buildRowBadgesOne(
                  context,
                  badgeText: "lbl_badges".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 30.v),
              _buildRowCloseOne(context),
              SizedBox(height: 31.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 26.h,
                  right: 17.h,
                ),
                child: _buildRowBadgesOne(
                  context,
                  badgeText: "msg_animals_stickers".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 25.v),
              _buildRowFlamingoOne(context),
              SizedBox(height: 5.v)
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        margin: EdgeInsets.fromLTRB(28.h, 20.v, 379.h, 19.v),
      ),
    );
  }

  Widget _buildStackHomeOne(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(left: 23.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 43.v,
              width: 48.h,
              padding: EdgeInsets.symmetric(
                horizontal: 12.h,
                vertical: 9.v,
              ),
              decoration: AppDecoration.fillGray800.copyWith(
                borderRadius: BorderRadiusStyle.roundedBorder15,
              ),
              child: CustomImageView(
                imagePath: ImageConstant.imgHome,
                height: 24.adaptSize,
                width: 24.adaptSize,
                alignment: Alignment.center,
              ),
            ),
            const Spacer(
              flex: 17,
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 12.v,
                bottom: 10.v,
              ),
              child: Text(
                "lbl_basic".tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Spacer(
              flex: 20,
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 12.v,
                bottom: 10.v,
              ),
              child: Text(
                "lbl_blob".tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Spacer(
              flex: 21,
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 13.v,
                bottom: 9.v,
              ),
              child: Text(
                "lbl_badges".tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Spacer(
              flex: 20,
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 12.v,
                bottom: 10.v,
              ),
              child: Text(
                "lbl_borders".tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Spacer(
              flex: 20,
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 12.v,
                bottom: 10.v,
              ),
              child: Text(
                "lbl_islamic".tr,
                style: theme.textTheme.bodyMedium,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRowBasicOne(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 26.h,
        right: 17.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "lbl_basic".tr,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            "lbl_see_all".tr,
            style: CustomTextStyles.titleSmallPrimary_1,
          )
        ],
      ),
    );
  }

  Widget _buildRowView(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: double.maxFinite,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 90.v,
              width: 104.h,
              decoration: BoxDecoration(
                color: appTheme.blueGray100,
                borderRadius: BorderRadius.circular(
                  13.h,
                ),
              ),
            ),
            Container(
              height: 69.adaptSize,
              width: 69.adaptSize,
              margin: EdgeInsets.only(
                left: 35.h,
                top: 11.v,
                bottom: 10.v,
              ),
              decoration: BoxDecoration(
                color: appTheme.blueGray100,
                borderRadius: BorderRadius.circular(
                  34.h,
                ),
              ),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgRectangle5488,
              height: 40.v,
              width: 104.h,
              radius: BorderRadius.circular(
                9.h,
              ),
              margin: EdgeInsets.only(
                left: 25.h,
                top: 25.v,
                bottom: 25.v,
              ),
            ),
            Container(
              height: 63.adaptSize,
              width: 63.adaptSize,
              margin: EdgeInsets.only(
                left: 28.h,
                top: 14.v,
                bottom: 13.v,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  31.h,
                ),
                border: Border.all(
                  color: appTheme.blueGray100,
                  width: 3.h,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRowCloseOne(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(left: 26.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgBadgesStarSvgrepoCom,
              height: 60.adaptSize,
              width: 60.adaptSize,
              margin: EdgeInsets.only(bottom: 5.v),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgClose,
              height: 60.adaptSize,
              width: 60.adaptSize,
              margin: EdgeInsets.only(bottom: 5.v),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgSignal,
              height: 62.adaptSize,
              width: 62.adaptSize,
              margin: EdgeInsets.only(bottom: 2.v),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgNameBadgeSvgrepoCom,
              height: 64.adaptSize,
              width: 64.adaptSize,
              margin: EdgeInsets.only(bottom: 1.v),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgSettings,
              height: 64.adaptSize,
              width: 64.adaptSize,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRowFlamingoOne(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 17.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgFlamingo1,
            height: 64.adaptSize,
            width: 64.adaptSize,
            margin: EdgeInsets.only(
              top: 4.v,
              bottom: 2.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgTiger1,
            height: 64.adaptSize,
            width: 64.adaptSize,
            margin: EdgeInsets.only(
              top: 4.v,
              bottom: 2.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgGiraffe1,
            height: 62.adaptSize,
            width: 62.adaptSize,
            margin: EdgeInsets.only(
              top: 4.v,
              bottom: 2.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgElephant1,
            height: 68.adaptSize,
            width: 68.adaptSize,
            margin: EdgeInsets.only(top: 2.v),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgGiraffe1,
            height: 62.adaptSize,
            width: 62.adaptSize,
            margin: EdgeInsets.only(bottom: 8.v),
          )
        ],
      ),
    );
  }

  Widget _buildRowBadgesOne(
    BuildContext context, {
    required String badgeText,
    required String seeAllText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.v),
          child: Text(
            badgeText,
            style: theme.textTheme.titleSmall!.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(1),
            ),
          ),
        ),
        Text(
          seeAllText,
          style: CustomTextStyles.titleSmallPrimary_1.copyWith(
            color: theme.colorScheme.primary,
          ),
        )
      ],
    );
  }
}
