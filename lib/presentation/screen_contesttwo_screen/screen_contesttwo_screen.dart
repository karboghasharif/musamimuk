import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../data/repositories/contest_repository.dart';
import 'bloc/screen_contesttwo_bloc.dart';
import 'models/contest_detail_args.dart';
import 'models/screen_contesttwo_model.dart';
import 'models/userprofile_item_model.dart';
import 'widgets/userprofile_item_widget.dart';

class ScreenContesttwoScreen extends StatelessWidget {
  const ScreenContesttwoScreen({super.key});
  static Widget builder(BuildContext context) {
    final args = ContestDetailArgs.fromRouteArguments(
      ModalRoute.of(context)?.settings.arguments,
    );
    final contestId = args?.contestId ?? 0;
    final contestFromList = args?.contest;
    return BlocProvider<ScreenContesttwoBloc>(
      create: (context) => ScreenContesttwoBloc(
        ScreenContesttwoState(
          screenContesttwoModelObj: ScreenContesttwoModel(),
        ),
        repository: ContestRepository.instance,
      )..add(ScreenContesttwoInitialEvent(
          contestId: contestId,
          contestFromList: contestFromList,
        )),
      child: const ScreenContesttwoScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: BlocBuilder<ScreenContesttwoBloc, ScreenContesttwoState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.h),
                  child: Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return SizedBox(
              width: SizeUtils.width,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: 13.v),
                child: Container(
                  margin: EdgeInsets.only(bottom: 5.v),
                  padding: EdgeInsets.symmetric(horizontal: 12.h),
                  child: Column(
                    children: [
                      if (isContestEndOverdue(state.endDate)) ...[
                        CustomElevatedButton(
                          height: 38.v,
                          width: 177.h,
                          text: "msg_winner_announced".tr,
                          buttonStyle: CustomButtonStyles.fillPrimaryTL19,
                          buttonTextStyle: theme.textTheme.labelLarge!,
                        ),
                        SizedBox(height: 11.v),
                      ],
                      CustomImageView(
                        imagePath: state.bannerUrl ?? ImageConstant.imgRectangle5591,
                        height: 255.v,
                        width: 399.h,
                        radius: BorderRadius.circular(12.h),
                      ),
                      SizedBox(height: 21.v),
                      Text(
                        state.contestName ?? "lbl_contest".tr,
                        style: CustomTextStyles.titleMediumPoppins16,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 18.v),
                      _buildColumnSpacer(context, state),
                      SizedBox(height: 25.v),
                      _buildUserProfile(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Section Widget  PreferredSizeWidget
  _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowDownPrimary,
        margin: EdgeInsets.only(
          left: 25.h,
          top: 12.v,
          bottom: 12.v,
        ),
        onTap: () {
          onTapArrowdownone(context);
        },
      ),
      centerTitle: true,
      title: AppbarTitle(
        text: "lbl_contest".tr,
      ),
    );
  }

  /// Section Widget
  Widget _buildColumnSpacer(BuildContext context, ScreenContesttwoState state) {
    final accepted = state.acceptedCount ?? 0;
    final dateText =
        formatContestDateRangeDisplay(state.startDate, state.endDate);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 25.h,
        vertical: 13.v,
      ),
      decoration: AppDecoration.fillGray80001.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 15.h,
              right: 10.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 29.h),
                      child: Text(
                        accepted.toString(),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    SizedBox(height: 1.v),
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        "msg_designs_accepted".tr,
                        style: CustomTextStyles.bodySmallOnPrimaryContainer,
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(left: 26.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 27.h),
                        child: Text(
                          "-",
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      SizedBox(height: 1.v),
                      Opacity(
                        opacity: 0.7,
                        child: Text(
                          "msg_designs_rejected".tr,
                          style: CustomTextStyles.bodySmallOnPrimaryContainer,
                        ),
                      )
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      accepted.toString(),
                      style: theme.textTheme.titleLarge,
                    ),
                    SizedBox(height: 1.v),
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        "msg_designs_submitted".tr,
                        style: CustomTextStyles.bodySmallOnPrimaryContainer,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          SizedBox(height: 17.v),
          Opacity(
            opacity: 0.1,
            child: Divider(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.39),
            ),
          ),
          SizedBox(height: 12.v),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1.v, bottom: 1.v),
                child: Text(
                  "lbl_date".tr,
                  style: theme.textTheme.labelMedium,
                ),
              ),
              SizedBox(width: 7.h),
              Expanded(
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    dateText.isEmpty ? '-' : dateText,
                    style: CustomTextStyles.bodySmallOnPrimaryContainerLight,
                    textAlign: TextAlign.start,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildUserProfile(BuildContext context) {
    return BlocSelector<ScreenContesttwoBloc, ScreenContesttwoState,
        ScreenContesttwoModel?>(
      selector: (state) => state.screenContesttwoModelObj,
      builder: (context, screenContesttwoModelObj) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          separatorBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 13.0.v),
              child: SizedBox(
                width: 401.h,
                child: Divider(
                  height: 1.v,
                  thickness: 1.v,
                  color: appTheme.blueGray70001,
                ),
              ),
            );
          },
          itemCount: screenContesttwoModelObj?.userprofileItemList.length ?? 0,
          itemBuilder: (context, index) {
            UserprofileItemModel model =
                screenContesttwoModelObj?.userprofileItemList[index] ??
                    UserprofileItemModel();
            return UserprofileItemWidget(
              model,
            );
          },
        );
      },
    );
  }

  /// Navigates to the screen1HomeScreen when the action is triggered.
  onTapArrowdownone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen1HomeScreen,
    );
  }
}
