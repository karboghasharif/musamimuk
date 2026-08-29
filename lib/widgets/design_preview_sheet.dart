import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_export.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/open_design_redesign.dart';
import '../data/models/wallet_models.dart';
import '../data/repositories/design_interaction_repository.dart';
import '../presentation/wallet/bloc/wallet_bloc.dart';
import '../presentation/wallet/wallet_cost_guard.dart';

bool designPreviewIsNetworkUrl(String? s) {
  if (s == null || s.isEmpty) return false;
  final u = s.trim().toLowerCase();
  return u.startsWith('http://') || u.startsWith('https://');
}

/// Full-width design preview sheet with zoom, share, and redesign.
Future<void> showDesignPreviewSheet(
  BuildContext context, {
  required String imageRef,
  int? designId,
  String? title,
  String? subtitle,

  /// Multi-line catalog metadata (kept for non-online callers).
  String? detailsBody,

  /// Preferred compact stats for online designs.
  String? categoryName,
  int? downloadsCount,
  int? trendingScore,
  String? designHistoryJson,
  int? designWidth,
  int? designHeight,
  Widget? footer,
  bool showRemoveBackground = true,

  /// When true, shows Redesign instead of Open in browser.
  bool enableRedesign = false,

  /// Public catalog designs are cloned before opening so originals stay intact.
  bool cloneBeforeRedesign = false,
}) async {
  final parentContext = context;
  await showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      if (designId != null) {
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
            showAppToast(msg);
          }

          final hasStructuredStats =
              categoryName != null ||
              downloadsCount != null ||
              trendingScore != null;
          final showLegacyDetails =
              !hasStructuredStats &&
              detailsBody != null &&
              detailsBody.trim().isNotEmpty;

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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppDs.space3.v),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDs.radiusMd.adaptSize,
                      ),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: InteractiveViewer(
                          minScale: 0.6,
                          maxScale: 4,
                          child: CustomImageView(
                            imagePath: imageRef,
                            height: 300.v,
                            width: double.maxFinite,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (hasStructuredStats) ...[
                      SizedBox(height: AppDs.space4.v),
                      Wrap(
                        spacing: 8.h,
                        runSpacing: 8.v,
                        children: [
                          if (categoryName != null &&
                              categoryName.trim().isNotEmpty)
                            _PreviewStatChip(
                              icon: Icons.category_outlined,
                              label: categoryName.trim(),
                            ),
                          if (downloadsCount != null)
                            _PreviewStatChip(
                              icon: Icons.download_outlined,
                              label: '${'lbl_downloads'.tr}: $downloadsCount',
                            ),
                          if (trendingScore != null)
                            _PreviewStatChip(
                              icon: Icons.trending_up_rounded,
                              label:
                                  '${'lbl_trending_score'.tr}: $trendingScore',
                            ),
                        ],
                      ),
                    ],
                    if (showLegacyDetails) ...[
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
                          borderRadius: BorderRadius.circular(
                            AppDs.radiusMd.adaptSize,
                          ),
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
                    if (enableRedesign) ...[
                      SizedBox(
                        height: 52.v,
                        child: FilledButton.icon(
                          onPressed: isWorking || designId == null
                              ? null
                              : () async {
                                  if (isWorking) return;
                                  setState(() => isWorking = true);
                                  Navigator.of(context).pop();
                                  await openDesignForRedesign(
                                    parentContext,
                                    designId: designId,
                                    cloneBeforeOpening: cloneBeforeRedesign,
                                  );
                                },
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          label: Text('lbl_redesign'.tr),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            textStyle: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDs.space3.v),
                    ],
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
                                            ? 'msg_added_to_favorites'.tr
                                            : 'msg_removed_from_favorites'.tr,
                                      );
                                    }),
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                              ),
                              label: Text(
                                isFavorite
                                    ? 'lbl_unfavorite'.tr
                                    : 'lbl_favorite'.tr,
                              ),
                            ),
                          ),
                          SizedBox(width: AppDs.space3.h),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: (!canCallApi || isWorking)
                                  ? null
                                  : () => run(() async {
                                      final repo =
                                          DesignInteractionRepository();
                                      final res = await repo.recordDownload(
                                        designId,
                                      );
                                      if (res is DesignInteractionFailure) {
                                        toast(res.message);
                                        return;
                                      }
                                      if (!designPreviewIsNetworkUrl(
                                        imageRef,
                                      )) {
                                        toast(
                                          'msg_download_link_unavailable'.tr,
                                        );
                                        return;
                                      }
                                      final uri = Uri.parse(imageRef.trim());
                                      try {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (_) {}
                                    }),
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 20,
                              ),
                              label: Text('lbl_download'.tr),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDs.space3.v),
                      if (showRemoveBackground)
                        FilledButton.tonalIcon(
                          onPressed: (!canCallApi || isWorking)
                              ? null
                              : () => run(() async {
                                  final allowed = await ensureCanSpendCoins(
                                    context: context,
                                    feature: WalletFeatureCost.removeBackground,
                                  );
                                  if (!allowed) return;
                                  final repo = DesignInteractionRepository();
                                  final res = await repo.removeBackground(
                                    designId,
                                  );
                                  if (res is DesignInteractionFailure) {
                                    toast(res.message);
                                    return;
                                  }
                                  if (context.mounted) {
                                    context
                                        .read<WalletBloc>()
                                        .add(const WalletRefreshEvent());
                                  }
                                  toast('msg_background_removal_requested'.tr);
                                }),
                          icon: const Icon(
                            Icons.auto_fix_high_outlined,
                            size: 20,
                          ),
                          label: Text('lbl_remove_bg'.tr),
                        ),
                      if (showRemoveBackground)
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
                        if (!enableRedesign) ...[
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
                      ],
                    ),
                    SizedBox(height: AppDs.space2.v),
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

class _PreviewStatChip extends StatelessWidget {
  const _PreviewStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.v),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.adaptSize),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.adaptSize, color: theme.colorScheme.primary),
          SizedBox(width: 6.h),
          Text(
            label,
            style: AppDs.sheetCaption(
              theme,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
