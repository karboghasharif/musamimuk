part of 'screen_15_menu_bar_bloc.dart';

class Screen15MenuBarState extends Equatable {
  Screen15MenuBarState({this.screen15MenuBarModelObj});
  Screen15MenuBarModel? screen15MenuBarModelObj;
  @override
  List<Object?> get props => [screen15MenuBarModelObj];
  Screen15MenuBarState copyWith(
      {Screen15MenuBarModel? screen15MenuBarModelObj}) {
    return Screen15MenuBarState(
      screen15MenuBarModelObj:
          screen15MenuBarModelObj ?? this.screen15MenuBarModelObj,
    );
  }
}
