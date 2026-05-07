import 'package:equatable/equatable.dart';
import 'staggeredmosque_item_model.dart';

class Screen6AddPngImagesModel extends Equatable {
  Screen6AddPngImagesModel({this.staggeredmosqueItemList = const []});
  List<StaggeredmosqueItemModel> staggeredmosqueItemList;
  Screen6AddPngImagesModel copyWith(
      {List<StaggeredmosqueItemModel>? staggeredmosqueItemList}) {
    return Screen6AddPngImagesModel(
      staggeredmosqueItemList:
          staggeredmosqueItemList ?? this.staggeredmosqueItemList,
    );
  }

  @override
  List<Object?> get props => [staggeredmosqueItemList];
}
