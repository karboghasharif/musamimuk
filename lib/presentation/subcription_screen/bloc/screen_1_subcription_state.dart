part of 'screen_1_subcription_bloc.dart';

class Screen1SubcriptionState extends Equatable {
  Screen1SubcriptionState({this.screen1SubcriptionModelObj});
  Screen1SubcriptionModel? screen1SubcriptionModelObj;
  @override
  List<Object?> get props => [screen1SubcriptionModelObj];
  Screen1SubcriptionState copyWith(
      {Screen1SubcriptionModel? screen1SubcriptionModelObj}) {
    return Screen1SubcriptionState(
      screen1SubcriptionModelObj:
          screen1SubcriptionModelObj ?? this.screen1SubcriptionModelObj,
    );
  }
}
