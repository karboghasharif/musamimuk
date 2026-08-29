import '../../../core/app_export.dart';

class PlaylistItemModel {
  PlaylistItemModel({
    this.image,
    this.text1,
    this.text2,
    this.id,
    this.isPrivate = false,
    this.visibility,
    this.designDataRaw,
    this.width,
    this.height,
    this.isLocal = false,
  }) {
    image = image ?? ImageConstant.imgRectangle5591106x115;
    text1 = text1 ?? "Untitled";
    text2 = text2 ?? "Oct 14, 2023, 6:33 PM";
    id = id ?? "";
  }

  String? image;
  String? text1;
  String? text2;
  String? id;
  bool isPrivate;
  String? visibility;
  String? designDataRaw;
  int? width;
  int? height;
  bool isLocal;
}
