import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../models/gridgallery_pic_item_model.dart';

class GridgalleryPicItemWidget extends StatelessWidget {
  const GridgalleryPicItemWidget(
    this.gridgalleryPicItemModelObj, {
    super.key,
    this.onTapColumngallery,
  });
  final GridgalleryPicItemModel gridgalleryPicItemModelObj;
  final VoidCallback? onTapColumngallery;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTapColumngallery?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
        decoration: AppDecoration.fillYellow.copyWith(
          borderRadius: BorderRadiusStyle.roundedBorder10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            gridgalleryPicItemModelObj.icon != null
                ? Icon(
                    gridgalleryPicItemModelObj.icon,
                    size: 26.adaptSize,
                    color: appTheme.blueGray90004,
                  )
                : CustomImageView(
                    imagePath: gridgalleryPicItemModelObj.galleryPicOne!,
                    height: 26.adaptSize,
                    width: 26.adaptSize,
                  ),
            SizedBox(height: 6.v),
            Flexible(
              child: Text(
                gridgalleryPicItemModelObj.gallerypic!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CustomTextStyles.bodySmallBluegray90004.copyWith(
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
