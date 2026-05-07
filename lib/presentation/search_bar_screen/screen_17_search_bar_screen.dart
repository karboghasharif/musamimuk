import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../data/models/media_item.dart';
import '../../widgets/custom_floating_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/design_preview_sheet.dart';
import 'bloc/screen_17_search_bar_bloc.dart';
import 'models/screen_17_search_bar_model.dart';

class Screen17SearchBarScreen extends StatelessWidget {
  const Screen17SearchBarScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen17SearchBarBloc>(
      create: (context) => Screen17SearchBarBloc(Screen17SearchBarState(
        screen17SearchBarModelObj: const Screen17SearchBarModel(),
      ))
        ..add(Screen17SearchBarInitialEvent()),
      child: const Screen17SearchBarScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 44.v),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 22.h,
                          right: 23.h,
                        ),
                        child: BlocSelector<Screen17SearchBarBloc,
                            Screen17SearchBarState, TextEditingController?>(
                          selector: (state) => state.searchController,
                          builder: (context, searchController) {
                            return CustomSearchView(
                              controller: searchController,
                              hintText: "lbl_search_designs".tr,
                              onChanged: (value) {
                                context.read<Screen17SearchBarBloc>().add(
                                      Screen17SearchBarQueryChangedEvent(value),
                                    );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16.v),
                      _buildResults(context),
                      SizedBox(height: 24.v),
                      _buildHomeSection(context),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButtonSection(context),
      ),
    );
  }

  Widget _buildHomeSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(
        horizontal: 50.h,
        vertical: 9.v,
      ),
      decoration: AppDecoration.fillBluegray90005,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 198.h,
            margin: EdgeInsets.only(
              left: 7.h,
              top: 5.v,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 1.v),
                  child: Column(
                    children: [
                      CustomIconButton(
                        height: 51.v,
                        width: 56.h,
                        padding: EdgeInsets.all(10.h),
                        onTap: () {
                          onTapBtnHomeone(context);
                        },
                        child: CustomImageView(
                          imagePath: ImageConstant.imgHome,
                        ),
                      ),
                      SizedBox(height: 10.v),
                      GestureDetector(
                        onTap: () {
                          onTapTxtHometwo(context);
                        },
                        child: Text(
                          "lbl_home".tr,
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    ],
                  ),
                ),
                Column(
                  children: [
                    CustomIconButton(
                      height: 51.v,
                      width: 56.h,
                      padding: EdgeInsets.all(13.h),
                      onTap: () {
                        onTapBtnAppsaddoneone(context);
                      },
                      child: CustomImageView(
                        imagePath: ImageConstant.imgAppsAdd1Primary,
                      ),
                    ),
                    SizedBox(height: 11.v),
                    GestureDetector(
                      onTap: () {
                        onTapTxtOnlinedesigns(context);
                      },
                      child: Text(
                        "lbl_online_designs".tr,
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 5.v),
            child: Column(
              children: [
                CustomIconButton(
                  height: 51.v,
                  width: 56.h,
                  padding: EdgeInsets.all(12.h),
                  onTap: () {
                    onTapBtnAppsaddtwoone(context);
                  },
                  child: CustomImageView(
                    imagePath: ImageConstant.imgAppsAdd2Primary,
                  ),
                ),
                SizedBox(height: 11.v),
                GestureDetector(
                  onTap: () {
                    onTapTxtMydesigns(context);
                  },
                  child: Text(
                    "lbl_my_designs".tr,
                    style: theme.textTheme.bodySmall,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: BlocBuilder<Screen17SearchBarBloc, Screen17SearchBarState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.errorMessage != null) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 24.v),
              child: Center(
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }
          if (state.results.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 24.v),
              child: Center(
                child: Text(
                  'Type to search designs',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10.v,
              crossAxisSpacing: 10.h,
              childAspectRatio: 1,
            ),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final MediaItem item = state.results[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.h),
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
                    borderRadius: BorderRadius.circular(10.h),
                    child: CustomImageView(
                      imagePath: item.fileUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
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

  onTapBtnHomeone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen1HomeScreen,
    );
  }

  onTapTxtHometwo(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen1HomeScreen,
    );
  }

  onTapBtnAppsaddoneone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen16OnlineDesignsScreen,
    );
  }

  onTapTxtOnlinedesigns(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen16OnlineDesignsScreen,
    );
  }

  onTapBtnAppsaddtwoone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen18MyDesignsScreen,
    );
  }

  onTapTxtMydesigns(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.screen18MyDesignsScreen,
    );
  }
}
