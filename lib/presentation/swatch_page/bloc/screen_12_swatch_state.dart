part of 'screen_12_swatch_bloc.dart';

class Screen12SwatchState extends Equatable {
  Screen12SwatchState({this.screen12SwatchModelObj});
  Screen12SwatchModel? screen12SwatchModelObj;
  @override
  List<Object?> get props => [screen12SwatchModelObj];
  Screen12SwatchState copyWith({Screen12SwatchModel? screen12SwatchModelObj}) {
    return Screen12SwatchState(
      screen12SwatchModelObj:
          screen12SwatchModelObj ?? this.screen12SwatchModelObj,
    );
  }
}
