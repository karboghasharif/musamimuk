import 'package:equatable/equatable.dart';
import 'userprofile_item_model.dart';

/// This class defines the variables used in the [screen_contesttwo_screen],/// and is typically used to hold data that is passed between different parts of the application.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class ScreenContesttwoModel extends Equatable {
  const ScreenContesttwoModel({this.userprofileItemList = const []});
  final List<UserprofileItemModel> userprofileItemList;
  ScreenContesttwoModel copyWith(
      {List<UserprofileItemModel>? userprofileItemList}) {
    return ScreenContesttwoModel(
      userprofileItemList: userprofileItemList ?? this.userprofileItemList,
    );
  }

  @override
  List<Object?> get props => [userprofileItemList];
}
