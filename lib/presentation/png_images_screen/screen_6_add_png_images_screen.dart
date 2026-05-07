import 'package:flutter/material.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/screen_6_add_png_images_bloc.dart';
import 'models/screen_6_add_png_images_model.dart';
import 'models/staggeredmosque_item_model.dart';
import 'widgets/staggeredmosque_item_widget.dart';

class Screen6AddPngImagesScreen extends StatelessWidget {
  const Screen6AddPngImagesScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen6AddPngImagesBloc>(
      create: (context) => Screen6AddPngImagesBloc(Screen6AddPngImagesState(
        screen6AddPngImagesModelObj: Screen6AddPngImagesModel(),
      ))
        ..add(Screen6AddPngImagesInitialEvent()),
      child: const Screen6AddPngImagesScreen(),
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
                child: BlocSelector<Screen6AddPngImagesBloc,
                    Screen6AddPngImagesState, TextEditingController?>(
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
              _buildRowHomeOne(context),
              SizedBox(height: 40.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 32.h,
                  right: 18.h,
                ),
                child: _buildRowPoliticsOne(
                  context,
                  politicsText: "lbl_islamic".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 16.v),
              _buildStackMuslimOne(context),
              SizedBox(height: 10.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 32.h,
                  right: 18.h,
                ),
                child: _buildRowPoliticsOne(
                  context,
                  politicsText: "lbl_politics".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 27.v),
              _buildRowCandidateOne(context),
              SizedBox(height: 23.v),
              Padding(
                padding: EdgeInsets.only(
                  left: 32.h,
                  right: 18.h,
                ),
                child: _buildRowPoliticsOne(
                  context,
                  politicsText: "lbl_sports".tr,
                  seeAllText: "lbl_see_all".tr,
                ),
              ),
              SizedBox(height: 16.v),
              _buildRowCupOneOne(context),
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

  Widget _buildRowHomeOne(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 23.h,
        right: 37.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconButton(
            height: 43.v,
            width: 48.h,
            padding: EdgeInsets.all(9.h),
            child: CustomImageView(
              imagePath: ImageConstant.imgHome,
            ),
          ),
          const Spacer(
            flex: 25,
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
          const Spacer(
            flex: 24,
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 12.v,
              bottom: 10.v,
            ),
            child: Text(
              "lbl_business".tr,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Spacer(
            flex: 26,
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 12.v,
              bottom: 10.v,
            ),
            child: Text(
              "lbl_politics".tr,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Spacer(
            flex: 23,
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 14.v,
              bottom: 8.v,
            ),
            child: Text(
              "lbl_sports".tr,
              style: theme.textTheme.bodyMedium,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStackMuslimOne(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: 248.v,
        width: 417.h,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 213.h,
                  top: 1.v,
                  right: 12.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgMuslim1,
                          height: 76.adaptSize,
                          width: 76.adaptSize,
                          margin: EdgeInsets.only(
                            top: 8.v,
                            bottom: 5.v,
                          ),
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgMuslim11,
                          height: 89.adaptSize,
                          width: 89.adaptSize,
                        )
                      ],
                    ),
                    SizedBox(height: 20.v),
                    Padding(
                      padding: EdgeInsets.only(right: 12.h),
                      child: Text(
                        "lbl_see_all".tr,
                        style: CustomTextStyles.titleSmallPrimary_1,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 15.h),
                child: Text(
                  "lbl_business".tr,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            BlocSelector<Screen6AddPngImagesBloc, Screen6AddPngImagesState,
                Screen6AddPngImagesModel?>(
              selector: (state) => state.screen6AddPngImagesModelObj,
              builder: (context, screen6AddPngImagesModelObj) {
                return StaggeredGridView.countBuilder(
                  shrinkWrap: true,
                  primary: false,
                  crossAxisCount: 4,
                  crossAxisSpacing: 27.h,
                  mainAxisSpacing: 27.h,
                  staggeredTileBuilder: (index) {
                    return const StaggeredTile.fit(2);
                  },
                  itemCount: screen6AddPngImagesModelObj
                          ?.staggeredmosqueItemList.length ??
                      0,
                  itemBuilder: (context, index) {
                    StaggeredmosqueItemModel model = screen6AddPngImagesModelObj
                            ?.staggeredmosqueItemList[index] ??
                        StaggeredmosqueItemModel();
                    return StaggeredmosqueItemWidget(
                      model,
                    );
                  },
                );
              },
            ),
            CustomImageView(
              imagePath: ImageConstant.imgPlan1,
              height: 78.adaptSize,
              width: 78.adaptSize,
              alignment: Alignment.bottomLeft,
              margin: EdgeInsets.only(
                left: 141.h,
                bottom: 13.v,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 13.v),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgDevelopment1,
                      height: 68.adaptSize,
                      width: 68.adaptSize,
                      margin: EdgeInsets.only(top: 2.v),
                    ),
                    CustomImageView(
                      imagePath: ImageConstant.imgApproved1,
                      height: 70.adaptSize,
                      width: 70.adaptSize,
                      margin: EdgeInsets.only(left: 30.h),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRowCandidateOne(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(
          left: 32.h,
          right: 5.h,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgCandidate1,
              height: 74.adaptSize,
              width: 74.adaptSize,
            ),
            const Spacer(
              flex: 33,
            ),
            CustomImageView(
              imagePath: ImageConstant.imgTank1,
              height: 76.adaptSize,
              width: 76.adaptSize,
            ),
            const Spacer(
              flex: 33,
            ),
            CustomImageView(
              imagePath: ImageConstant.imgPulpit1,
              height: 74.adaptSize,
              width: 74.adaptSize,
            ),
            const Spacer(
              flex: 33,
            ),
            CustomImageView(
              imagePath: ImageConstant.imgNewsPolitics1,
              height: 71.adaptSize,
              width: 71.adaptSize,
              margin: EdgeInsets.only(bottom: 5.v),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRowCupOneOne(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgCup1,
            height: 78.adaptSize,
            width: 78.adaptSize,
            margin: EdgeInsets.symmetric(vertical: 7.v),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgBasketballBall,
            height: 92.adaptSize,
            width: 92.adaptSize,
          ),
          CustomImageView(
            imagePath: ImageConstant.imgShuttercock1,
            height: 73.adaptSize,
            width: 73.adaptSize,
            margin: EdgeInsets.only(
              top: 12.v,
              bottom: 7.v,
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgSoccerBall1,
            height: 77.adaptSize,
            width: 77.adaptSize,
            margin: EdgeInsets.symmetric(vertical: 7.v),
          )
        ],
      ),
    );
  }

  Widget _buildRowPoliticsOne(
    BuildContext context, {
    required String politicsText,
    required String seeAllText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          politicsText,
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
