import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../widgets/design_preview_sheet.dart';

/// Opens a bottom sheet with pinch-to-zoom preview and actions.
Future<void> showContestImageSheet(
  BuildContext context, {
  required String imageUrl,
  String? title,
  String? subtitle,
  Widget? footer,
}) async {
  final path = imageUrl.trim();
  if (path.isEmpty) return;

  await showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null && title.trim().isNotEmpty) ...[
                  Text(
                    title.trim(),
                    style: AppDs.sheetTitle(theme, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDs.space2.v),
                ],
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  Text(
                    subtitle.trim(),
                    style: AppDs.sheetCaption(
                      theme,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDs.space3.v),
                ],
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDs.radiusMd.adaptSize),
                  child: ContestZoomableImage(
                    imageUrl: path,
                    height: 300.v,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Text(
                  'msg_pinch_to_zoom'.tr,
                  textAlign: TextAlign.center,
                  style: AppDs.sheetCaption(
                    theme,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                if (footer != null) ...[
                  SizedBox(height: AppDs.space4.v),
                  footer,
                ],
                SizedBox(height: AppDs.space4.v),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          openContestImageFullscreen(
                            context,
                            imageUrl: path,
                            title: title,
                          );
                        },
                        icon: const Icon(Icons.fullscreen, size: 20),
                        label: Text('lbl_fullscreen'.tr),
                      ),
                    ),
                    SizedBox(width: AppDs.space3.h),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: designPreviewIsNetworkUrl(path)
                            ? () async {
                                try {
                                  await Share.shareUri(Uri.parse(path));
                                } catch (_) {
                                  await Share.share(path);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.share_outlined, size: 20),
                        label: Text('lbl_share_link'.tr),
                      ),
                    ),
                  ],
                ),
                if (designPreviewIsNetworkUrl(path)) ...[
                  SizedBox(height: AppDs.space3.v),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(path);
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: Text('lbl_open_in_browser'.tr),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Full-screen black backdrop with pinch-to-zoom.
Future<void> openContestImageFullscreen(
  BuildContext context, {
  required String imageUrl,
  String? title,
}) {
  final path = imageUrl.trim();
  if (path.isEmpty) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ContestImageFullscreenPage(
        imageUrl: path,
        title: title,
      ),
    ),
  );
}

class ContestImageFullscreenPage extends StatelessWidget {
  const ContestImageFullscreenPage({
    super.key,
    required this.imageUrl,
    this.title,
  });

  final String imageUrl;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: title != null && title!.trim().isNotEmpty
            ? Text(
                title!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        actions: [
          if (designPreviewIsNetworkUrl(imageUrl))
            IconButton(
              tooltip: 'lbl_share_link'.tr,
              onPressed: () async {
                try {
                  await Share.shareUri(Uri.parse(imageUrl.trim()));
                } catch (_) {
                  await Share.share(imageUrl.trim());
                }
              },
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ContestZoomableImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppDs.space4.adaptSize),
              child: Text(
                'msg_pinch_to_zoom'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable zoomable image — [InteractiveViewer] with optional fixed height.
class ContestZoomableImage extends StatelessWidget {
  const ContestZoomableImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.minScale = 0.6,
    this.maxScale = 5,
  });

  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double minScale;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final path = imageUrl.trim();
    if (path.isEmpty) {
      return SizedBox(
        height: height ?? 120.v,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 40.adaptSize,
          ),
        ),
      );
    }

    final image = InteractiveViewer(
      minScale: minScale,
      maxScale: maxScale,
      child: CustomImageView(
        imagePath: path,
        height: height,
        width: width ?? double.maxFinite,
        fit: fit,
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// Contest banner with separate view / zoom actions on the image area.
class ContestImageBanner extends StatelessWidget {
  const ContestImageBanner({
    super.key,
    required this.imageUrl,
    this.title,
    this.aspectRatio = 16 / 9,
    this.borderRadius,
    this.overlay,
    this.showActions = true,
    this.onImageTap,
  });

  final String? imageUrl;
  final String? title;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final Widget? overlay;
  final bool showActions;
  final VoidCallback? onImageTap;

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppDs.radiusLg.adaptSize);

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasImage)
              CustomImageView(
                imagePath: imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(
                color: appTheme.gray80001,
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 48.adaptSize,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            if (_hasImage)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            if (overlay != null) overlay!,
            if (showActions && _hasImage)
              Positioned(
                right: 10.h,
                bottom: 10.v,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ImageActionChip(
                      icon: Icons.visibility_outlined,
                      label: 'lbl_view_image'.tr,
                      onTap: onImageTap ??
                          () => showContestImageSheet(
                                context,
                                imageUrl: imageUrl!,
                                title: title,
                              ),
                    ),
                    SizedBox(width: 8.h),
                    _ImageActionChip(
                      icon: Icons.zoom_in_rounded,
                      label: 'lbl_zoom'.tr,
                      onTap: () => openContestImageFullscreen(
                        context,
                        imageUrl: imageUrl!,
                        title: title,
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

class _ImageActionChip extends StatelessWidget {
  const _ImageActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
          padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.v),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.adaptSize, color: Colors.white),
              SizedBox(width: 4.h),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
