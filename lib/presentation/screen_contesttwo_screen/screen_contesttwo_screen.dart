import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/repositories/contest_repository.dart';
import '../../presentation/contest/contest_gallery_screen.dart';
import '../../presentation/contest/widgets/contest_countdown_timer.dart';
import '../../presentation/contest/widgets/contest_image_viewer.dart';
import '../../presentation/contest/widgets/contest_primary_action_button.dart';
import '../../presentation/contest/widgets/contest_quick_actions.dart';
import '../../presentation/contest/widgets/contest_section_card.dart';
import '../../presentation/contest/widgets/contest_stats_grid.dart';
import '../../presentation/contest/widgets/contest_status_chip.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_contesttwo_bloc.dart';
import 'models/contest_detail_args.dart';
import 'models/screen_contesttwo_model.dart';
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

  String _formatStat(int? value) => value == null ? '0' : value.toString();

  Future<void> _onRefresh(BuildContext context) async {
    final args = ContestDetailArgs.fromRouteArguments(
      ModalRoute.of(context)?.settings.arguments,
    );
    final bloc = context.read<ScreenContesttwoBloc>();
    bloc.add(
      ScreenContesttwoRefreshEvent(
        contestId: args?.contestId ?? 0,
        contestFromList: args?.contest,
      ),
    );
    await waitForBlocLoadingComplete(
      bloc,
      isLoading: (state) => state.isLoading,
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
                return RefreshIndicator(
                  onRefresh: () => _onRefresh(context),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      AppContestDetailSkeleton(),
                    ],
                  ),
                );
              }
              if (state.errorMessage != null) {
                return RefreshIndicator(
                  onRefresh: () => _onRefresh(context),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 80.v),
                      AppErrorState(
                        message: state.errorMessage!,
                        onRetry: () => _onRefresh(context),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    AppDs.space4.h,
                    AppDs.space3.v,
                    AppDs.space4.h,
                    AppDs.space6.v,
                  ),
                  child: _buildContent(context, state),
                ),
              );
            },
        ),
      ),
    );
  }

  void _onContestAction(
    BuildContext context,
    ScreenContesttwoState state,
    String key,
  ) {
    final contestId = state.detail?.contest.id ?? 0;
    if (contestId <= 0) return;
    switch (key) {
      case 'join':
        context.read<ScreenContesttwoBloc>().add(
          ScreenContesttwoJoinEvent(contestId: contestId),
        );
        break;
      case 'submit':
        showContestEligibleDesignsSheet(
          context: context,
          contestId: contestId,
          repo: ContestRepository.instance,
          onSubmitted: (_) {
            context.read<ScreenContesttwoBloc>().add(
              ScreenContesttwoRefreshEvent(contestId: contestId),
            );
          },
        );
        break;
      case 'gallery':
        NavigatorService.pushNamed(
          AppRoutes.contestGalleryScreen,
          arguments: contestId,
        );
        break;
      case 'winners':
      case 'results':
        NavigatorService.pushNamed(
          AppRoutes.contestWinnersScreen,
          arguments: contestId,
        );
        break;
      case 'notify':
        showAppToast('msg_notify_upcoming_set'.tr);
        break;
    }
  }

  Widget _buildContent(BuildContext context, ScreenContesttwoState state) {
    final contestId = state.detail?.contest.id ?? 0;
    final name = state.contestName ?? 'lbl_contest'.tr;
    final description = state.detail?.contest.description?.trim();
    final categoryName = state.detail?.contest.category?.name;
    final dateText =
        formatContestDateRangeDisplay(state.startDate, state.endDate);
    final userMessage = state.detail?.user != null
        ? _userStatusMessage(state)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // —— Hero: image + status ——
        ContestImageBanner(
          imageUrl: state.bannerUrl,
          title: name,
          overlay: Positioned(
            top: 10.v,
            left: 10.h,
            right: 10.h,
            child: Row(
              children: [
                ContestStatusChip(status: state.status),
                if (state.detail?.user?.joined == true) ...[
                  SizedBox(width: 8.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
                    decoration: BoxDecoration(
                      color: appTheme.green500.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20.adaptSize),
                    ),
                    child: Text(
                      'lbl_joined'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (state.prizeText != null && state.prizeText!.isNotEmpty)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
                    decoration: BoxDecoration(
                      color: appTheme.yellow500.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20.adaptSize),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 14.adaptSize,
                          color: appTheme.gray900,
                        ),
                        SizedBox(width: 4.h),
                        Text(
                          state.prizeText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: appTheme.gray900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppDs.space6.v),
        // —— Primary info hierarchy ——
        AppText(name, variant: AppTextVariant.display),
        if (categoryName != null && categoryName.trim().isNotEmpty) ...[
          SizedBox(height: AppDs.space2.v),
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 16.adaptSize,
                color: AppDs.textSecondary(theme.colorScheme),
              ),
              SizedBox(width: AppDs.space2.h),
              AppText(
                categoryName.trim(),
                variant: AppTextVariant.secondary,
              ),
            ],
          ),
        ],
        if (state.detail?.countdown != null) ...[
          SizedBox(height: AppDs.space6.v),
          AppCard(
            elevated: true,
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space6.h,
              vertical: AppDs.space5.v,
            ),
            child: ContestCountdownTimer(
              countdown: state.detail!.countdown,
              hero: true,
            ),
          ),
        ],
        if (state.resultsAnnounced) ...[
          SizedBox(height: AppDs.space4.v),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.v),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.celebration_outlined,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 8.h),
                Expanded(
                  child: Text(
                    'msg_winner_announced'.tr,
                    style: AppTypography.bodyMedium(theme).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppDs.textOnDarkPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (userMessage != null && userMessage.isNotEmpty) ...[
          SizedBox(height: AppDs.space4.v),
          AppText(userMessage, variant: AppTextVariant.secondary),
        ],
        SizedBox(height: AppDs.space6.v),
        // —— Primary action ——
        ContestPrimaryActionButton(
          user: state.detail?.user,
          fallbackUser: state.detail?.contest.user,
          isLoading: state.isActionLoading,
          onAction: (key) => _onContestAction(context, state, key),
        ),
        SizedBox(height: AppDs.space4.v),
        // —— Secondary quick actions ——
        ContestQuickActions(
          actions: [
            ContestQuickAction(
              icon: Icons.dynamic_feed_outlined,
              label: 'lbl_contest_feed'.tr,
              onTap: () {
                NavigatorService.pushNamed(AppRoutes.contestFeedScreen);
              },
            ),
            ContestQuickAction(
              icon: Icons.collections_outlined,
              label: 'lbl_browse_gallery'.tr,
              primary: true,
              onTap: () {
                if (contestId <= 0) return;
                NavigatorService.pushNamed(
                  AppRoutes.contestGalleryScreen,
                  arguments: contestId,
                );
              },
            ),
            ContestQuickAction(
              icon: Icons.emoji_events_outlined,
              label: 'lbl_view_winners'.tr,
              onTap: () {
                if (contestId <= 0) return;
                NavigatorService.pushNamed(
                  AppRoutes.contestWinnersScreen,
                  arguments: contestId,
                );
              },
            ),
            ContestQuickAction(
              icon: Icons.folder_outlined,
              label: 'lbl_my_submissions'.tr,
              onTap: () {
                if (contestId <= 0) return;
                NavigatorService.pushNamed(
                  AppRoutes.contestMySubmissionsScreen,
                  arguments: contestId,
                );
              },
            ),
          ],
        ),
        SizedBox(height: AppDs.space8.v),
        // —— Supporting content ——
        ContestStatsGrid(
          title: 'lbl_contest_stats'.tr,
          items: [
            ContestStatItem(
              icon: Icons.people_outline,
              label: 'lbl_participants'.tr,
              value: _formatStat(state.participantsCount),
            ),
            ContestStatItem(
              icon: Icons.brush_outlined,
              label: 'msg_designs_submitted'.tr,
              value: _formatStat(state.submittedCount),
              highlight: true,
            ),
            ContestStatItem(
              icon: Icons.check_circle_outline,
              label: 'msg_designs_accepted'.tr,
              value: _formatStat(state.acceptedCount),
            ),
            ContestStatItem(
              icon: Icons.cancel_outlined,
              label: 'msg_designs_rejected'.tr,
              value: _formatStat(state.rejectedCount),
            ),
          ],
        ),
        if (dateText.isNotEmpty) ...[
          SizedBox(height: AppDs.space6.v),
          ContestSectionCard(
            title: 'lbl_date'.tr,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18.adaptSize,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: Text(
                    dateText,
                    style: AppTypography.bodyMedium(theme).copyWith(
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (description != null && description.isNotEmpty) ...[
          SizedBox(height: AppDs.space6.v),
          ContestSectionCard(
            title: 'lbl_about_contest'.tr,
            child: Text(
              description,
              style: AppTypography.secondary(theme).copyWith(
                height: 1.45,
              ),
            ),
          ),
        ],
        SizedBox(height: AppDs.space8.v),
        _buildLeaderboard(context, state),
      ],
    );
  }

  String? _userStatusMessage(ScreenContesttwoState state) {
    final raw = state.detail?.raw;
    if (raw != null) {
      final user = raw['user'];
      if (user is Map) {
        final msg = user['status_message']?.toString().trim();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    }
    return null;
  }

  Widget _buildLeaderboard(BuildContext context, ScreenContesttwoState state) {
    final profiles =
        state.screenContesttwoModelObj?.userprofileItemList ?? const [];
    if (profiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'lbl_top_submissions'.tr,
          variant: AppTextVariant.heading,
        ),
        SizedBox(height: AppDs.space4.v),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: profiles.length,
          separatorBuilder: (_, _) => SizedBox(height: AppDs.space4.v),
          itemBuilder: (context, index) {
            final model = profiles[index];
            return UserprofileItemWidget(
              model,
              onImageTap: model.userImage?.trim().isNotEmpty == true
                  ? () => showContestImageSheet(
                        context,
                        imageUrl: model.userImage!,
                        title: model.username,
                      )
                  : null,
            );
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowDownPrimary,
        margin: EdgeInsets.only(left: 16.h, top: 12.v, bottom: 12.v),
        onTap: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: AppbarTitle(text: 'lbl_contest_details'.tr),
    );
  }
}
