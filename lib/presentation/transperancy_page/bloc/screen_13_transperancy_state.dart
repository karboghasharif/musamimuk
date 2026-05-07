part of 'screen_13_transperancy_bloc.dart';

class Screen13TransperancyState extends Equatable {
  Screen13TransperancyState(
      {this.edittextController,
      this.edittextoneController,
      this.edittexttwoController,
      this.edittextthreeController,
      this.edittextfourController,
      this.screen13TransperancyModelObj});
  TextEditingController? edittextController;
  TextEditingController? edittextoneController;
  TextEditingController? edittexttwoController;
  TextEditingController? edittextthreeController;
  TextEditingController? edittextfourController;
  Screen13TransperancyModel? screen13TransperancyModelObj;
  @override
  List<Object?> get props => [
        edittextController,
        edittextoneController,
        edittexttwoController,
        edittextthreeController,
        edittextfourController,
        screen13TransperancyModelObj
      ];
  Screen13TransperancyState copyWith({
    TextEditingController? edittextController,
    TextEditingController? edittextoneController,
    TextEditingController? edittexttwoController,
    TextEditingController? edittextthreeController,
    TextEditingController? edittextfourController,
    Screen13TransperancyModel? screen13TransperancyModelObj,
  }) {
    return Screen13TransperancyState(
      edittextController: edittextController ?? this.edittextController,
      edittextoneController:
          edittextoneController ?? this.edittextoneController,
      edittexttwoController:
          edittexttwoController ?? this.edittexttwoController,
      edittextthreeController:
          edittextthreeController ?? this.edittextthreeController,
      edittextfourController:
          edittextfourController ?? this.edittextfourController,
      screen13TransperancyModelObj:
          screen13TransperancyModelObj ?? this.screen13TransperancyModelObj,
    );
  }
}
