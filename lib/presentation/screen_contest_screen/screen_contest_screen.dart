import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../data/models/contest_item.dart';
import '../../data/repositories/contest_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/advertisement_banner.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_contest_bloc.dart';
import 'models/certificatedesign_item_model.dart';
import 'models/screen_contest_model.dart';
import '../../presentation/contest/widgets/contest_category_chips.dart';
import '../../presentation/contest/widgets/contest_list_card.dart';
import '../screen_contesttwo_screen/models/contest_detail_args.dart';

class ScreenContestScreen extends StatelessWidget {
  const ScreenContestScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<ScreenContestBloc>(
      create: (context) => ScreenContestBloc(
        ScreenContestState(
          screenContestModelObj: ScreenContestModel(),
        ),
        repository: ContestRepository.instance,
      )..add(ScreenContestInitialEvent()),
      child: const ScreenContestScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: BlocBuilder<ScreenContestBloc, ScreenContestState>(
          builder: (context, state) {
            Future<void> onRefresh() async {
              final bloc = context.read<ScreenContestBloc>();
              bloc.add(ScreenContestLoadEvent(forceRefresh: true));
              await waitForBlocLoadingComplete(
                bloc,
                isLoading: (s) => s.isLoading,
              );
            }

            final items =
                state.screenContestModelObj?.contestItemList ?? const [];

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppDs.space4.h,
                      AppDs.space3.v,
                      AppDs.space4.h,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPageHeader(
                            title: 'lbl_contest'.tr,
                            subtitle: 'msg_take_part_in_the'.tr,
                          ),
                          SizedBox(height: AppDs.space4.v),
                          AdvertisementBanner(
                            placement: 'contest_banner',
                            limit: 3,
                            height: 80.v,
                          ),
                          SizedBox(height: AppDs.space4.v),
                          _ContestFeedEntry(),
                          SizedBox(height: AppDs.space4.v),
                          AppSearchField(
                            hintText: 'lbl_search_contests'.tr,
                            onChanged: (v) =>
                                context.read<ScreenContestBloc>().add(
                                  ScreenContestFilterEvent(search: v),
                                ),
                          ),
                          SizedBox(height: AppDs.space3.v),
                          _StatusFilters(state: state),
                          SizedBox(height: AppDs.space2.v),
                          ContestCategoryChips(
                            categories: state.categories,
                            selectedCategoryId: state.selectedCategoryId,
                            onSelected: (id) =>
                                context.read<ScreenContestBloc>().add(
                                  ScreenContestFilterEvent(
                                    categoryId: id,
                                    updateCategory: true,
                                  ),
                                ),
                          ),
                          SizedBox(height: AppDs.space4.v),
                        ],
                      ),
                    ),
                  ),
                  _buildContestListSliver(context, state: state, items: items),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        margin: EdgeInsets.only(left: AppDs.space4.h, top: AppDs.space3.v, bottom: AppDs.space3.v),
        onTap: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: AppbarTitle(text: 'lbl_contest'.tr),
    );
  }

  Widget _buildContestListSliver(
    BuildContext context, {
    required ScreenContestState state,
    required List<CertificatedesignItemModel> items,
  }) {
    if (state.isLoading && items.isEmpty) {
      return const SliverToBoxAdapter(child: AppContestListSkeleton());
    }
    if (state.errorMessage != null && items.isEmpty) {
      return SliverFillRemaining(
        child: AppErrorState(message: state.errorMessage!),
      );
    }
    if (items.isEmpty) {
      return SliverFillRemaining(
        child: AppEmptyState(
          title: 'msg_no_contests'.tr,
          icon: Icons.emoji_events_outlined,
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppDs.space4.h, 0, AppDs.space4.h, AppDs.space6.v),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= items.length) {
              if (state.hasMore && !state.isLoadingMore) {
                context.read<ScreenContestBloc>().add(
                  ScreenContestLoadEvent(loadMore: true),
                );
              }
              return Padding(
                padding: EdgeInsets.all(AppDs.space4.h),
                child: state.isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink(),
              );
            }
            final model = items[index];
            final contestId = int.tryParse(model.id ?? '');
            final id = contestId ?? 0;
            return Padding(
              padding: EdgeInsets.only(bottom: AppDs.space4.v),
              child: ContestListCard(
                model: model,
                animateIn: true,
                onOpenDetail: id > 0
                    ? () => _openContestDetail(context, model, id)
                    : null,
                onQuickAction: id > 0
                    ? () => _handleContestCardAction(context, model, id)
                    : null,
              ),
            );
          },
          childCount: items.length + 1,
        ),
      ),
    );
  }

  static String _statusFilterLabel(String status) {
    return switch (status) {
      'all' => 'lbl_all'.tr,
      'active' => 'lbl_status_active'.tr,
      'upcoming' => 'lbl_status_upcoming'.tr,
      'ended' => 'lbl_status_ended'.tr,
      'completed' => 'lbl_status_completed'.tr,
      _ => status,
    };
  }

  void _handleContestCardAction(
    BuildContext context,
    CertificatedesignItemModel model,
    int contestId,
  ) {
    final action = model.primaryAction ?? '';
    switch (action) {
      case 'gallery':
        NavigatorService.pushNamed(
          AppRoutes.contestGalleryScreen,
          arguments: contestId,
        );
        return;
      case 'winners':
      case 'results':
        NavigatorService.pushNamed(
          AppRoutes.contestWinnersScreen,
          arguments: contestId,
        );
        return;
      case 'submit':
        _openContestDetail(context, model, contestId);
        return;
      default:
        _openContestDetail(context, model, contestId);
    }
  }

  void _openContestDetail(
    BuildContext context,
    CertificatedesignItemModel model,
    int contestId,
  ) {
    ContestItem? contest;
    if (model.contestJson != null) {
      try {
        contest = ContestItem.fromJson(model.contestJson!);
      } catch (_) {}
    }
    NavigatorService.pushNamed(
      AppRoutes.screenContesttwoScreen,
      arguments: ContestDetailArgs(
        contestId: contestId,
        contest: contest,
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.state});
  final ScreenContestState state;

  static const _statuses = [
    'all',
    'active',
    'upcoming',
    'ended',
    'completed',
  ];

  @override
  Widget build(BuildContext context) {
    final labels = _statuses
        .map((s) => ScreenContestScreen._statusFilterLabel(s))
        .toList();
    final selected = _statuses.indexOf(state.selectedStatus);
    return AppFilterChipRow(
      labels: labels,
      selectedIndex: selected < 0 ? 0 : selected,
      onSelected: (index) => context.read<ScreenContestBloc>().add(
        ScreenContestFilterEvent(
          status: _statuses[index],
          updateStatus: true,
        ),
      ),
    );
  }
}

class _ContestFeedEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDs.surfaceElevated,
      borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
      child: InkWell(
        onTap: () => NavigatorService.pushNamed(AppRoutes.contestFeedScreen),
        borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4.h,
            vertical: AppDs.space3.v,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dynamic_feed_outlined,
                color: theme.colorScheme.primary,
                size: 28.adaptSize,
              ),
              SizedBox(width: AppDs.space3.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lbl_contest_feed'.tr,
                      style: AppTypography.cardTitle(theme).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppDs.textOnDarkPrimary,
                      ),
                    ),
                    SizedBox(height: 2.v),
                    Text(
                      'msg_contest_feed_subtitle'.tr,
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppDs.textOnDarkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
