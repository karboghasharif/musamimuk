import 'package:flutter/material.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_icon_button.dart';
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
        backgroundColor: AppDs.surfaceBase,
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space3.v,
            AppDs.space4.h,
            AppDs.space4.v,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'lbl_png_images'.tr,
                subtitle: 'msg_screen_6_add_png'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              BlocSelector<Screen6AddPngImagesBloc,
                  Screen6AddPngImagesState, TextEditingController?>(
                selector: (state) => state.searchController,
                builder: (context, searchController) {
                  return AppSearchField(
                    controller: searchController,
                    hintText: 'lbl_search'.tr,
                  );
                },
              ),
              SizedBox(height: AppDs.space4.v),
              _buildRowHomeOne(context),
              SizedBox(height: AppDs.space6.v),
              _buildSectionHeader(
                context,
                politicsText: 'lbl_islamic'.tr,
                seeAllText: 'lbl_see_all'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              _buildStackMuslimOne(context),
              SizedBox(height: AppDs.space4.v),
              _buildSectionHeader(
                context,
                politicsText: 'lbl_politics'.tr,
                seeAllText: 'lbl_see_all'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              _buildRowCandidateOne(context),
              SizedBox(height: AppDs.space6.v),
              _buildSectionHeader(
                context,
                politicsText: 'lbl_sports'.tr,
                seeAllText: 'lbl_see_all'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              _buildRowCupOneOne(context),
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
        margin: EdgeInsets.only(left: AppDs.space4.h),
      ),
    );
  }

  Widget _buildRowHomeOne(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CustomIconButton(
            height: 43.v,
            width: 48.h,
            padding: EdgeInsets.all(AppDs.space2.h),
            child: CustomImageView(
              imagePath: ImageConstant.imgHome,
            ),
          ),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_islamic'.tr, variant: AppTextVariant.body),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_business'.tr, variant: AppTextVariant.body),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_politics'.tr, variant: AppTextVariant.body),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_sports'.tr, variant: AppTextVariant.body),
        ],
      ),
    );
  }

  Widget _buildStackMuslimOne(BuildContext context) {
    return AppCard(
      elevated: true,
      child: SizedBox(
        height: 248.v,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 213.h,
                  top: AppDs.space1.v,
                  right: AppDs.space3.h,
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
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgMuslim11,
                          height: 89.adaptSize,
                          width: 89.adaptSize,
                        ),
                      ],
                    ),
                    SizedBox(height: AppDs.space5.v),
                    AppText(
                      'lbl_see_all'.tr,
                      variant: AppTextVariant.accent,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AppText('lbl_business'.tr, variant: AppTextVariant.title),
            ),
            BlocSelector<Screen6AddPngImagesBloc, Screen6AddPngImagesState,
                Screen6AddPngImagesModel?>(
              selector: (state) => state.screen6AddPngImagesModelObj,
              builder: (context, screen6AddPngImagesModelObj) {
                return StaggeredGridView.countBuilder(
                  shrinkWrap: true,
                  primary: false,
                  crossAxisCount: 4,
                  crossAxisSpacing: AppDs.space6.h,
                  mainAxisSpacing: AppDs.space6.h,
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
                bottom: AppDs.space3.v,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppDs.space3.v),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgDevelopment1,
                      height: 68.adaptSize,
                      width: 68.adaptSize,
                    ),
                    SizedBox(width: AppDs.space6.h),
                    CustomImageView(
                      imagePath: ImageConstant.imgApproved1,
                      height: 70.adaptSize,
                      width: 70.adaptSize,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCandidateOne(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgCandidate1,
            height: 74.adaptSize,
            width: 74.adaptSize,
          ),
          SizedBox(width: AppDs.space6.h),
          CustomImageView(
            imagePath: ImageConstant.imgTank1,
            height: 76.adaptSize,
            width: 76.adaptSize,
          ),
          SizedBox(width: AppDs.space6.h),
          CustomImageView(
            imagePath: ImageConstant.imgPulpit1,
            height: 74.adaptSize,
            width: 74.adaptSize,
          ),
          SizedBox(width: AppDs.space6.h),
          CustomImageView(
            imagePath: ImageConstant.imgNewsPolitics1,
            height: 71.adaptSize,
            width: 71.adaptSize,
          ),
        ],
      ),
    );
  }

  Widget _buildRowCupOneOne(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgCup1,
            height: 78.adaptSize,
            width: 78.adaptSize,
          ),
          SizedBox(width: AppDs.space4.h),
          CustomImageView(
            imagePath: ImageConstant.imgBasketballBall,
            height: 92.adaptSize,
            width: 92.adaptSize,
          ),
          SizedBox(width: AppDs.space4.h),
          CustomImageView(
            imagePath: ImageConstant.imgShuttercock1,
            height: 73.adaptSize,
            width: 73.adaptSize,
          ),
          SizedBox(width: AppDs.space4.h),
          CustomImageView(
            imagePath: ImageConstant.imgSoccerBall1,
            height: 77.adaptSize,
            width: 77.adaptSize,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String politicsText,
    required String seeAllText,
  }) {
    return AppSectionHeader(
      title: politicsText,
      trailing: AppText(
        seeAllText,
        variant: AppTextVariant.accent,
      ),
    );
  }
}
