part of 'screen_1_home_bloc.dart';

class Screen1HomeState extends Equatable {
  Screen1HomeState({this.screen1HomeModelObj});
  Screen1HomeModel? screen1HomeModelObj;
  @override
  List<Object?> get props => [screen1HomeModelObj];
  Screen1HomeState copyWith({
    Screen1HomeModel? screen1HomeModelObj,
  }) {
    return Screen1HomeState(
      screen1HomeModelObj: screen1HomeModelObj ?? this.screen1HomeModelObj,
    );
  }
}
