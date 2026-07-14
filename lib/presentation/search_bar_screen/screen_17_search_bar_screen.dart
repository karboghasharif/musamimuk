import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../data/models/media_item.dart';
import '../../presentation/screen_contesttwo_screen/models/contest_detail_args.dart';
import '../../widgets/custom_floating_button.dart';
import '../../widgets/design_preview_sheet.dart';
import 'bloc/screen_17_search_bar_bloc.dart';
import 'models/screen_17_search_bar_model.dart';

class Screen17SearchBarScreen extends StatelessWidget {
  const Screen17SearchBarScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen17SearchBarBloc>(
      create: (context) => Screen17SearchBarBloc(
        Screen17SearchBarState(
          screen17SearchBarModelObj: const Screen17SearchBarModel(),
        ),
      )..add(Screen17SearchBarInitialEvent()),
      child: const Screen17SearchBarScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space6.v,
            AppDs.space4.h,
            AppDs.space2.v,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'lbl_search_designs'.tr,
                subtitle: 'msg_search_online_t'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              BlocSelector<Screen17SearchBarBloc, Screen17SearchBarState,
                  TextEditingController?>(
                selector: (state) => state.searchController,
                builder: (context, searchController) {
                  return AppSearchField(
                    controller: searchController,
                    hintText: 'lbl_search_designs'.tr,
                    onChanged: (value) {
                      context.read<Screen17SearchBarBloc>().add(
                            Screen17SearchBarQueryChangedEvent(value),
                          );
                    },
                  );
                },
              ),
              SizedBox(height: AppDs.space4.v),
              Expanded(child: _buildResults(context)),
              SizedBox(height: AppDs.space2.v),
              _buildHomeSection(context),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButtonSection(context),
      ),
    );
  }

  Widget _buildHomeSection(BuildContext context) {
    final isGuest = PrefUtils().isGuestAccount();
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space4.h,
        vertical: AppDs.space3.v,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          AppQuickActionTile(
            imagePath: ImageConstant.imgHome,
            label: 'lbl_home'.tr,
            onTap: () => onTapBtnHomeone(context),
          ),
          AppQuickActionTile(
            imagePath: ImageConstant.imgAppsAdd1Primary,
            label: 'lbl_online_designs'.tr,
            onTap: () => onTapBtnAppsaddoneone(context),
          ),
          isGuest
              ? AppQuickActionTile(
                  icon: Icons.login,
                  label: 'lbl_sign_in'.tr,
                  highlighted: true,
                  onTap: () => NavigatorService.pushNamed(
                    AppRoutes.screen0LoginScreen,
                  ),
                )
              : AppQuickActionTile(
                  imagePath: ImageConstant.imgAppsAdd2Primary,
                  label: 'lbl_my_designs'.tr,
                  highlighted: true,
                  onTap: () => onTapBtnAppsaddtwoone(context),
                ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return BlocBuilder<Screen17SearchBarBloc, Screen17SearchBarState>(
      builder: (context, state) {
        final hasResults =
            state.results.isNotEmpty || state.contestResults.isNotEmpty;
        return AppAsyncBody(
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          isEmpty:
              !state.isLoading && state.errorMessage == null && !hasResults,
          emptyTitle: 'lbl_search_designs'.tr,
          emptyMessage: 'Type to search designs',
          loading: const AppSearchGridSkeleton(),
          child: ListView(
            padding: EdgeInsets.only(top: AppDs.space2.v),
            children: [
              if (state.contestResults.isNotEmpty) ...[
                AppSectionHeader(title: 'lbl_contest'.tr),
                SizedBox(height: AppDs.space2.v),
                ...state.contestResults.map(
                  (contest) => Padding(
                    padding: EdgeInsets.only(bottom: AppDs.space2.v),
                    child: AppCard(
                      onTap: () => NavigatorService.pushNamed(
                        AppRoutes.screenContesttwoScreen,
                        arguments: ContestDetailArgs(
                          contestId: contest.id,
                          contest: contest,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: AppDs.space3.h),
                          Expanded(
                            child: Text(
                              contest.name,
                              style: AppTypography.title(theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space4.v),
              ],
              if (state.results.isNotEmpty) ...[
                AppSectionHeader(title: 'lbl_online_designs'.tr),
                SizedBox(height: AppDs.space2.v),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppDs.space2.v,
                    crossAxisSpacing: AppDs.space2.h,
                    childAspectRatio: 1,
                  ),
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final MediaItem item = state.results[index];
                    return AppFadeIn(
                      delay: Duration(milliseconds: 25 * index),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppDs.radiusMd.adaptSize),
                          onTap: () {
                            showDesignPreviewSheet(
                              context,
                              imageRef: item.fileUrl,
                              designId: item.id,
                              title: item.name,
                              subtitle: 'ID: ${item.id}',
                            );
                          },
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppDs.radiusMd.adaptSize),
                            child: CustomImageView(
                              imagePath: item.fileUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButtonSection(BuildContext context) {
    return CustomFloatingButton(
      height: 59,
      width: 59,
      backgroundColor: theme.colorScheme.primary,
      child: CustomImageView(
        imagePath: ImageConstant.imgPlusSvgrepoComBlueGray90005,
        height: 29.5.v,
        width: 29.5.h,
      ),
    );
  }

  void onTapBtnHomeone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen1HomeScreen);
  }

  void onTapBtnAppsaddoneone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen16OnlineDesignsScreen);
  }

  void onTapBtnAppsaddtwoone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen18MyDesignsScreen);
  }
}
