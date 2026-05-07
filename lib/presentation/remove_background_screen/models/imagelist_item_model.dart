import '../../../core/app_export.dart';

class ImagelistItemModel {
  ImagelistItemModel({this.rectangle, this.id}) {
    rectangle = rectangle ?? ImageConstant.imgRectangle5594;
    id = id ?? "";
  }
  String? rectangle;
  String? id;
}
