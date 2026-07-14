import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_18_my_designs_bloc.dart';
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
        appBar: _buildAppBar(context),
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space3.v,
            AppDs.space4.h,
            AppDs.space6.v,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'lbl_my_designs'.tr,
                subtitle: 'lbl_search_designs'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              BlocSelector<Screen18MyDesignsBloc, Screen18MyDesignsState,
                  TextEditingController?>(
                selector: (state) => state.searchController,
                builder: (context, searchController) {
                  return AppSearchField(
                    controller: searchController,
                    hintText: 'lbl_search_designs'.tr,
                    onChanged: (value) {
                      context.read<Screen18MyDesignsBloc>().add(
                            Screen18MyDesignsSearchChangedEvent(value),
                          );
                    },
                  );
                },
              ),
              SizedBox(height: AppDs.space6.v),
              AppSectionHeader(title: 'lbl_my_designs'.tr),
              Expanded(child: _buildPlaylist(context)),
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
        onTap: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: AppbarTitle(text: 'lbl_my_designs'.tr),
    );
  }

  Widget _buildPlaylist(BuildContext context) {
    return BlocBuilder<Screen18MyDesignsBloc, Screen18MyDesignsState>(
      builder: (context, state) {
        final items =
            state.screen18MyDesignsModelObj?.playlistItemList ?? const [];
        return AppAsyncBody(
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          isEmpty: !state.isLoading &&
              state.errorMessage == null &&
              items.isEmpty,
          emptyTitle: 'lbl_my_designs'.tr,
          emptyMessage: 'Try a different search term.',
          loading: const AppHorizontalListSkeleton(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(bottom: AppDs.space2.v),
            separatorBuilder: (_, _) => SizedBox(width: AppDs.space4.h),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return AppFadeIn(
                delay: Duration(milliseconds: 40 * index),
                child: PlaylistItemWidget(items[index]),
              );
            },
          ),
        );
      },
    );
  }
}
