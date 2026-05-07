import '../../../core/app_export.dart';

class RectanglelistsectionItemModel {
  RectanglelistsectionItemModel({
    this.rectangle,
    this.id,
    this.name,
    this.isFeatured = false,
    this.tier,
    this.previewDetails,
  }) {
    rectangle = rectangle ?? ImageConstant.imgRectangle5582;
    id = id ?? "";
  }
  String? rectangle;
  String? id;
  String? name;
  bool isFeatured;
  String? tier;
  /// Full catalog details for the preview sheet (admin / rich API).
  String? previewDetails;
}
