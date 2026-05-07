import 'package:equatable/equatable.dart';
import 'listrectangle_item_model.dart';

/// This class defines the variables used in the [screen_20_remove_background_screen],/// and is typically used to hold data that is passed between different parts of the application.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class Screen20RemoveBackgroundModel extends Equatable {
  Screen20RemoveBackgroundModel({this.listrectangleItemList = const []});
  final List<ListrectangleItemModel> listrectangleItemList;
  Screen20RemoveBackgroundModel copyWith(
      {List<ListrectangleItemModel>? listrectangleItemList}) {
    return Screen20RemoveBackgroundModel(
      listrectangleItemList:
          listrectangleItemList ?? this.listrectangleItemList,
    );
  }

  @override
  List<Object?> get props => [listrectangleItemList];
}
