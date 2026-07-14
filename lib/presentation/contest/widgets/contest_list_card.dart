import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../screen_contest_screen/models/certificatedesign_item_model.dart';
import 'contest_countdown_timer.dart';
import 'contest_image_viewer.dart';
import 'contest_status_chip.dart';

/// User-friendly contest card for the public listing screen.
class ContestListCard extends StatelessWidget {
  const ContestListCard({
    super.key,
    required this.model,
    this.onOpenDetail,
    this.onQuickAction,
    this.animateIn = false,
  });

  final CertificatedesignItemModel model;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onQuickAction;
  final bool animateIn;

  String? get _ctaLabel {
    final action = model.primaryAction ?? '';
    return switch (action) {
      'join' => 'lbl_join_contest'.tr,
      'submit' => 'lbl_submit_design'.tr,
      'gallery' => 'lbl_browse_gallery'.tr,
      'winners' => 'lbl_view_winners'.tr,
      'results' => 'lbl_view_results'.tr,
      'notify' => 'lbl_notify_upcoming'.tr,
      _ => 'lbl_view_contest'.tr,
    };
  }

  bool get _isPrimaryCta {
    final action = model.primaryAction ?? '';
    return action == 'join' || action == 'submit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = model.certificateText?.trim() ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      elevated: true,
      animateIn: animateIn,
      onTap: onOpenDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContestImageBanner(
            imageUrl: model.image,
            title: title,
            showActions: false,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDs.radiusLg.adaptSize),
            ),
            overlay: Positioned(
              top: AppDs.space3.v,
              left: AppDs.space3.h,
              right: AppDs.space3.h,
              child: Row(
                children: [
                  ContestStatusChip(status: model.status),
                  if (model.hasJoined) ...[
                    SizedBox(width: AppDs.space2.h),
                    _JoinedBadge(),
                  ],
                  const Spacer(),
                  if (model.prizeText?.trim().isNotEmpty == true)
                    _PrizeBadge(text: model.prizeText!.trim()),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppDs.space4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle(theme), maxLines: 2),
                if (model.categoryName?.trim().isNotEmpty == true) ...[
                  SizedBox(height: AppDs.space2.v),
                  _MetaRow(
                    icon: Icons.category_outlined,
                    text: model.categoryName!.trim(),
                  ),
                ],
                if (model.dateRange?.trim().isNotEmpty == true) ...[
                  SizedBox(height: AppDs.space1.v),
                  _MetaRow(
                    icon: Icons.calendar_today_outlined,
                    text: model.dateRange!.trim(),
                  ),
                ],
                SizedBox(height: AppDs.space3.v),
                _buildStatsRow(theme),
                if (model.countdown != null) ...[
                  SizedBox(height: AppDs.space3.v),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDs.space3.h,
                      vertical: AppDs.space2.v,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                    ),
                    child: ContestCountdownTimer(
                      countdown: model.countdown,
                      compact: true,
                    ),
                  ),
                ],
                if (onQuickAction != null) ...[
                  SizedBox(height: AppDs.space4.v),
                  _isPrimaryCta
                      ? AppPrimaryButton(
                          label: _ctaLabel ?? 'lbl_view_contest'.tr,
                          onPressed: onQuickAction,
                        )
                      : AppSecondaryButton(
                          label: _ctaLabel ?? 'lbl_view_contest'.tr,
                          onPressed: onQuickAction,
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    final parts = <Widget>[];
    if (model.participantsCount != null) {
      parts.add(_StatChip(
        icon: Icons.people_outline,
        value: '${model.participantsCount}',
        label: 'lbl_participants'.tr,
      ));
    }
    if (model.submissionsCount != null) {
      parts.add(_StatChip(
        icon: Icons.brush_outlined,
        value: '${model.submissionsCount}',
        label: 'lbl_submissions'.tr,
      ));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: AppDs.space3.h, runSpacing: AppDs.space2.v, children: parts);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDs.iconSm.adaptSize, color: AppDs.textSecondary(theme.colorScheme)),
        SizedBox(width: AppDs.space2.h),
        Expanded(child: Text(text, style: AppTypography.secondary(theme), maxLines: 1)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDs.iconSm.adaptSize, color: AppDs.textSecondary(theme.colorScheme)),
        SizedBox(width: AppDs.space1.h),
        Text(value, style: AppTypography.accent(theme)),
        SizedBox(width: AppDs.space1.h),
        Text(label, style: AppTypography.secondary(theme)),
      ],
    );
  }
}

class _PrizeBadge extends StatelessWidget {
  const _PrizeBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space2.h, vertical: AppDs.space1.v),
      decoration: BoxDecoration(
        color: appTheme.yellow500.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined, size: 14.adaptSize, color: appTheme.gray900),
          SizedBox(width: AppDs.space1.h),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: appTheme.gray900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space2.h, vertical: AppDs.space1.v),
      decoration: BoxDecoration(
        color: appTheme.green500.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
      ),
      child: Text(
        'lbl_joined'.tr,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
