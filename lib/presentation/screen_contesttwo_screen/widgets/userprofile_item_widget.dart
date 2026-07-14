import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../contest/widgets/contest_image_viewer.dart';
import '../models/userprofile_item_model.dart';

class UserprofileItemWidget extends StatelessWidget {
  const UserprofileItemWidget(
    this.userprofileItemModelObj, {
    super.key,
    this.onImageTap,
  });

  final UserprofileItemModel userprofileItemModelObj;
  final VoidCallback? onImageTap;

  Color _placeColor(int position) {
    return switch (position) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => theme.colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final position = userprofileItemModelObj.placePosition;
    final image = userprofileItemModelObj.userImage?.trim() ?? '';
    final name = userprofileItemModelObj.username?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppDs.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: image.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomImageView(
                            imagePath: image,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 10.h,
                            bottom: 10.v,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _MiniImageButton(
                                  icon: Icons.visibility_outlined,
                                  onTap: onImageTap ??
                                      () => showContestImageSheet(
                                            context,
                                            imageUrl: image,
                                            title: name,
                                          ),
                                ),
                                SizedBox(width: 8.h),
                                _MiniImageButton(
                                  icon: Icons.zoom_in_rounded,
                                  onTap: () => openContestImageFullscreen(
                                    context,
                                    imageUrl: image,
                                    title: name,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ColoredBox(
                        color: appTheme.blueGray90001,
                        child: Icon(
                          Icons.image_outlined,
                          size: 40.adaptSize,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
              ),
              if (position != null && position >= 1 && position <= 3)
                Positioned(
                  top: 10.v,
                  left: 10.h,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.v),
                    decoration: BoxDecoration(
                      color: _placeColor(position).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20.adaptSize),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 16.adaptSize,
                          color: appTheme.gray900,
                        ),
                        SizedBox(width: 4.h),
                        Text(
                          '#$position',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: appTheme.gray900,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.h, 10.v, 14.h, 12.v),
            child: Text(
              name.isNotEmpty ? name : 'lbl_participant'.tr,
              style: AppTypography.cardTitle(theme),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniImageButton extends StatelessWidget {
  const _MiniImageButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20.adaptSize),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.adaptSize),
        child: Padding(
          padding: EdgeInsets.all(8.adaptSize),
          child: Icon(icon, size: 18.adaptSize, color: Colors.white),
        ),
      ),
    );
  }
}
