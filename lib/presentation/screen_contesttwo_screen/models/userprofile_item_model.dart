import '../../../core/app_export.dart';

/// This class is used in the [userprofile_item_widget] screen.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class UserprofileItemModel {
  UserprofileItemModel(
      {this.userImage, this.username, this.userImage1, this.id}) {
    userImage = userImage ?? ImageConstant.imgImage6;
    username = username ?? "Robin Dias";
    userImage1 = userImage1 ?? ImageConstant.img2ndPlace1;
    id = id ?? "";
  }
  String? userImage;
  String? username;
  String? userImage1;
  String? id;
}
