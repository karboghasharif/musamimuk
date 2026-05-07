part of 'screen_5_add_shape_bloc.dart';

/// Represents the state of Screen5AddShape in the application.// ignore_for_file: must_be_immutable
class Screen5AddShapeState extends Equatable {
  Screen5AddShapeState(
      {this.searchController,
      this.otpController,
      this.screen5AddShapeModelObj});
  TextEditingController? searchController;
  TextEditingController? otpController;
  Screen5AddShapeModel? screen5AddShapeModelObj;
  @override
  List<Object?> get props =>
      [searchController, otpController, screen5AddShapeModelObj];
  Screen5AddShapeState copyWith({
    TextEditingController? searchController,
    TextEditingController? otpController,
    Screen5AddShapeModel? screen5AddShapeModelObj,
  }) {
    return Screen5AddShapeState(
      searchController: searchController ?? this.searchController,
      otpController: otpController ?? this.otpController,
      screen5AddShapeModelObj:
          screen5AddShapeModelObj ?? this.screen5AddShapeModelObj,
    );
  }
}
