import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
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
        backgroundColor: AppDs.surfaceBase,
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: Padding(
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
                title: 'lbl_logos'.tr,
                subtitle: 'msg_screen_6_add_logos'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              BlocSelector<Screen6AddLogosBloc, Screen6AddLogosState,
                  TextEditingController?>(
                selector: (state) => state.searchController,
                builder: (context, searchController) {
                  return AppSearchField(
                    controller: searchController,
                    hintText: 'lbl_search'.tr,
                  );
                },
              ),
              SizedBox(height: AppDs.space4.v),
              _buildHomeRow(context),
              SizedBox(height: AppDs.space6.v),
              _buildSectionHeader(
                context,
                title: 'lbl_new'.tr,
                seeAllText: 'lbl_see_all'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              _buildSectionHeader(
                context,
                title: 'lbl_islamic'.tr,
                seeAllText: 'lbl_see_all'.tr,
              ),
              SizedBox(height: AppDs.space3.v),
              _buildCategorySectionHeaders(context),
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

  Widget _buildHomeRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            height: 43.v,
            width: 48.h,
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space3.h,
              vertical: AppDs.space2.v,
            ),
            decoration: AppDecoration.fillGray800.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder15,
            ),
            child: CustomImageView(
              imagePath: ImageConstant.imgHome,
              height: AppDs.iconMd.adaptSize,
              width: AppDs.iconMd.adaptSize,
              alignment: Alignment.center,
            ),
          ),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_new'.tr, variant: AppTextVariant.body),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_islamic'.tr, variant: AppTextVariant.body),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_news'.tr, variant: AppTextVariant.body),
          SizedBox(width: AppDs.space4.h),
          AppText('lbl_gaming'.tr, variant: AppTextVariant.body),
        ],
      ),
    );
  }

  Widget _buildCategorySectionHeaders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context,
          title: 'lbl_news'.tr,
          seeAllText: 'lbl_see_all'.tr,
        ),
        SizedBox(height: AppDs.space6.v),
        _buildSectionHeader(
          context,
          title: 'lbl_gaming'.tr,
          seeAllText: 'lbl_see_all'.tr,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String seeAllText,
  }) {
    return AppSectionHeader(
      title: title,
      trailing: AppText(
        seeAllText,
        variant: AppTextVariant.accent,
      ),
    );
  }
}
