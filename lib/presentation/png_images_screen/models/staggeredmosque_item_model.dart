import '../../../core/app_export.dart';

/// This class is used in the [staggeredmosque_item_widget] screen.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class StaggeredmosqueItemModel {
  StaggeredmosqueItemModel({this.mosque, this.id}) {
    mosque = mosque ?? ImageConstant.imgMosque1;
    id = id ?? "";
  }
  String? mosque;
  String? id;
}
