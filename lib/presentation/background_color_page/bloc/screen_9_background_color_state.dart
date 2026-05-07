part of 'screen_9_background_color_bloc.dart';

/// Represents the state of Screen9BackgroundColor in the application.// ignore_for_file: must_be_immutable
class Screen9BackgroundColorState extends Equatable {
  Screen9BackgroundColorState(
      {this.edittextController,
      this.edittextoneController,
      this.edittexttwoController,
      this.edittextthreeController,
      this.edittextfourController,
      this.screen9BackgroundColorModelObj});
  TextEditingController? edittextController;
  TextEditingController? edittextoneController;
  TextEditingController? edittexttwoController;
  TextEditingController? edittextthreeController;
  TextEditingController? edittextfourController;
  Screen9BackgroundColorModel? screen9BackgroundColorModelObj;
  @override
  List<Object?> get props => [
        edittextController,
        edittextoneController,
        edittexttwoController,
        edittextthreeController,
        edittextfourController,
        screen9BackgroundColorModelObj
      ];
  Screen9BackgroundColorState copyWith({
    TextEditingController? edittextController,
    TextEditingController? edittextoneController,
    TextEditingController? edittexttwoController,
    TextEditingController? edittextthreeController,
    TextEditingController? edittextfourController,
    Screen9BackgroundColorModel? screen9BackgroundColorModelObj,
  }) {
    return Screen9BackgroundColorState(
      edittextController: edittextController ?? this.edittextController,
      edittextoneController:
          edittextoneController ?? this.edittextoneController,
      edittexttwoController:
          edittexttwoController ?? this.edittexttwoController,
      edittextthreeController:
          edittextthreeController ?? this.edittextthreeController,
      edittextfourController:
          edittextfourController ?? this.edittextfourController,
      screen9BackgroundColorModelObj:
          screen9BackgroundColorModelObj ?? this.screen9BackgroundColorModelObj,
    );
  }
}
