part of 'screen_9_background_color_tab_container_bloc.dart';

/// Represents the state of Screen9BackgroundColorTabContainer in the application.// ignore_for_file: must_be_immutable
class Screen9BackgroundColorTabContainerState extends Equatable {
  Screen9BackgroundColorTabContainerState(
      {this.screen9BackgroundColorTabContainerModelObj});
  Screen9BackgroundColorTabContainerModel?
      screen9BackgroundColorTabContainerModelObj;
  @override
  List<Object?> get props => [screen9BackgroundColorTabContainerModelObj];
  Screen9BackgroundColorTabContainerState copyWith(
      {Screen9BackgroundColorTabContainerModel?
          screen9BackgroundColorTabContainerModelObj}) {
    return Screen9BackgroundColorTabContainerState(
      screen9BackgroundColorTabContainerModelObj:
          screen9BackgroundColorTabContainerModelObj ??
              this.screen9BackgroundColorTabContainerModelObj,
    );
  }
}
