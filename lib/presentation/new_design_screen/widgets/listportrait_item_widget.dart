import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/listportrait_item_model.dart';
// ignore: must_be_immutable// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable

class ListportraitItemWidget extends StatelessWidget {
  ListportraitItemWidget(this.listportraitItemModelObj, {super.key});
  ListportraitItemModel listportraitItemModelObj;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 17.h,
          vertical: 15.v,
        ),
        decoration: AppDecoration.fillOnPrimaryContainer.copyWith(
          borderRadius: BorderRadiusStyle.roundedBorder7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 128.v),
            Opacity(
              opacity: 0.54,
              child: Text(
                listportraitItemModelObj.portrait!,
                style: CustomTextStyles.bodyMediumInterBluegray90004,
              ),
            ),
            SizedBox(height: 117.v),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                listportraitItemModelObj.twoThree!,
                style: CustomTextStyles.bodyMediumInterGray90001,
              ),
            )
          ],
        ),
      ),
    );
  }
}
