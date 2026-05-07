import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/userprofile_item_model.dart';
// ignore: must_be_immutable// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable

class UserprofileItemWidget extends StatelessWidget {
  const UserprofileItemWidget(this.userprofileItemModelObj, {super.key});
  final UserprofileItemModel userprofileItemModelObj;
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: appTheme.blueGray700,
          width: 1.h,
        ),
        borderRadius: BorderRadiusStyle.roundedBorder22,
      ),
      child: Container(
        height: 337.v,
        width: 401.h,
        decoration: AppDecoration.outlineBlueGray.copyWith(
          borderRadius: BorderRadiusStyle.roundedBorder22,
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CustomImageView(
              imagePath: userprofileItemModelObj.userImage,
              height: 258.v,
              width: 398.h,
              radius: BorderRadius.only(
                topLeft: Radius.circular(23.h),
                topRight: Radius.circular(18.h),
              ),
              alignment: Alignment.topCenter,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(31.h, 212.v, 22.h, 29.v),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 72.v),
                      child: Text(
                        userprofileItemModelObj.username ?? '',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (userprofileItemModelObj.userImage1 != null)
                      CustomImageView(
                        imagePath: userprofileItemModelObj.userImage1,
                        height: 93.adaptSize,
                        width: 93.adaptSize,
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
