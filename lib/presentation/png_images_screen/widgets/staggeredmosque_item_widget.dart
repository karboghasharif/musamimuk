import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/staggeredmosque_item_model.dart';

class StaggeredmosqueItemWidget extends StatelessWidget {
  StaggeredmosqueItemWidget(this.staggeredmosqueItemModelObj, {super.key});
  StaggeredmosqueItemModel staggeredmosqueItemModelObj;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CustomImageView(
        imagePath: staggeredmosqueItemModelObj.mosque!,
        height: 84.adaptSize,
        width: 84.adaptSize,
      ),
    );
  }
}
