import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/design_preview_sheet.dart';
import '../models/rectanglelistsection_item_model.dart';

class RectanglelistsectionItemWidget extends StatelessWidget {
  RectanglelistsectionItemWidget(
    this.rectanglelistsectionItemModelObj, {
    super.key,
    this.cellWidth,
    this.imageHeight,
  });

  final RectanglelistsectionItemModel rectanglelistsectionItemModelObj;
  /// Defaults to `114.h` (e.g. hero row uses a taller [imageHeight]).
  final double? cellWidth;
  /// Defaults to `110.v`.
  final double? imageHeight;

  void _openPreview(BuildContext context) {
    final path = rectanglelistsectionItemModelObj.rectangle ?? '';
    if (path.isEmpty) return;
    final designId =
        int.tryParse((rectanglelistsectionItemModelObj.id ?? '').trim());
    final tier = rectanglelistsectionItemModelObj.tier;
    final tierLine = (tier != null && tier.trim().isNotEmpty)
        ? 'Tier: ${_displayTier(tier)}'
        : null;
    final featuredLine = rectanglelistsectionItemModelObj.isFeatured
        ? 'lbl_featured'.tr
        : null;
    final subtitleParts = <String>[
      if (rectanglelistsectionItemModelObj.id?.isNotEmpty == true)
        'ID: ${rectanglelistsectionItemModelObj.id}',
      if (featuredLine != null) featuredLine,
      if (tierLine != null) tierLine,
    ];
    showDesignPreviewSheet(
      context,
      imageRef: path,
      designId: designId,
      title: rectanglelistsectionItemModelObj.name?.trim().isNotEmpty == true
          ? rectanglelistsectionItemModelObj.name
          : 'lbl_online_designs'.tr,
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' · '),
      detailsBody: rectanglelistsectionItemModelObj.previewDetails,
    );
  }

  static String _displayTier(String raw) {
    return raw
        .trim()
        .split('_')
        .where((w) => w.isNotEmpty)
        .map(
          (w) =>
              '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final width = cellWidth ?? 114.h;
    final height = imageHeight ?? 110.v;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(6.h),
        child: SizedBox(
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomImageView(
                imagePath: rectanglelistsectionItemModelObj.rectangle,
                height: height,
                width: width,
                radius: BorderRadius.circular(6.h),
              ),
              if (isPremiumDesignTier(rectanglelistsectionItemModelObj.tier))
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
                  top: 4.adaptSize,
                  left: 4.adaptSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      borderRadius: BorderRadius.circular(4.adaptSize),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.adaptSize,
                        vertical: 2.adaptSize,
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
              if (rectanglelistsectionItemModelObj.tier != null &&
                  rectanglelistsectionItemModelObj.tier!.trim().isNotEmpty &&
                  !isPremiumDesignTier(rectanglelistsectionItemModelObj.tier))
                Positioned(
                  left: 4.adaptSize,
                  bottom: 4.adaptSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4.adaptSize),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.adaptSize,
                        vertical: 2.adaptSize,
                      ),
                      child: Text(
                        _displayTier(rectanglelistsectionItemModelObj.tier!),
                        style: TextStyle(
                          fontSize: 9.adaptSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 4.adaptSize,
                right: 4.adaptSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6.adaptSize),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4.adaptSize),
                    child: Icon(
                      Icons.zoom_in_rounded,
                      size: 16.adaptSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
