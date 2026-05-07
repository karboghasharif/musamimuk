import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/design_preview_sheet.dart';
import '../models/listsection_item_model.dart';

class ListsectionItemWidget extends StatelessWidget {
  ListsectionItemWidget(this.listsectionItemModelObj, {super.key});
  final ListsectionItemModel listsectionItemModelObj;

  void _openPreview(BuildContext context) {
    final path = listsectionItemModelObj.rectangle ?? '';
    if (path.isEmpty) return;
    final designId = int.tryParse((listsectionItemModelObj.id ?? '').trim());
    final tier = listsectionItemModelObj.tier;
    final tierLine = (tier != null && tier.trim().isNotEmpty)
        ? 'Tier: ${_displayTier(tier)}'
        : null;
    final featuredLine =
        listsectionItemModelObj.isFeatured ? 'lbl_featured'.tr : null;
    final subtitleParts = <String>[
      if (listsectionItemModelObj.id?.isNotEmpty == true)
        'ID: ${listsectionItemModelObj.id}',
      if (featuredLine != null) featuredLine,
      if (tierLine != null) tierLine,
    ];
    showDesignPreviewSheet(
      context,
      imageRef: path,
      designId: designId,
      title: listsectionItemModelObj.name?.trim().isNotEmpty == true
          ? listsectionItemModelObj.name
          : 'lbl_online_designs'.tr,
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' · '),
      detailsBody: listsectionItemModelObj.previewDetails,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(6.h),
        child: SizedBox(
          width: 114.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomImageView(
                imagePath: listsectionItemModelObj.rectangle,
                height: 110.v,
                width: 114.h,
                radius: BorderRadius.circular(6.h),
              ),
              if (isPremiumDesignTier(listsectionItemModelObj.tier))
                Positioned(
                  top: 110.v * 0.03,
                  left: 2.adaptSize,
                  right: 28.adaptSize,
                  height: 110.v * 0.34,
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
              if (listsectionItemModelObj.tier != null &&
                  listsectionItemModelObj.tier!.trim().isNotEmpty &&
                  !isPremiumDesignTier(listsectionItemModelObj.tier))
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
                        _displayTier(listsectionItemModelObj.tier!),
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
