part of 'screen_8_transperant_bg_bloc.dart';

/// Represents the state of Screen8TransperantBg in the application.// ignore_for_file: must_be_immutable
class Screen8TransperantBgState extends Equatable {
  Screen8TransperantBgState({this.screen8TransperantBgModelObj});
  Screen8TransperantBgModel? screen8TransperantBgModelObj;
  @override
  List<Object?> get props => [screen8TransperantBgModelObj];
  Screen8TransperantBgState copyWith(
      {Screen8TransperantBgModel? screen8TransperantBgModelObj}) {
    return Screen8TransperantBgState(
      screen8TransperantBgModelObj:
          screen8TransperantBgModelObj ?? this.screen8TransperantBgModelObj,
    );
  }
}
