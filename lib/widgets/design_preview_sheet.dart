import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_export.dart';
import '../data/repositories/design_interaction_repository.dart';

bool designPreviewIsNetworkUrl(String? s) {
  if (s == null || s.isEmpty) return false;
  final u = s.trim().toLowerCase();
  return u.startsWith('http://') || u.startsWith('https://');
}

/// Full-width preview with zoom, share, and open-in-browser for network URLs.
/// [footer] is placed above the action row (e.g. "View contest" button).
Future<void> showDesignPreviewSheet(
  BuildContext context, {
  required String imageRef,
  int? designId,
  String? title,
  String? subtitle,
  /// Multi-line catalog metadata (dimensions, tier, counts, etc.).
  String? detailsBody,
  Widget? footer,
}) async {
  await showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      if (designId != null) {
        // Fire-and-forget: doesn't block UI.
        DesignInteractionRepository().recordView(designId);
      }

      var isWorking = false;
      var isFavorite = false;

      return StatefulBuilder(
        builder: (context, setState) {
          final canCallApi = PrefUtils().isLoggedIn();
          Future<void> run(Future<void> Function() fn) async {
            if (isWorking) return;
            setState(() => isWorking = true);
            try {
              await fn();
            } finally {
              if (context.mounted) setState(() => isWorking = false);
            }
          }

          void toast(String msg) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }

          return AppDarkSheetTheme(
            child: AppSheetPagePadding(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: AppDs.sheetTitle(theme, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppDs.space2.v),
                  ],
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    Text(
                      subtitle,
                      style: AppDs.sheetCaption(
                        theme,
                        color: Colors.white.withValues(alpha: 0.65),
                      ).copyWith(height: 1.35),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppDs.space3.v),
                  ],
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDs.radiusMd.adaptSize),
                    child: InteractiveViewer(
                      minScale: 0.6,
                      maxScale: 4,
                      child: CustomImageView(
                        imagePath: imageRef,
                        height: 280.v,
                        width: double.maxFinite,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (detailsBody != null && detailsBody.trim().isNotEmpty) ...[
                    SizedBox(height: AppDs.space4.v),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'lbl_design_details'.tr,
                        style: AppDs.sheetCaption(
                          theme,
                          color: Colors.white.withValues(alpha: 0.85),
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(height: AppDs.space2.v),
                    Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.all(AppDs.space3.adaptSize),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius:
                            BorderRadius.circular(AppDs.radiusMd.adaptSize),
                      ),
                      child: SelectableText(
                        detailsBody.trim(),
                        style: AppDs.sheetCaption(
                          theme,
                          color: Colors.white.withValues(alpha: 0.78),
                        ).copyWith(height: 1.4),
                      ),
                    ),
                  ],
                  if (footer != null) ...[
                    SizedBox(height: AppDs.space4.v),
                    footer,
                  ],
                  SizedBox(height: AppDs.space4.v),

                  if (designId != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (!canCallApi || isWorking)
                                ? null
                                : () => run(() async {
                                      final repo =
                                          DesignInteractionRepository();
                                      final res = isFavorite
                                          ? await repo.removeFavorite(designId)
                                          : await repo.addFavorite(designId);
                                      if (res is DesignInteractionFailure) {
                                        toast(res.message);
                                        return;
                                      }
                                      setState(() => isFavorite = !isFavorite);
                                      toast(
                                        isFavorite
                                            ? 'Added to favorites'
                                            : 'Removed from favorites',
                                      );
                                    }),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                            ),
                            label: Text(
                              isFavorite ? 'Unfavorite' : 'Favorite',
                            ),
                          ),
                        ),
                        SizedBox(width: AppDs.space3.h),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: (!canCallApi || isWorking)
                                ? null
                                : () => run(() async {
                                      final repo =
                                          DesignInteractionRepository();
                                      final res =
                                          await repo.recordDownload(designId);
                                      if (res is DesignInteractionFailure) {
                                        toast(res.message);
                                        return;
                                      }
                                      if (!designPreviewIsNetworkUrl(imageRef)) {
                                        toast('Download link not available');
                                        return;
                                      }
                                      final uri = Uri.parse(imageRef.trim());
                                      try {
                                        await launchUrl(
                                          uri,
                                          mode:
                                              LaunchMode.externalApplication,
                                        );
                                      } catch (_) {}
                                    }),
                            icon: const Icon(Icons.download_outlined, size: 20),
                            label: const Text('Download'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDs.space3.v),
                    FilledButton.tonalIcon(
                      onPressed: (!canCallApi || isWorking)
                          ? null
                          : () => run(() async {
                                final repo = DesignInteractionRepository();
                                final res =
                                    await repo.removeBackground(designId);
                                if (res is DesignInteractionFailure) {
                                  toast(res.message);
                                  return;
                                }
                                toast('Background removal requested');
                              }),
                      icon: const Icon(Icons.auto_fix_high_outlined, size: 20),
                      label: const Text('Remove BG'),
                    ),
                    SizedBox(height: AppDs.space3.v),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: designPreviewIsNetworkUrl(imageRef)
                              ? () async {
                                  try {
                                    await Share.shareUri(
                                      Uri.parse(imageRef.trim()),
                                    );
                                  } catch (_) {
                                    await Share.share(imageRef.trim());
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.share_outlined, size: 20),
                          label: Text('lbl_share_link'.tr),
                        ),
                      ),
                      SizedBox(width: AppDs.space3.h),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: designPreviewIsNetworkUrl(imageRef)
                              ? () async {
                                  final uri = Uri.parse(imageRef.trim());
                                  try {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (_) {}
                                }
                              : null,
                          icon: const Icon(Icons.open_in_new, size: 20),
                          label: Text('lbl_open_in_browser'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
