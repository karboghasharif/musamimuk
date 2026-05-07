import 'package:equatable/equatable.dart';
import '../../../data/models/selectionPopupModel/selection_popup_model.dart';

/// This class defines the variables used in the [screen_7_resize_paper_screen],/// and is typically used to hold data that is passed between different parts of the application.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class Screen7ResizePaperModel extends Equatable {
  Screen7ResizePaperModel({this.dropdownItemList = const []});
  List<SelectionPopupModel> dropdownItemList;
  Screen7ResizePaperModel copyWith(
      {List<SelectionPopupModel>? dropdownItemList}) {
    return Screen7ResizePaperModel(
      dropdownItemList: dropdownItemList ?? this.dropdownItemList,
    );
  }

  @override
  List<Object?> get props => [dropdownItemList];
}
