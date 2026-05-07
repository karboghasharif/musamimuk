part of 'screen_19_remove_background_bloc.dart';

class Screen19RemoveBackgroundState extends Equatable {
  Screen19RemoveBackgroundState({this.screen19RemoveBackgroundModelObj});
  final Screen19RemoveBackgroundModel? screen19RemoveBackgroundModelObj;
  @override
  List<Object?> get props => [screen19RemoveBackgroundModelObj];
  Screen19RemoveBackgroundState copyWith(
      {Screen19RemoveBackgroundModel? screen19RemoveBackgroundModelObj}) {
    return Screen19RemoveBackgroundState(
      screen19RemoveBackgroundModelObj: screen19RemoveBackgroundModelObj ??
          this.screen19RemoveBackgroundModelObj,
    );
  }
}
