import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/design_preview_sheet.dart';
import '../models/rectanglelistsection_item_model.dart';

class RectanglelistsectionItemWidget extends StatelessWidget {
  const RectanglelistsectionItemWidget(
    this.rectanglelistsectionItemModelObj, {
    super.key,
    this.cellWidth,
    this.imageHeight,
  });

  final RectanglelistsectionItemModel rectanglelistsectionItemModelObj;
  final double? cellWidth;
  final double? imageHeight;

  void _openPreview(BuildContext context) {
    final path = rectanglelistsectionItemModelObj.rectangle ?? '';
    if (path.isEmpty) return;
    final designId = int.tryParse(
      (rectanglelistsectionItemModelObj.id ?? '').trim(),
    );
    final category = rectanglelistsectionItemModelObj.categoryName?.trim();
    showDesignPreviewSheet(
      context,
      imageRef: path,
      designId: designId,
      showRemoveBackground: false,
      enableRedesign: true,
      cloneBeforeRedesign: true,
      title: rectanglelistsectionItemModelObj.name?.trim().isNotEmpty == true
          ? rectanglelistsectionItemModelObj.name
          : 'lbl_online_designs'.tr,
      subtitle: (category != null && category.isNotEmpty) ? category : null,
      categoryName: category,
      downloadsCount: rectanglelistsectionItemModelObj.downloadsCount,
      trendingScore: rectanglelistsectionItemModelObj.trendingScore,
      designHistoryJson: rectanglelistsectionItemModelObj.designDataRaw,
      designWidth: rectanglelistsectionItemModelObj.width,
      designHeight: rectanglelistsectionItemModelObj.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = cellWidth ?? 132.h;
    final height = imageHeight ?? 120.v;
    final name = rectanglelistsectionItemModelObj.name?.trim() ?? '';
    final category =
        rectanglelistsectionItemModelObj.categoryName?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(12.h),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomImageView(
                    imagePath: rectanglelistsectionItemModelObj.rectangle,
                    height: height,
                    width: width,
                    radius: BorderRadius.circular(12.h),
                    fit: BoxFit.cover,
                  ),
                  if (isPremiumDesignTier(
                    rectanglelistsectionItemModelObj.tier,
                  ))
                    Positioned(
                      top: height * 0.03,
                      left: 2.adaptSize,
                      right: 28.adaptSize,
                      height: height * 0.34,
                      child: IgnorePointer(
                        child: Image.asset(
                          ImageConstant.imgPremiumBadgeRemovebg,
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  if (rectanglelistsectionItemModelObj.isFeatured)
                    Positioned(
                      top: 6.adaptSize,
                      left: 6.adaptSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800,
                          borderRadius: BorderRadius.circular(6.adaptSize),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.adaptSize,
                            vertical: 3.adaptSize,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 12.adaptSize,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2.adaptSize),
                              Text(
                                'lbl_featured'.tr,
                                style: TextStyle(
                                  fontSize: 9.adaptSize,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6.adaptSize,
                    right: 6.adaptSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8.adaptSize),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(5.adaptSize),
                        child: Icon(
                          Icons.zoom_in_rounded,
                          size: 14.adaptSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (name.isNotEmpty) ...[
                SizedBox(height: 6.v),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (category.isNotEmpty) ...[
                SizedBox(height: 2.v),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
