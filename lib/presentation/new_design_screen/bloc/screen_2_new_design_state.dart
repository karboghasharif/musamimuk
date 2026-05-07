part of 'screen_2_new_design_bloc.dart';

/// Represents the state of Screen2NewDesign in the application.\\ ignore_for_file: must_be_immutable
class Screen2NewDesignState extends Equatable {
  Screen2NewDesignState({this.screen2NewDesignModelObj});
  Screen2NewDesignModel? screen2NewDesignModelObj;
  @override
  List<Object?> get props => [screen2NewDesignModelObj];
  Screen2NewDesignState copyWith(
      {Screen2NewDesignModel? screen2NewDesignModelObj}) {
    return Screen2NewDesignState(
      screen2NewDesignModelObj:
          screen2NewDesignModelObj ?? this.screen2NewDesignModelObj,
    );
  }
}
