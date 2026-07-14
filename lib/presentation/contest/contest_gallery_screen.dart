import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/contest_detail.dart';
import '../../data/models/contest_submission.dart';
import '../../data/repositories/contest_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'widgets/contest_image_viewer.dart';

class ContestGalleryScreen extends StatefulWidget {
  const ContestGalleryScreen({super.key, required this.contestId});

  final int contestId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is int ? args : int.tryParse(args?.toString() ?? '') ?? 0;
    return ContestGalleryScreen(contestId: id);
  }

  @override
  State<ContestGalleryScreen> createState() => _ContestGalleryScreenState();
}

class _ContestGalleryScreenState extends State<ContestGalleryScreen> {
  final ContestRepository _repo = ContestRepository.instance;
  final ScrollController _scroll = ScrollController();
  final List<ContestSubmission> _items = [];
  String _sort = 'recent';
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _items.clear();
      });
    } else {
      if (!_hasMore) return;
      setState(() => _loadingMore = true);
    }

    final result = await _repo.gallerySubmissions(
      widget.contestId,
      sort: _sort,
      page: reset ? 1 : _page,
    );
    if (!mounted) return;

    if (result is ContestFailure) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = result.message;
      });
      return;
    }

    final success = result as ContestSubmissionsResult;
    setState(() {
      if (reset) _items.clear();
      _items.addAll(success.submissions);
      _hasMore = success.page?.hasMore ?? false;
      _page = (success.page?.nextPage ?? _page + 1);
      _loading = false;
      _loadingMore = false;
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
          title: AppbarTitle(text: 'lbl_browse_gallery'.tr),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('lbl_recent'.tr),
                    selected: _sort == 'recent',
                    onSelected: (_) {
                      _sort = 'recent';
                      _load(reset: true);
                    },
                  ),
                  SizedBox(width: 8.h),
                  ChoiceChip(
                    label: Text('lbl_most_liked'.tr),
                    selected: _sort == 'most_liked',
                    onSelected: (_) {
                      _sort = 'most_liked';
                      _load(reset: true);
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppImageGridSkeleton();
    }
    if (_error != null) {
      return Center(
        child: AppErrorState(
          message: _error!,
          onRetry: () => _load(reset: true),
          retryLabel: 'lbl_retry'.tr,
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: AppEmptyState(
          title: 'msg_no_gallery_submissions'.tr,
          icon: Icons.photo_library_outlined,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: GridView.builder(
        controller: _scroll,
        padding: EdgeInsets.all(16.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.h,
          mainAxisSpacing: 12.v,
          childAspectRatio: 0.85,
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = _items[index];
          return _GalleryCard(submission: item);
        },
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.submission});
  final ContestSubmission submission;

  @override
  Widget build(BuildContext context) {
    final image = submission.imageUrl.trim();
    final title = submission.submitterName ?? 'lbl_submissions'.tr;

    return Material(
      color: appTheme.blueGray90001,
      borderRadius: BorderRadius.circular(12.adaptSize),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: image.isEmpty
            ? null
            : () => showContestImageSheet(
                  context,
                  imageUrl: image,
                  title: title,
                  subtitle: submission.likesCount != null
                      ? '${submission.likesCount} ${'lbl_likes'.tr}'
                      : null,
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.adaptSize),
                    ),
                    child: CustomImageView(
                      imagePath: submission.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  if (image.isNotEmpty)
                    Positioned(
                      right: 8.h,
                      bottom: 8.v,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20.adaptSize),
                        child: InkWell(
                          onTap: () => openContestImageFullscreen(
                            context,
                            imageUrl: image,
                            title: title,
                          ),
                          borderRadius: BorderRadius.circular(20.adaptSize),
                          child: Padding(
                            padding: EdgeInsets.all(6.adaptSize),
                            child: Icon(
                              Icons.zoom_in_rounded,
                              size: 18.adaptSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (submission.submitterName != null)
                  Text(
                    submission.submitterName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyles.bodySmallInter,
                  ),
                if (submission.likesCount != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${submission.likesCount}',
                          style: AppTypography.accent(theme).copyWith(
                            fontSize: AppDs.fontSecondary.fSize,
                          ),
                        ),
                        TextSpan(
                          text: ' ${'lbl_likes'.tr}',
                          style: AppTypography.secondary(theme),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

Future<void> showContestEligibleDesignsSheet({
  required BuildContext context,
  required int contestId,
  required ContestRepository repo,
  required void Function(int designId) onSubmitted,
}) async {
  final result = await repo.eligibleDesigns(contestId);
  if (!context.mounted) return;
  if (result is ContestFailure) {
    showAppToast(result.message, type: ToastificationType.error);
    return;
  }
  final designs = (result as ContestEligibleDesignsResult).designs;
  if (designs.isEmpty) {
    showAppToast('msg_no_eligible_designs'.tr, type: ToastificationType.info);
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EligibleDesignsSheet(
      designs: designs,
      hint: result.hint,
      onPick: (id) async {
        Navigator.of(ctx).pop();
        final submitRes = await repo.submitDesign(
          contestId: contestId,
          designId: id,
        );
        if (!context.mounted) return;
        if (submitRes is ContestFailure) {
          showAppToast(submitRes.message, type: ToastificationType.error);
          return;
        }
        showAppToast(
          (submitRes as ContestMessageResult).message ??
              'msg_design_submitted'.tr,
        );
        onSubmitted(id);
      },
    ),
  );
}

class _EligibleDesignsSheet extends StatelessWidget {
  const _EligibleDesignsSheet({
    required this.designs,
    required this.onPick,
    this.hint,
  });

  final List<ContestEligibleDesign> designs;
  final ValueChanged<int> onPick;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      decoration: BoxDecoration(
        color: AppDs.sheetBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDs.radiusSheet.adaptSize),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.v),
          Text('lbl_select_design'.tr, style: theme.textTheme.titleMedium),
          if (hint != null && hint!.trim().isNotEmpty) ...[
            SizedBox(height: 8.v),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              child: Text(
                hint!.trim(),
                textAlign: TextAlign.center,
                style: AppTypography.secondary(theme),
              ),
            ),
          ],
          SizedBox(height: 12.v),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.h,
                mainAxisSpacing: 10.v,
              ),
              itemCount: designs.length,
              itemBuilder: (context, index) {
                final d = designs[index];
                return GestureDetector(
                  onTap: () => onPick(d.id),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.adaptSize),
                    child: CustomImageView(
                      imagePath: d.displayUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
