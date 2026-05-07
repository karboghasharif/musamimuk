import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/design_preview_sheet.dart';
import '../models/certificatedesign_item_model.dart'; // ignore: must_be_immutable// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable

class CertificatedesignItemWidget extends StatelessWidget {
  const CertificatedesignItemWidget(this.certificatedesignItemModelObj,
      {super.key, this.onTap});
  final CertificatedesignItemModel certificatedesignItemModelObj;
  final VoidCallback? onTap;

  void _openPreview(BuildContext context) {
    final path = certificatedesignItemModelObj.image ?? '';
    if (path.isEmpty) {
      onTap?.call();
      return;
    }
    showDesignPreviewSheet(
      context,
      imageRef: path,
      title: certificatedesignItemModelObj.certificateText?.trim().isNotEmpty ==
              true
          ? certificatedesignItemModelObj.certificateText
          : "msg_certificate_design".tr,
      subtitle:
          certificatedesignItemModelObj.designsText?.trim().isNotEmpty == true
              ? certificatedesignItemModelObj.designsText
              : null,
      footer: onTap == null
          ? null
          : FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onTap!();
              },
              child: Text("lbl_view_contest".tr),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPreview(context),
      child: SizedBox(
        height: 303.v,
        width: 377.h,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 61.h,
                  vertical: 11.v,
                ),
                decoration: AppDecoration.fillGray80001.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 41.v),
                    Text(
                      certificatedesignItemModelObj.certificateText ?? '',
                      style: CustomTextStyles.titleMediumPoppins16,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.v),
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        certificatedesignItemModelObj.designsText ?? '',
                        style: CustomTextStyles.bodySmallOnPrimaryContainer,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 241.v,
                width: 377.h,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    CustomImageView(
                      imagePath: certificatedesignItemModelObj.image,
                      height: 241.v,
                      width: 377.h,
                      radius: BorderRadius.circular(12.h),
                      alignment: Alignment.center,
                    ),
                    CustomElevatedButton(
                      height: 32.v,
                      width: 154.h,
                      text: "msg_result_announced".tr,
                      buttonStyle: CustomButtonStyles.fillPrimaryBR16,
                      buttonTextStyle: theme.textTheme.labelLarge!,
                      alignment: Alignment.topLeft,
                    )
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
