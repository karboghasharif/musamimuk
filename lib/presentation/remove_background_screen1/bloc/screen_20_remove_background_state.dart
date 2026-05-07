part of 'screen_20_remove_background_bloc.dart';

/// Represents the state of Screen20RemoveBackground in the application.// ignore_for_file: must_be_immutable
class Screen20RemoveBackgroundState extends Equatable {
  Screen20RemoveBackgroundState({this.screen20RemoveBackgroundModelObj});
  final Screen20RemoveBackgroundModel? screen20RemoveBackgroundModelObj;
  @override
  List<Object?> get props => [screen20RemoveBackgroundModelObj];
  Screen20RemoveBackgroundState copyWith(
      {Screen20RemoveBackgroundModel? screen20RemoveBackgroundModelObj}) {
    return Screen20RemoveBackgroundState(
      screen20RemoveBackgroundModelObj: screen20RemoveBackgroundModelObj ??
          this.screen20RemoveBackgroundModelObj,
    );
  }
}
