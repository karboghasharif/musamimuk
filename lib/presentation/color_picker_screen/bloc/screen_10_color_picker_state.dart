part of 'screen_10_color_picker_bloc.dart';

class Screen10ColorPickerState extends Equatable {
  Screen10ColorPickerState({this.screen10ColorPickerModelObj});
  Screen10ColorPickerModel? screen10ColorPickerModelObj;
  @override
  List<Object?> get props => [screen10ColorPickerModelObj];
  Screen10ColorPickerState copyWith(
      {Screen10ColorPickerModel? screen10ColorPickerModelObj}) {
    return Screen10ColorPickerState(
      screen10ColorPickerModelObj:
          screen10ColorPickerModelObj ?? this.screen10ColorPickerModelObj,
    );
  }
}
