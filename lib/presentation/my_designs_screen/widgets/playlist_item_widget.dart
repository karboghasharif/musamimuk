import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../../../widgets/design_preview_sheet.dart';
import '../bloc/screen_18_my_designs_bloc.dart';
import '../models/playlist_item_model.dart';

class PlaylistItemWidget extends StatelessWidget {
  PlaylistItemWidget(
    this.playlistItemModelObj, {
    super.key,
    this.isDeleting = false,
  });
  final PlaylistItemModel playlistItemModelObj;
  final bool isDeleting;

  void _openPreview(BuildContext context) {
    if (playlistItemModelObj.isLocal) {
      _openLocalDesign(context);
      return;
    }
    final path = playlistItemModelObj.image ?? '';
    if (path.isEmpty) return;
    final designId = int.tryParse((playlistItemModelObj.id ?? '').trim());
    showDesignPreviewSheet(
      context,
      imageRef: path,
      designId: designId,
      enableRedesign: true,
      title: playlistItemModelObj.text1?.trim().isNotEmpty == true
          ? playlistItemModelObj.text1
          : "lbl_my_designs".tr,
      subtitle: playlistItemModelObj.text2?.trim().isNotEmpty == true
          ? playlistItemModelObj.text2
          : null,
    );
  }

  Future<void> _openLocalDesign(BuildContext context) async {
    final history = playlistItemModelObj.designDataRaw?.trim() ?? '';
    if (history.isEmpty) {
      showAppToast(
        'msg_local_design_open_failed'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    final w = (playlistItemModelObj.width ?? 1080).toDouble();
    final h = (playlistItemModelObj.height ?? 1080).toDouble();
    await NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
      arguments: <String, dynamic>{
        'width': w,
        'height': h,
        'unit': 'px',
        'presetName': playlistItemModelObj.text1?.trim().isNotEmpty == true
            ? playlistItemModelObj.text1!.trim()
            : 'lbl_local_designs'.tr,
        'designHistoryJson': history,
        'localDesignId': playlistItemModelObj.id,
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (playlistItemModelObj.isLocal) {
      final id = (playlistItemModelObj.id ?? '').trim();
      if (id.isEmpty) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('msg_delete_design_title'.tr),
            content: Text('msg_delete_local_design_warning'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('lbl_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
                child: Text('lbl_delete'.tr),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !context.mounted) return;
      context.read<Screen18MyDesignsBloc>().add(
            Screen18MyDesignsDeleteLocalEvent(id),
          );
      return;
    }
    final designId = int.tryParse((playlistItemModelObj.id ?? '').trim());
    if (designId == null) {
      showAppToast(
        'msg_design_delete_failed'.tr,
        type: ToastificationType.error,
      );
      return;
    }

    final name = (playlistItemModelObj.text1 ?? '').trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('msg_delete_design_title'.tr),
          content: Text(
            name.isEmpty
                ? 'msg_delete_design_warning'.tr
                : 'msg_delete_design_warning_named'.tr.replaceAll(
                    '{name}',
                    name,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('lbl_cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text('lbl_delete'.tr),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    context.read<Screen18MyDesignsBloc>().add(
          Screen18MyDesignsDeleteEvent(designId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = playlistItemModelObj.isLocal
        ? (playlistItemModelObj.id ?? '').trim().isNotEmpty
        : int.tryParse((playlistItemModelObj.id ?? '').trim()) != null;

    return SizedBox(
      width: 115.h,
      height: 149.v,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDeleting ? null : () => _openPreview(context),
              onLongPress: (!canDelete || isDeleting)
                  ? null
                  : () => _confirmDelete(context),
              borderRadius: BorderRadius.circular(12.h),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Opacity(
                    opacity: isDeleting ? 0.45 : 1,
                    child: CustomImageView(
                      imagePath: playlistItemModelObj.image,
                      height: 106.v,
                      width: 115.h,
                      radius: BorderRadius.circular(12.h),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(4.adaptSize),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (playlistItemModelObj.isPrivate)
                          Padding(
                            padding: EdgeInsets.only(right: 4.h),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius:
                                    BorderRadius.circular(6.adaptSize),
                              ),
                              child: Icon(
                                Icons.lock_outline,
                                size: 16.adaptSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (canDelete)
                          Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6.adaptSize),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              tooltip: 'lbl_delete'.tr,
                              enabled: !isDeleting,
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDelete(context);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18.adaptSize,
                                        color: theme.colorScheme.error,
                                      ),
                                      SizedBox(width: 8.h),
                                      Text(
                                        'lbl_delete'.tr,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              child: SizedBox(
                                width: 24.adaptSize,
                                height: 24.adaptSize,
                                child: isDeleting
                                    ? Padding(
                                        padding: EdgeInsets.all(4.adaptSize),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.more_vert,
                                        size: 16.adaptSize,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          )
                        else
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6.adaptSize),
                            ),
                            child: Icon(
                              Icons.zoom_in_rounded,
                              size: 16.adaptSize,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6.v),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8.h, right: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    playlistItemModelObj.text1 ?? '',
                    style: CustomTextStyles.bodySmall12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.v),
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      playlistItemModelObj.text2 ?? '',
                      style: CustomTextStyles.bodySmallOnPrimaryContainer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
