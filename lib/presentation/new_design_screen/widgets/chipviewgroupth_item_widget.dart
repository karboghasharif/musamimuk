import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/chipviewgroupth_item_model.dart';

// ignore: must_be_immutable// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class ChipviewgroupthItemWidget extends StatelessWidget {
  ChipviewgroupthItemWidget(this.chipviewgroupthItemModelObj,
      {super.key, this.onSelectedChipView});
  ChipviewgroupthItemModel chipviewgroupthItemModelObj;
  Function(bool)? onSelectedChipView;
  @override
  Widget build(BuildContext context) {
    return RawChip(
      padding: EdgeInsets.symmetric(
        horizontal: 30.h,
        vertical: 15.v,
      ),
      showCheckmark: false,
      labelPadding: EdgeInsets.zero,
      label: Text(
        chipviewgroupthItemModelObj.groupthirty!,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 13.442816734313965.fSize,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
      ),
      selected: (chipviewgroupthItemModelObj.isSelected ?? false),
      backgroundColor: appTheme.blueGray90001,
      selectedColor: appTheme.blueGray90001,
      shape: (chipviewgroupthItemModelObj.isSelected ?? false)
          ? RoundedRectangleBorder(
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.6),
                width: 1.h,
              ),
              borderRadius: BorderRadius.circular(
                7.h,
              ))
          : RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.circular(
                7.h,
              ),
            ),
      onSelected: (value) {
        onSelectedChipView?.call(value);
      },
    );
  }
}
