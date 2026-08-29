import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
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
    final primary = theme.colorScheme.primary;

    return BlocListener<Screen18MyDesignsBloc, Screen18MyDesignsState>(
      listenWhen: (prev, next) =>
          next.deleteFeedback != null &&
          next.deleteFeedback != prev.deleteFeedback,
      listener: (context, state) {
        final msg = state.deleteFeedback;
        if (msg == null || msg.isEmpty) return;
        final isSuccess = msg == 'msg_design_deleted'.tr;
        showAppToast(
          msg,
          type: isSuccess
              ? ToastificationType.success
              : ToastificationType.error,
        );
      },
      child: SafeArea(
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
                  subtitle: 'msg_my_designs_visibility_hint'.tr,
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
                SizedBox(height: AppDs.space4.v),
                BlocBuilder<Screen18MyDesignsBloc, Screen18MyDesignsState>(
                  buildWhen: (prev, next) =>
                      prev.visibilityTab != next.visibilityTab,
                  builder: (context, state) {
                    return SegmentedButton<MyDesignsVisibilityTab>(
                      segments: [
                        ButtonSegment(
                          value: MyDesignsVisibilityTab.public,
                          label: Text('lbl_public'.tr),
                          icon: const Icon(Icons.public_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: MyDesignsVisibilityTab.private,
                          label: Text('lbl_private'.tr),
                          icon: const Icon(Icons.lock_outline, size: 18),
                        ),
                        ButtonSegment(
                          value: MyDesignsVisibilityTab.local,
                          label: Text('lbl_local_designs'.tr),
                          icon: const Icon(Icons.phone_android_outlined, size: 18),
                        ),
                      ],
                      selected: {state.visibilityTab},
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        context.read<Screen18MyDesignsBloc>().add(
                              Screen18MyDesignsVisibilityTabChangedEvent(
                                selection.first,
                              ),
                            );
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return primary.withValues(alpha: 0.22);
                          }
                          return AppDs.surfaceElevated;
                        }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return primary;
                          }
                          return AppDs.textOnDarkSecondary;
                        }),
                        side: WidgetStatePropertyAll(
                          BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: AppDs.space4.v),
                BlocBuilder<Screen18MyDesignsBloc, Screen18MyDesignsState>(
                  buildWhen: (prev, next) =>
                      prev.visibilityTab != next.visibilityTab,
                  builder: (context, state) {
                    final title = switch (state.visibilityTab) {
                      MyDesignsVisibilityTab.private =>
                        'lbl_private_designs'.tr,
                      MyDesignsVisibilityTab.local => 'lbl_local_designs'.tr,
                      MyDesignsVisibilityTab.public => 'lbl_public_designs'.tr,
                    };
                    return AppSectionHeader(title: title);
                  },
                ),
                Expanded(child: _buildPlaylist(context)),
              ],
            ),
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
        final emptyMessage = switch (state.visibilityTab) {
          MyDesignsVisibilityTab.private => 'msg_no_private_designs'.tr,
          MyDesignsVisibilityTab.local => 'msg_no_local_designs'.tr,
          MyDesignsVisibilityTab.public => 'msg_no_public_designs'.tr,
        };
        return AppAsyncBody(
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          isEmpty: !state.isLoading &&
              state.errorMessage == null &&
              items.isEmpty,
          emptyTitle: 'lbl_my_designs'.tr,
          emptyMessage: emptyMessage,
          loading: const AppHorizontalListSkeleton(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(bottom: AppDs.space2.v),
            separatorBuilder: (_, _) => SizedBox(width: AppDs.space4.h),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final id = int.tryParse((item.id ?? '').trim());
              return AppFadeIn(
                delay: Duration(milliseconds: 40 * index),
                child: PlaylistItemWidget(
                  item,
                  isDeleting: id != null && state.deletingDesignId == id,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
