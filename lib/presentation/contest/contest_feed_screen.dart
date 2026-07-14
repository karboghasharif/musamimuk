import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../screen_contesttwo_screen/models/contest_detail_args.dart';
import 'bloc/contest_feed_bloc.dart';
import 'widgets/contest_feed_card.dart';

class ContestFeedScreen extends StatefulWidget {
  const ContestFeedScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<ContestFeedBloc>(
      create: (_) => ContestFeedBloc(const ContestFeedState())
        ..add(const ContestFeedInitialEvent()),
      child: const ContestFeedScreen(),
    );
  }

  @override
  State<ContestFeedScreen> createState() => _ContestFeedScreenState();
}

class _ContestFeedScreenState extends State<ContestFeedScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final bloc = context.read<ContestFeedBloc>();
    final state = bloc.state;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 280) {
      bloc.add(const ContestFeedLoadMoreEvent());
    }
  }

  bool _canLike() {
    return PrefUtils().isLoggedIn() && !PrefUtils().isGuestAccount();
  }

  void _onLike(BuildContext context, int submissionId) {
    if (!_canLike()) {
      showAppToast(
        'msg_sign_in_to_like'.tr,
        type: ToastificationType.warning,
      );
      NavigatorService.pushNamed(AppRoutes.screen0LoginScreen);
      return;
    }
    context.read<ContestFeedBloc>().add(
          ContestFeedToggleLikeEvent(submissionId),
        );
  }

  void _openContest(BuildContext context, int contestId) {
    if (contestId <= 0) return;
    NavigatorService.pushNamed(
      AppRoutes.screenContesttwoScreen,
      arguments: ContestDetailArgs(contestId: contestId),
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<ContestFeedBloc>();
    bloc.add(const ContestFeedRefreshEvent());
    await waitForBlocLoadingComplete(
      bloc,
      isLoading: (s) => s.isRefreshing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowDownPrimary,
            onTap: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: AppbarTitle(text: 'lbl_contest_feed'.tr),
        ),
        body: BlocBuilder<ContestFeedBloc, ContestFeedState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppDs.space4.h,
                      AppDs.space3.v,
                      AppDs.space4.h,
                      AppDs.space2.v,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AppPageHeader(
                        title: 'lbl_contest_feed'.tr,
                        subtitle: 'msg_contest_feed_subtitle'.tr,
                      ),
                    ),
                  ),
                  _buildFeedSliver(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedSliver(BuildContext context, ContestFeedState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const SliverToBoxAdapter(child: AppContestFeedSkeleton());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return SliverFillRemaining(
        child: AppErrorState(
          message: state.errorMessage!,
          onRetry: () => context.read<ContestFeedBloc>().add(
                const ContestFeedInitialEvent(),
              ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return SliverFillRemaining(
        child: AppEmptyState(
          title: 'msg_no_feed_submissions'.tr,
          icon: Icons.dynamic_feed_outlined,
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppDs.space4.h,
        0,
        AppDs.space4.h,
        AppDs.space6.v,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= state.items.length) {
              if (state.hasMore && !state.isLoadingMore) {
                context.read<ContestFeedBloc>().add(
                      const ContestFeedLoadMoreEvent(),
                    );
              }
              return Padding(
                padding: EdgeInsets.all(AppDs.space4.h),
                child: state.isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink(),
              );
            }

            final item = state.items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppDs.space4.v),
              child: ContestFeedCard(
                submission: item,
                isLiking: state.likingIds.contains(item.id),
                onLike: () => _onLike(context, item.id),
                onShareRecorded: (sharesCount) {
                  context.read<ContestFeedBloc>().add(
                        ContestFeedShareRecordedEvent(
                          submissionId: item.id,
                          sharesCount: sharesCount,
                        ),
                      );
                },
                onOpenContest: () => _openContest(context, item.contestId),
              ),
            );
          },
          childCount: state.items.length + 1,
        ),
      ),
    );
  }
}
