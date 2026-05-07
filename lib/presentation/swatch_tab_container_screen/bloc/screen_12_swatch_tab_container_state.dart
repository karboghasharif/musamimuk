part of 'screen_12_swatch_tab_container_bloc.dart';

class Screen12SwatchTabContainerState extends Equatable {
  Screen12SwatchTabContainerState(
      {this.edittextController,
      this.edittextoneController,
      this.edittexttwoController,
      this.edittextthreeController,
      this.edittextfourController,
      this.screen12SwatchTabContainerModelObj});
  TextEditingController? edittextController;
  TextEditingController? edittextoneController;
  TextEditingController? edittexttwoController;
  TextEditingController? edittextthreeController;
  TextEditingController? edittextfourController;
  Screen12SwatchTabContainerModel? screen12SwatchTabContainerModelObj;
  @override
  List<Object?> get props => [
        edittextController,
        edittextoneController,
        edittexttwoController,
        edittextthreeController,
        edittextfourController,
        screen12SwatchTabContainerModelObj
      ];
  Screen12SwatchTabContainerState copyWith({
    TextEditingController? edittextController,
    TextEditingController? edittextoneController,
    TextEditingController? edittexttwoController,
    TextEditingController? edittextthreeController,
    TextEditingController? edittextfourController,
    Screen12SwatchTabContainerModel? screen12SwatchTabContainerModelObj,
  }) {
    return Screen12SwatchTabContainerState(
      edittextController: edittextController ?? this.edittextController,
      edittextoneController:
          edittextoneController ?? this.edittextoneController,
      edittexttwoController:
          edittexttwoController ?? this.edittexttwoController,
      edittextthreeController:
          edittextthreeController ?? this.edittextthreeController,
      edittextfourController:
          edittextfourController ?? this.edittextfourController,
      screen12SwatchTabContainerModelObj: screen12SwatchTabContainerModelObj ??
          this.screen12SwatchTabContainerModelObj,
    );
  }
}
