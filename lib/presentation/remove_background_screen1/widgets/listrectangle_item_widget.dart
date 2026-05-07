import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/listrectangle_item_model.dart'; // ignore: must_be_immutable// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable

class ListrectangleItemWidget extends StatelessWidget {
  ListrectangleItemWidget(this.listrectangleItemModelObj, {super.key});
  final ListrectangleItemModel listrectangleItemModelObj;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 61.h,
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomImageView(
          imagePath: listrectangleItemModelObj.rectangle!,
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
