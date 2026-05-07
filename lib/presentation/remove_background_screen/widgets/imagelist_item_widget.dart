import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/imagelist_item_model.dart';

class ImagelistItemWidget extends StatelessWidget {
  ImagelistItemWidget(this.imagelistItemModelObj, {super.key});
  final ImagelistItemModel imagelistItemModelObj;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 61.h,
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomImageView(
          imagePath: imagelistItemModelObj.rectangle!,
          height: 61.adaptSize,
          width: 61.adaptSize,
          radius: BorderRadius.circular(
            8.h,
          ),
        ),
      ),
    );
  }
}
