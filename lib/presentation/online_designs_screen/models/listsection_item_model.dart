import '../../../core/app_export.dart';

class ListsectionItemModel {
  ListsectionItemModel({
    this.rectangle,
    this.id,
    this.name,
    this.isFeatured = false,
    this.tier,
    this.previewDetails,
  }) {
    rectangle = rectangle ?? ImageConstant.imgRectangle5585;
    id = id ?? "";
  }
  String? rectangle;
  String? id;
  String? name;
  bool isFeatured;
  String? tier;
  String? previewDetails;
}
