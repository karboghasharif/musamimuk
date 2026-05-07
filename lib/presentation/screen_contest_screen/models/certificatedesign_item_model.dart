import '../../../core/app_export.dart';

/// This class is used in the [certificatedesign_item_widget] screen.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class CertificatedesignItemModel {
  CertificatedesignItemModel({
    this.certificateText,
    this.designsText,
    this.image,
    this.id,
    this.contestJson,
  }) {
    certificateText = certificateText ?? "Certificate Design Competition";
    designsText = designsText ?? "44 Designs Submitted";
    image = image ?? ImageConstant.imgRectangle5591;
    id = id ?? "";
  }
  String? certificateText;
  String? designsText;
  String? image;
  String? id;
  /// Raw fields from [GET /api/contest/list] for the detail screen (no GET /api/contest/:id).
  Map<String, dynamic>? contestJson;
}
