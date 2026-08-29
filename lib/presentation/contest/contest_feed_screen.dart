import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/contest_submission.dart';
import '../../presentation/guest_upgrade/guest_upgrade_prompt.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../screen_contesttwo_screen/models/contest_detail_args.dart';
import 'bloc/contest_feed_bloc.dart';
import 'contest_feed_social_access.dart';
import 'widgets/contest_feed_card.dart';

class ContestFeedScreen extends StatefulWidget {
  const ContestFeedScreen({
    super.key,
    this.focusSubmissionId,
    this.deepLinkContestId,
  });

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    int? focusSubmissionId;
    int? contestId;
    if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      focusSubmissionId = _readPositiveInt(
        map['submissionId'] ?? map['submission_id'],
      );
      contestId = _readPositiveInt(map['contestId'] ?? map['contest_id']);
    }

    return BlocProvider<ContestFeedBloc>(
      create: (_) =>
          ContestFeedBloc(const ContestFeedState())
            ..add(const ContestFeedInitialEvent()),
      child: ContestFeedScreen(
        focusSubmissionId: focusSubmissionId,
        deepLinkContestId: contestId,
      ),
    );
  }

  /// Optional submission id from a shared deep link.
  final int? focusSubmissionId;
  final int? deepLinkContestId;

  @override
  State<ContestFeedScreen> createState() => _ContestFeedScreenState();
}

