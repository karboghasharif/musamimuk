import 'package:equatable/equatable.dart';
import 'imagelist_item_model.dart';

class Screen19RemoveBackgroundModel extends Equatable {
  Screen19RemoveBackgroundModel({this.imagelistItemList = const []});
  final List<ImagelistItemModel> imagelistItemList;
  Screen19RemoveBackgroundModel copyWith(
      {List<ImagelistItemModel>? imagelistItemList}) {
    return Screen19RemoveBackgroundModel(
      imagelistItemList: imagelistItemList ?? this.imagelistItemList,
    );
  }

  @override
  List<Object?> get props => [imagelistItemList];
}
