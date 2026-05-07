part of 'screen_twentythree_bloc.dart';

/// Represents the state of ScreenTwentythree in the application.// ignore_for_file: must_be_immutable
class ScreenTwentythreeState extends Equatable {
  const ScreenTwentythreeState({this.screenTwentythreeModelObj});
  final ScreenTwentythreeModel? screenTwentythreeModelObj;
  @override
  List<Object?> get props => [screenTwentythreeModelObj];
  ScreenTwentythreeState copyWith(
      {ScreenTwentythreeModel? screenTwentythreeModelObj}) {
    return ScreenTwentythreeState(
      screenTwentythreeModelObj:
          screenTwentythreeModelObj ?? this.screenTwentythreeModelObj,
    );
  }
}
