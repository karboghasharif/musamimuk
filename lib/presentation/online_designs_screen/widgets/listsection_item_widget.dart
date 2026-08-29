import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/design_preview_sheet.dart';
import '../models/listsection_item_model.dart';

class ListsectionItemWidget extends StatelessWidget {
  const ListsectionItemWidget(this.listsectionItemModelObj, {super.key});
  final ListsectionItemModel listsectionItemModelObj;

  void _openPreview(BuildContext context) {
    final path = listsectionItemModelObj.rectangle ?? '';
    if (path.isEmpty) return;
    final designId = int.tryParse((listsectionItemModelObj.id ?? '').trim());
    final category = listsectionItemModelObj.categoryName?.trim();
    showDesignPreviewSheet(
      context,
      imageRef: path,
      designId: designId,
      showRemoveBackground: false,
      enableRedesign: true,
      cloneBeforeRedesign: true,
      title: listsectionItemModelObj.name?.trim().isNotEmpty == true
          ? listsectionItemModelObj.name
          : 'lbl_online_designs'.tr,
      subtitle: (category != null && category.isNotEmpty) ? category : null,
      categoryName: category,
      downloadsCount: listsectionItemModelObj.downloadsCount,
      trendingScore: listsectionItemModelObj.trendingScore,
      designHistoryJson: listsectionItemModelObj.designDataRaw,
      designWidth: listsectionItemModelObj.width,
      designHeight: listsectionItemModelObj.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = listsectionItemModelObj.name?.trim() ?? '';
    final category = listsectionItemModelObj.categoryName?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(12.h),
        child: SizedBox(
          width: 132.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomImageView(
                    imagePath: listsectionItemModelObj.rectangle,
                    height: 120.v,
                    width: 132.h,
                    radius: BorderRadius.circular(12.h),
                    fit: BoxFit.cover,
                  ),
                  if (isPremiumDesignTier(listsectionItemModelObj.tier))
                    Positioned(
                      top: 120.v * 0.03,
                      left: 2.adaptSize,
                      right: 28.adaptSize,
                      height: 120.v * 0.34,
                      child: IgnorePointer(
                        child: Image.asset(
                          ImageConstant.imgPremiumBadgeRemovebg,
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  if (listsectionItemModelObj.isFeatured)
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
