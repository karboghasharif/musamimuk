part of 'screen_14_recent_colors_bloc.dart';

class Screen14RecentColorsState extends Equatable {
  Screen14RecentColorsState(
      {this.edittextController,
      this.edittextoneController,
      this.edittexttwoController,
      this.edittextthreeController,
      this.edittextfourController,
      this.screen14RecentColorsModelObj});
  TextEditingController? edittextController;
  TextEditingController? edittextoneController;
  TextEditingController? edittexttwoController;
  TextEditingController? edittextthreeController;
  TextEditingController? edittextfourController;
  Screen14RecentColorsModel? screen14RecentColorsModelObj;
  @override
  List<Object?> get props => [
        edittextController,
        edittextoneController,
        edittexttwoController,
        edittextthreeController,
        edittextfourController,
        screen14RecentColorsModelObj
      ];
  Screen14RecentColorsState copyWith({
    TextEditingController? edittextController,
    TextEditingController? edittextoneController,
    TextEditingController? edittexttwoController,
    TextEditingController? edittextthreeController,
    TextEditingController? edittextfourController,
    Screen14RecentColorsModel? screen14RecentColorsModelObj,
  }) {
    return Screen14RecentColorsState(
      edittextController: edittextController ?? this.edittextController,
      edittextoneController:
          edittextoneController ?? this.edittextoneController,
      edittexttwoController:
          edittexttwoController ?? this.edittexttwoController,
      edittextthreeController:
          edittextthreeController ?? this.edittextthreeController,
      edittextfourController:
          edittextfourController ?? this.edittextfourController,
      screen14RecentColorsModelObj:
          screen14RecentColorsModelObj ?? this.screen14RecentColorsModelObj,
    );
  }
}
