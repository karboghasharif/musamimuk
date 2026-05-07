part of 'screen_21_remove_background_bloc.dart';

/// Represents the state of Screen21RemoveBackground in the application.// ignore_for_file: must_be_immutable
class Screen21RemoveBackgroundState extends Equatable {
  Screen21RemoveBackgroundState({this.screen21RemoveBackgroundModelObj});
  final Screen21RemoveBackgroundModel? screen21RemoveBackgroundModelObj;
  @override
  List<Object?> get props => [screen21RemoveBackgroundModelObj];
  Screen21RemoveBackgroundState copyWith(
      {Screen21RemoveBackgroundModel? screen21RemoveBackgroundModelObj}) {
    return Screen21RemoveBackgroundState(
      screen21RemoveBackgroundModelObj: screen21RemoveBackgroundModelObj ??
          this.screen21RemoveBackgroundModelObj,
    );
  }
}
