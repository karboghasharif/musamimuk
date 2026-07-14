import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/contest_submission.dart';
import '../../data/repositories/contest_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'widgets/contest_image_viewer.dart';

class ContestMySubmissionsScreen extends StatefulWidget {
  const ContestMySubmissionsScreen({super.key, required this.contestId});

  final int contestId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is int ? args : int.tryParse(args?.toString() ?? '') ?? 0;
    return ContestMySubmissionsScreen(contestId: id);
  }

  @override
  State<ContestMySubmissionsScreen> createState() =>
      _ContestMySubmissionsScreenState();
}

class _ContestMySubmissionsScreenState extends State<ContestMySubmissionsScreen> {
  final ContestRepository _repo = ContestRepository.instance;
  List<ContestSubmission> _items = const [];
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
    final result = await _repo.mySubmissions(widget.contestId);
    if (!mounted) return;
    if (result is ContestFailure) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    final list = (result as ContestSubmissionsResult).submissions;
    setState(() {
      _items = list;
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
          title: AppbarTitle(text: 'lbl_my_submissions'.tr),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.separated(
        padding: EdgeInsets.all(AppDs.space4.h),
        itemCount: 4,
        separatorBuilder: (_, _) => SizedBox(height: AppDs.space3.v),
        itemBuilder: (_, _) => AppSkeletonBox(
          height: 88.v,
          borderRadius: BorderRadius.circular(AppDs.radiusLg),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: AppErrorState(
          message: _error!,
          onRetry: _load,
          retryLabel: 'lbl_retry'.tr,
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: AppEmptyState(
          title: 'msg_no_my_submissions'.tr,
          icon: Icons.collections_outlined,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.all(16.h),
        itemCount: _items.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.v),
        itemBuilder: (context, index) => _SubmissionRow(item: _items[index]),
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.item});
  final ContestSubmission item;

  Color _statusColor(String status) {
    return switch (status) {
      'Approved' => appTheme.green500,
      'Rejected' => appTheme.redA400,
      _ => appTheme.yellow500,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = item.displayStatus;
    final date = formatContestDateRangeDisplay(item.createdAt, null);
    final image = item.imageUrl.trim();

    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.blueGray90001,
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: image.isEmpty
                ? null
                : () => showContestImageSheet(
                      context,
                      imageUrl: image,
                      title: status,
                      subtitle: date.isNotEmpty ? date : null,
                    ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.adaptSize),
                  child: CustomImageView(
                    imagePath: item.imageUrl,
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
                Text(status, style: TextStyle(color: _statusColor(status))),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: AppTypography.secondary(theme),
                  ),
                if (item.rejectionReason != null &&
                    item.rejectionReason!.isNotEmpty)
                  Text(
                    item.rejectionReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyles.bodySmallInter,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
