import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../core/app_export.dart';
import '../../../../data/models/online_asset_models.dart';
import 'online_asset_browser_sheet.dart';

/// First sheet: pick an online asset category / provider.
Future<T?> showOnlineAssetsCategorySheet<T>({
  required BuildContext context,
  required GlobalKey<ProImageEditorState>? editorKey,
  bool pickOnly = false,
  VoidCallback? onAssetAdded,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.72,
      child: OnlineAssetsCategorySheet(
        editorKey: editorKey,
        pickOnly: pickOnly,
        onAssetAdded: onAssetAdded,
      ),
    ),
  );
}

class OnlineAssetsCategorySheet extends StatelessWidget {
  const OnlineAssetsCategorySheet({
    super.key,
    required this.editorKey,
    this.pickOnly = false,
    this.onAssetAdded,
  });

  final GlobalKey<ProImageEditorState>? editorKey;
  final bool pickOnly;
  final VoidCallback? onAssetAdded;

  static const _providers = OnlineAssetProvider.values;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDs.surfaceBase,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDs.radiusSheet.adaptSize),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 10.v),
            Container(
              width: 40.h,
              height: 4.v,
              decoration: BoxDecoration(
                color: AppDs.sheetBorderSubtle(),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 16.v, 8.h, 8.v),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'lbl_online_assets'.tr,
                      style: TextStyle(
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.w700,
                        color: AppDs.textOnDarkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppDs.textOnDarkSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 0, 16.h, 12.v),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'lbl_online_assets_hint'.tr,
                  style: TextStyle(
                    fontSize: 13.fSize,
                    color: AppDs.textOnDarkSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(12.h, 0, 12.h, 16.v),
                itemCount: _providers.length,
                separatorBuilder: (_, _) => SizedBox(height: 8.v),
                itemBuilder: (context, index) {
                  final provider = _providers[index];
                  return Material(
                    color: AppDs.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final result =
                            await showOnlineAssetBrowserSheet<Object?>(
                          context: context,
                          editorKey: editorKey,
                          provider: provider,
                          pickOnly: pickOnly,
                          onAssetAdded: onAssetAdded,
                        );
                        if (result == null || !context.mounted) return;
                        // Pick-only returns the layer; otherwise `true` means
                        // the asset was placed, so close this sheet too.
                        Navigator.of(context).pop(pickOnly ? result : null);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.h,
                          vertical: 14.v,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44.adaptSize,
                              height: 44.adaptSize,
                              decoration: BoxDecoration(
                                color: AppDs.surfaceBase,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                provider.icon,
                                color: AppDs.textOnDarkPrimary,
                              ),
                            ),
                            SizedBox(width: 12.h),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.titleKey.tr,
                                    style: TextStyle(
                                      fontSize: 15.fSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppDs.textOnDarkPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.v),
                                  Text(
                                    provider.subtitleKey.tr,
                                    style: TextStyle(
                                      fontSize: 12.fSize,
                                      color: AppDs.textOnDarkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppDs.textOnDarkSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
