import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/screen_6_add_logos_bloc.dart';
import 'models/screen_6_add_logos_model.dart';

class Screen6AddLogosScreen extends StatelessWidget {
  const Screen6AddLogosScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen6AddLogosBloc>(
      create: (context) => Screen6AddLogosBloc(Screen6AddLogosState(
        screen6AddLogosModelObj: const Screen6AddLogosModel(),
      ))
        ..add(Screen6AddLogosInitialEvent()),
      child: const Screen6AddLogosScreen(),
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
                child: BlocSelector<Screen6AddLogosBloc, Screen6AddLogosState,
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
              _buildHomeRow(context),
              SizedBox(height: 40.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 32.h,
                  right: 18.h,
                ),
                child: _buildIslamicRow(
                  context,
                  islamicText: "lbl_new".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 4.v),
              _buildImageRow(context),
              SizedBox(height: 11.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 32.h,
                  right: 18.h,
                ),
                child: _buildIslamicRow(
                  context,
                  islamicText: "lbl_islamic".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 3.v),
              _buildRowOne(context),
              SizedBox(height: 5.v),
              _buildSeeAllStack(context)
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

  Widget _buildHomeRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 23.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Padding(
            padding: EdgeInsets.only(
              top: 12.v,
              bottom: 10.v,
            ),
            child: Text(
              "lbl_new".tr,
              style: theme.textTheme.bodyMedium,
            ),
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
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 12.v,
              bottom: 10.v,
            ),
            child: Text(
              "lbl_news".tr,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 12.v,
              bottom: 9.v,
            ),
            child: Text(
              "lbl_gaming".tr,
              style: theme.textTheme.bodyMedium,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImageRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 9.h,
        right: 12.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview,
            height: 103.adaptSize,
            width: 103.adaptSize,
            margin: EdgeInsets.only(top: 8.v),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview80x82,
            height: 80.v,
            width: 82.h,
            margin: EdgeInsets.only(
              left: 4.h,
              top: 19.v,
              bottom: 12.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview83x100,
            height: 83.v,
            width: 100.h,
            margin: EdgeInsets.only(
              left: 4.h,
              top: 17.v,
              bottom: 11.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview110x110,
            height: 110.adaptSize,
            width: 110.adaptSize,
            margin: EdgeInsets.only(left: 4.h),
          )
        ],
      ),
    );
  }

  Widget _buildRowOne(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 23.h,
        right: 8.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview81x62,
            height: 81.v,
            width: 62.h,
            margin: EdgeInsets.symmetric(vertical: 20.v),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview73x79,
            height: 73.v,
            width: 79.h,
            margin: EdgeInsets.only(
              left: 29.h,
              top: 28.v,
              bottom: 20.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview88x94,
            height: 88.v,
            width: 94.h,
            margin: EdgeInsets.only(
              left: 17.h,
              top: 20.v,
              bottom: 12.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview121x113,
            height: 121.v,
            width: 113.h,
            margin: EdgeInsets.only(left: 3.h),
          )
        ],
      ),
    );
  }

  Widget _buildSeeAllStack(BuildContext context) {
    return SizedBox(
      height: 285.v,
      width: 418.h,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                top: 2.v,
                right: 18.h,
              ),
              child: Text(
                "lbl_see_all".tr,
                style: CustomTextStyles.titleSmallPrimary_1,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: 18.h,
                bottom: 113.v,
              ),
              child: Text(
                "lbl_see_all".tr,
                style: CustomTextStyles.titleSmallPrimary_1,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: 22.h,
                top: 2.v,
              ),
              child: Text(
                "lbl_news".tr,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: 22.h,
                bottom: 111.v,
              ),
              child: Text(
                "lbl_gaming".tr,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview93x115,
            height: 93.v,
            width: 115.h,
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(
              left: 13.h,
              top: 41.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview144x141,
            height: 144.v,
            width: 141.h,
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(
              left: 102.h,
              top: 16.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgImageRemovebgPreview67x135,
            height: 67.v,
            width: 135.h,
            alignment: Alignment.topRight,
            margin: EdgeInsets.only(
              top: 51.v,
              right: 65.h,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgImageRemovebgPreview104x104,
                  height: 104.adaptSize,
                  width: 104.adaptSize,
                  margin: EdgeInsets.only(top: 181.v),
                ),
                CustomImageView(
                  imagePath: ImageConstant.imgImageRemovebgPreview85x91,
                  height: 85.v,
                  width: 91.h,
                  margin: EdgeInsets.only(
                    top: 188.v,
                    bottom: 12.v,
                  ),
                ),
                CustomImageView(
                  imagePath: ImageConstant.imgPngimg1,
                  height: 87.v,
                  width: 72.h,
                  margin: EdgeInsets.only(
                    left: 20.h,
                    top: 187.v,
                    bottom: 11.v,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgImageRemovebgPreview181x69,
                        height: 181.v,
                        width: 69.h,
                        alignment: Alignment.centerRight,
                      ),
                      CustomImageView(
                        imagePath: ImageConstant.imgImageRemovebgPreview106x106,
                        height: 106.adaptSize,
                        width: 106.adaptSize,
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIslamicRow(
    BuildContext context, {
    required String islamicText,
    required String seeAllText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          islamicText,
          style: theme.textTheme.titleSmall!.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(1),
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
