import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/contest_winner.dart';
import '../../data/repositories/contest_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'widgets/contest_image_viewer.dart';

class ContestWinnersScreen extends StatefulWidget {
  const ContestWinnersScreen({super.key, required this.contestId});

  final int contestId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is int ? args : int.tryParse(args?.toString() ?? '') ?? 0;
    return ContestWinnersScreen(contestId: id);
  }

  @override
  State<ContestWinnersScreen> createState() => _ContestWinnersScreenState();
}

class _ContestWinnersScreenState extends State<ContestWinnersScreen> {
  final ContestRepository _repo = ContestRepository.instance;
  List<ContestWinner> _winners = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.publicWinners(widget.contestId);
    if (!mounted) return;
    if (result is ContestFailure) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    final list = (result as ContestWinnersResult).winners;
    setState(() {
      _winners = list;
      _loading = false;
      _error = null;
    });
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
          title: AppbarTitle(text: 'lbl_view_winners'.tr),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppImageGridSkeleton();
    if (_error != null) {
      return Center(
        child: AppErrorState(
          message: _error!,
          onRetry: _load,
          retryLabel: 'lbl_retry'.tr,
        ),
      );
    }
    if (_winners.isEmpty) {
      return Center(
        child: AppEmptyState(
          title: 'msg_no_winners_yet'.tr,
          icon: Icons.emoji_events_outlined,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.all(16.h),
        itemCount: _winners.length,
        separatorBuilder: (_, _) => SizedBox(height: 16.v),
        itemBuilder: (context, index) {
          final w = _winners[index];
          return _WinnerCard(winner: w);
        },
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.winner});
  final ContestWinner winner;

  @override
  Widget build(BuildContext context) {
    final image = winner.imageUrl.trim();
    final name = winner.winnerName ?? 'lbl_winner'.tr;

    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.blueGray90001,
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.adaptSize,
            backgroundColor: appTheme.yellow500,
            child: Text(
              '#${winner.position}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 12.h),
          GestureDetector(
            onTap: image.isEmpty
                ? null
                : () => showContestImageSheet(
                      context,
                      imageUrl: image,
                      title: name,
                      subtitle: winner.prizeDisplay(),
                    ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.adaptSize),
                  child: CustomImageView(
                    imagePath: winner.imageUrl,
                    height: 72.v,
                    width: 72.h,
                    fit: BoxFit.cover,
                  ),
                ),
                if (image.isNotEmpty)
                  Positioned(
                    right: 2.h,
                    bottom: 2.v,
                    child: Container(
                      padding: EdgeInsets.all(4.adaptSize),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                      child: Icon(
                        Icons.zoom_in_rounded,
                        size: 14.adaptSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.winnerName ?? 'lbl_winner'.tr,
                  style: CustomTextStyles.titleSmallVisbyRoundCF,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (winner.prizeDisplay().isNotEmpty)
                  Text(
                    winner.prizeDisplay(),
                    style: CustomTextStyles.bodySmallInter.copyWith(
                      color: appTheme.yellow500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