int? _readPositiveInt(Object? raw) {
  if (raw is int) return raw > 0 ? raw : null;
  if (raw is num) {
    final v = raw.toInt();
    return v > 0 ? v : null;
  }
  final parsed = int.tryParse(raw?.toString() ?? '');
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

class _ContestFeedScreenState extends State<ContestFeedScreen> {
  final ScrollController _scroll = ScrollController();
  bool _didAnnounceDeepLink = false;

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

  bool _requireAccountForSocial() {
    final access = resolveContestFeedSocialAccess(
      isLoggedIn: PrefUtils().isLoggedIn(),
      isGuestAccount: PrefUtils().isGuestAccount(),
    );
    switch (access) {
      case ContestFeedSocialAccess.loginRequired:
        showAppToast(
          'msg_sign_in_to_like'.tr,
          type: ToastificationType.warning,
        );
        SessionManager.instance.rememberCurrentRouteAsPending();
        NavigatorService.pushNamed(AppRoutes.screen0LoginScreen);
        return false;
      case ContestFeedSocialAccess.upgradeRequired:
        showGuestUpgradePrompt('msg_guest_feature_locked'.tr);
        return false;
      case ContestFeedSocialAccess.allowed:
        return true;
    }
  }

  void _onLike(BuildContext context, int submissionId) {
    if (!_requireAccountForSocial()) return;
    context.read<ContestFeedBloc>().add(
      ContestFeedToggleLikeEvent(submissionId),
    );
  }

  void _onShare(BuildContext context, int submissionId) {
    if (!_requireAccountForSocial()) return;
    context.read<ContestFeedBloc>().add(
      ContestFeedShareEvent(submissionId: submissionId),
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
    await waitForBlocLoadingComplete(bloc, isLoading: (s) => s.isRefreshing);
  }

  Future<void> _handlePendingShare(
    BuildContext context,
    ContestFeedState state,
  ) async {
    final url = state.pendingShareUrl?.trim();
    final id = state.pendingShareSubmissionId;
    if (url == null || url.isEmpty || id == null) return;

    ContestSubmission? submission;
    for (final item in state.items) {
      if (item.id == id) {
        submission = item;
        break;
      }
    }
    context.read<ContestFeedBloc>().add(const ContestFeedClearErrorEvent());

    if (submission == null) {
      showAppToast(
        'msg_share_link_unavailable'.tr,
        type: ToastificationType.warning,
      );
      return;
    }

    await openContestFeedShareSheet(
      context: context,
      submission: submission,
      shareUrl: url,
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
        body: MultiBlocListener(
          listeners: [
            BlocListener<ContestFeedBloc, ContestFeedState>(
              listenWhen: (prev, next) =>
                  next.errorMessage != null &&
                  next.errorMessage != prev.errorMessage,
              listener: (context, state) {
                final msg = state.errorMessage;
                if (msg == null || msg.isEmpty) return;
                showAppToast(msg, type: ToastificationType.error);
                // Keep full-page error when the list is empty so retry stays visible.
                if (state.items.isNotEmpty) {
                  context.read<ContestFeedBloc>().add(
                    const ContestFeedClearErrorEvent(),
                  );
                }
              },
            ),
            BlocListener<ContestFeedBloc, ContestFeedState>(
              listenWhen: (prev, next) =>
                  next.pendingShareUrl != null &&
                  next.pendingShareUrl != prev.pendingShareUrl,
              listener: (context, state) {
                _handlePendingShare(context, state);
              },
            ),
            BlocListener<ContestFeedBloc, ContestFeedState>(
              listenWhen: (prev, next) =>
                  !_didAnnounceDeepLink &&
                  next.items.isNotEmpty &&
                  (widget.focusSubmissionId != null ||
                      widget.deepLinkContestId != null),
              listener: (context, state) {
                _didAnnounceDeepLink = true;
                final focusId = widget.focusSubmissionId;
                if (focusId == null) return;
                final index = state.items.indexWhere((e) => e.id == focusId);
                if (index < 0) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_scroll.hasClients) return;
                  // Approximate card height; enough to bring shared item into view.
                  final offset = (index * 420.0).clamp(
                    0.0,
                    _scroll.position.maxScrollExtent,
                  );
                  _scroll.animateTo(
                    offset,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                  );
                });
              },
            ),
          ],
          child: BlocBuilder<ContestFeedBloc, ContestFeedState>(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppPageHeader(
                              title: 'lbl_contest_feed'.tr,
                              subtitle: 'msg_contest_feed_subtitle'.tr,
                            ),
                            SizedBox(height: AppDs.space3.v),
                            _FeedFilters(state: state),
                          ],
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
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= state.items.length) {
            if (state.loadMoreError != null) {
              return Padding(
                padding: EdgeInsets.all(AppDs.space4.h),
                child: Column(
                  children: [
                    Text(
                      state.loadMoreError!,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(
                        theme,
                      ).copyWith(color: AppDs.textOnDarkSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.read<ContestFeedBloc>().add(
                        const ContestFeedLoadMoreEvent(),
                      ),
                      child: Text('lbl_retry'.tr),
                    ),
                  ],
                ),
              );
            }
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
              isSharing: state.sharingIds.contains(item.id),
              onLike: () => _onLike(context, item.id),
              onShare: () => _onShare(context, item.id),
              onOpenPreview: () {
                context.read<ContestFeedBloc>().add(
                  ContestFeedRecordViewEvent(item.id),
                );
              },
              onOpenContest: () => _openContest(context, item.contestId),
            ),
          );
        }, childCount: state.items.length + 1),
      ),
    );
  }
}

class _FeedFilters extends StatelessWidget {
  const _FeedFilters({required this.state});

  final ContestFeedState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ContestFeedBloc>();
    return Wrap(
      spacing: AppDs.space2.h,
      runSpacing: AppDs.space2.v,
      children: [
        ChoiceChip(
          label: Text('lbl_recent'.tr),
          selected: state.sort == 'recent',
          onSelected: (_) =>
              bloc.add(const ContestFeedSortChangedEvent('recent')),
        ),
        ChoiceChip(
          label: Text('lbl_most_liked'.tr),
          selected: state.sort == 'likes',
          onSelected: (_) =>
              bloc.add(const ContestFeedSortChangedEvent('likes')),
        ),
        FilterChip(
          label: Text('lbl_featured'.tr),
          selected: state.featuredOnly,
          onSelected: (v) => bloc.add(ContestFeedFeaturedFilterEvent(v)),
        ),
      ],
    );
  }
}
