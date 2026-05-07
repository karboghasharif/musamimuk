import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_floating_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/screen_18_my_designs_bloc.dart';
import 'models/playlist_item_model.dart';
import 'models/screen_18_my_designs_model.dart';
import 'widgets/playlist_item_widget.dart';

class Screen18MyDesignsScreen extends StatelessWidget {
  const Screen18MyDesignsScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen18MyDesignsBloc>(
      create: (context) => Screen18MyDesignsBloc(
        Screen18MyDesignsState(
          screen18MyDesignsModelObj: Screen18MyDesignsModel(),
        ),
      )..add(Screen18MyDesignsInitialEvent()),
      child: const Screen18MyDesignsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.h),
                        child:
                            BlocSelector<
                              Screen18MyDesignsBloc,
                              Screen18MyDesignsState,
                              TextEditingController?
                            >(
                              selector: (state) => state.searchController,
                              builder: (context, searchController) {
                                return CustomSearchView(
                                  controller: searchController,
                                  hintText: "lbl_search_designs".tr,
                                  onChanged: (value) {
                                    context.read<Screen18MyDesignsBloc>().add(
                                      Screen18MyDesignsSearchChangedEvent(
                                        value,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                      ),
                      SizedBox(height: 25.v),
                      _buildPlaylist(context),
                      // SizedBox(height: 538.v),
                      // _buildRecentOrders(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        margin: EdgeInsets.fromLTRB(30.h, 20.v, 377.h, 19.v),
      ),
    );
  }

  Widget _buildPlaylist(BuildContext context) {
    return SizedBox(
      height: 149.v,
      child: BlocBuilder<Screen18MyDesignsBloc, Screen18MyDesignsState>(
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
          final items =
              state.screen18MyDesignsModelObj?.playlistItemList ?? const [];
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 25.h),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => SizedBox(width: 16.h),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final PlaylistItemModel model = items[index];
              return PlaylistItemWidget(model);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 49.h, vertical: 14.v),
      decoration: AppDecoration.fillBluegray90005,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 199.h,
            margin: EdgeInsets.only(left: 8.h, bottom: 5.v),
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
                        child: CustomImageView(
                          imagePath: ImageConstant.imgHome,
                        ),
                      ),
                      SizedBox(height: 10.v),
                      Text("lbl_home".tr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  children: [
                    CustomIconButton(
                      height: 51.v,
                      width: 56.h,
                      padding: EdgeInsets.all(13.h),
                      child: CustomImageView(
                        imagePath: ImageConstant.imgAppsAdd1Primary,
                      ),
                    ),
                    SizedBox(height: 11.v),
                    Text(
                      "lbl_online_designs".tr,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 5.v),
            child: Column(
              children: [
                CustomIconButton(
                  height: 51.v,
                  width: 56.h,
                  padding: EdgeInsets.all(12.h),
                  decoration: IconButtonStyleHelper.fillPrimary,
                  child: CustomImageView(
                    imagePath: ImageConstant.imgAppsAdd2BlueGray90004,
                  ),
                ),
                SizedBox(height: 11.v),
                Text("lbl_my_designs".tr, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
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
}
