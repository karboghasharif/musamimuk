import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/design_preview_sheet.dart';
import '../models/playlist_item_model.dart';

class PlaylistItemWidget extends StatelessWidget {
  PlaylistItemWidget(this.playlistItemModelObj, {super.key});
  final PlaylistItemModel playlistItemModelObj;

  void _openPreview(BuildContext context) {
    final path = playlistItemModelObj.image ?? '';
    if (path.isEmpty) return;
    final designId = int.tryParse((playlistItemModelObj.id ?? '').trim());
    showDesignPreviewSheet(
      context,
      imageRef: path,
      designId: designId,
      title: playlistItemModelObj.text1?.trim().isNotEmpty == true
          ? playlistItemModelObj.text1
          : "lbl_my_designs".tr,
      subtitle: playlistItemModelObj.text2?.trim().isNotEmpty == true
          ? playlistItemModelObj.text2
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onTap: () => _openPreview(context),
              borderRadius: BorderRadius.circular(12.h),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  CustomImageView(
                    imagePath: playlistItemModelObj.image,
                    height: 106.v,
                    width: 115.h,
                    radius: BorderRadius.circular(12.h),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6.adaptSize),
                    child: DecoratedBox(
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
