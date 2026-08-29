import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/contest_feed_share.dart';
import '../../../data/models/contest_submission.dart';
import 'contest_image_viewer.dart';

class ContestFeedCard extends StatefulWidget {
  const ContestFeedCard({
    super.key,
    required this.submission,
    required this.onLike,
    required this.onShare,
    required this.onOpenPreview,
    this.isLiking = false,
    this.isSharing = false,
    this.onOpenContest,
  });

  final ContestSubmission submission;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onOpenPreview;
  final bool isLiking;
  final bool isSharing;
  final VoidCallback? onOpenContest;

  @override
  State<ContestFeedCard> createState() => _ContestFeedCardState();
}

class _ContestFeedCardState extends State<ContestFeedCard> {
  bool _likePressed = false;
  bool _sharePressed = false;

  ContestSubmission get s => widget.submission;

  bool get _isVideo {
    final url = s.imageUrl.toLowerCase();
    return url.endsWith('.mp4') ||
        url.endsWith('.webm') ||
        url.endsWith('.mov') ||
        url.contains('/video/');
  }

  void _openPreview() {
    final url = s.imageUrl.trim();
    if (url.isEmpty) return;
    widget.onOpenPreview();
    showContestImageSheet(
      context,
      imageUrl: url,
      title: s.contestDisplayName.isNotEmpty
          ? s.contestDisplayName
          : s.contestTitle,
      subtitle: s.designerName.isNotEmpty ? s.designerName : s.submitterName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final liked = s.isLiked ?? false;
    final likes = s.likesCount ?? 0;
    final shares = s.sharesCount ?? 0;
    final views = s.viewsCount ?? 0;
    final avatarUrl = s.submitterAvatarUrl ?? s.userSummary?.avatarUrl ?? '';
    final name = s.designerName.isNotEmpty
        ? s.designerName
        : 'lbl_participant'.tr;
    final contestTitle = s.contestDisplayName.isNotEmpty
        ? s.contestDisplayName
        : 'lbl_contest'.tr;
    final timestamp = formatRelativeTimestamp(s.createdAt);
    final comments = s.displayComments;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: AppDs.cardDecoration(elevated: true),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space4.v,
              AppDs.space4.h,
              AppDs.space3.v,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarCircle(url: avatarUrl, name: name),
                SizedBox(width: AppDs.space3.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.cardTitle(theme).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppDs.textOnDarkPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timestamp.isNotEmpty) ...[
                        SizedBox(height: 2.v),
                        Text(
                          timestamp,
                          style: AppTypography.caption(
                            theme,
                          ).copyWith(color: AppDs.textOnDarkSecondary),
                        ),
                      ],
                      SizedBox(height: AppDs.space2.v),
                      InkWell(
                        onTap: widget.onOpenContest,
                        borderRadius: BorderRadius.circular(
                          AppDs.radiusSm.adaptSize,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.v),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 14.adaptSize,
                                color: cs.primary,
                              ),
                              SizedBox(width: 4.h),
                              Flexible(
                                child: Text(
                                  contestTitle,
                                  style: AppTypography.caption(theme).copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (s.isFeatured == true) ...[
                                SizedBox(width: 6.h),
                                Icon(
                                  Icons.star_rounded,
                                  size: 14.adaptSize,
                                  color: cs.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (s.imageUrl.trim().isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openPreview,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: CustomImageView(
                        imagePath: s.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        radius: BorderRadius.zero,
                      ),
                    ),
                    if (_isVideo)
                      Container(
                        padding: EdgeInsets.all(AppDs.space3.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36.adaptSize,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space3.v,
              AppDs.space4.h,
              AppDs.space2.v,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (likes > 0 || shares > 0 || views > 0)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppDs.space2.v),
                    child: Text(
                      _engagementSummary(
                        likes: likes,
                        shares: shares,
                        views: views,
                      ),
                      style: AppTypography.caption(
                        theme,
                      ).copyWith(color: AppDs.textOnDarkSecondary),
                    ),
                  ),
                if (comments.isNotEmpty) ...[
                  Text(
                    comments,
                    style: AppTypography.bodyMedium(
                      theme,
                    ).copyWith(color: AppDs.textOnDarkPrimary, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space2.h,
              vertical: AppDs.space1.v,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FeedActionButton(
                    icon: liked ? Icons.favorite : Icons.favorite_border,
                    label: liked ? 'lbl_liked'.tr : 'lbl_like'.tr,
                    active: liked,
                    loading: widget.isLiking,
                    pressed: _likePressed,
                    onHighlight: (v) => setState(() => _likePressed = v),
                    onTap: widget.onLike,
                  ),
                ),
                Expanded(
                  child: _FeedActionButton(
                    icon: Icons.share_outlined,
                    label: 'lbl_share'.tr,
                    loading: widget.isSharing,
                    pressed: _sharePressed,
                    onHighlight: (v) => setState(() => _sharePressed = v),
                    onTap: widget.onShare,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _engagementSummary({
    required int likes,
    required int shares,
    required int views,
  }) {
    final parts = <String>[];
    if (views > 0) {
      parts.add('$views ${'lbl_views'.tr}');
    }
    if (likes > 0) {
      parts.add('$likes ${likes == 1 ? 'lbl_like'.tr : 'lbl_likes'.tr}');
    }
    if (shares > 0) {
      parts.add('$shares ${'lbl_shares'.tr}');
    }
    return parts.join(' · ');
  }
}

/// Opens the share sheet after the BLoC has recorded the share and provided
/// a backend [shareUrl].
Future<void> openContestFeedShareSheet({
  required BuildContext context,
  required ContestSubmission submission,
  required String shareUrl,
  String? preferredChannel,
}) async {
  final contestTitle = submission.contestDisplayName.isNotEmpty
      ? submission.contestDisplayName
      : 'lbl_contest'.tr;
  final submitter = submission.designerName.isNotEmpty
      ? submission.designerName
      : 'lbl_participant'.tr;
  final message = ContestFeedShare.shareMessage(
    contestTitle: contestTitle,
    submitterName: submitter,
    url: shareUrl,
  );

  if (preferredChannel != null && preferredChannel.isNotEmpty) {
    await ContestFeedShare.shareNative(message: message, subject: contestTitle);
    return;
  }

  await showAppModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'lbl_share'.tr,
                style: AppDs.sheetTitle(theme, color: Colors.white),
              ),
              SizedBox(height: AppDs.space4.v),
              _ShareOptionTile(
                icon: Icons.ios_share_outlined,
                label: 'lbl_share_via'.tr,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await ContestFeedShare.shareNative(
                    message: message,
                    subject: contestTitle,
                  );
                },
              ),
              _ShareOptionTile(
                icon: Icons.link_outlined,
                label: 'lbl_copy_link'.tr,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await ContestFeedShare.copyLink(shareUrl);
                  showAppToast(
                    'msg_link_copied'.tr,
                    type: ToastificationType.success,
                  );
                },
              ),
              SizedBox(height: AppDs.space2.v),
            ],
          ),
        ),
      );
    },
  );
}

class _FeedActionButton extends StatelessWidget {
  const _FeedActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.onHighlight,
    this.active = false,
    this.loading = false,
    this.pressed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final void Function(bool) onHighlight;
  final bool active;
  final bool loading;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final color = active ? cs.primary : AppDs.textOnDarkSecondary;

    return AnimatedScale(
      scale: pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          onHighlightChanged: onHighlight,
          borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
          child: Container(
            constraints: BoxConstraints(minHeight: AppDs.minTap.v),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 20.adaptSize,
                    height: 20.adaptSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20.adaptSize, color: color),
                      SizedBox(width: AppDs.space2.h),
                      Text(
                        label,
                        style: AppTypography.navInactive(theme).copyWith(
                          color: color,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final size = 48.adaptSize;
    if (url.trim().isNotEmpty) {
      return CustomImageView(
        imagePath: url,
        height: size,
        width: size,
        fit: BoxFit.cover,
        radius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
      );
    }
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.25),
      child: Text(
        initial,
        style: AppTypography.cardTitle(theme).copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  const _ShareOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
      ),
    );
  }
}
