import 'package:equatable/equatable.dart';

import '../../../data/models/selectionPopupModel/selection_popup_model.dart';
import 'gridgallery_pic_item_model.dart';

// This class defines the variables used in the [screen_3_add_new_screen],/// and is typically used to hold data that is passed between different parts of the application.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class AddNewModel extends Equatable {
  const AddNewModel(
      {this.gridgalleryPicItemList = const [],
      this.dropdownItemList = const []});
  final List<GridgalleryPicItemModel> gridgalleryPicItemList;

  final List<SelectionPopupModel>? dropdownItemList;
  AddNewModel copyWith(
      {List<GridgalleryPicItemModel>? gridgalleryPicItemList}) {
    return AddNewModel(
      gridgalleryPicItemList:
          gridgalleryPicItemList ?? this.gridgalleryPicItemList,
    );
  }

  @override
  List<Object?> get props => [gridgalleryPicItemList];
}
