// This class is used in the [listportrait_item_widget] screen.// ignore_for_file: must_be_immutable
class ListportraitItemModel {
  ListportraitItemModel({this.portrait, this.twoThree, this.id}) {
    portrait = portrait ?? "Portrait";
    twoThree = twoThree ?? "2:3";
    id = id ?? "";
  }
  String? portrait;
  String? twoThree;
  String? id;
}
