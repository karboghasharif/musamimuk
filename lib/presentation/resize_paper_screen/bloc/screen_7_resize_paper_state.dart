part of 'screen_7_resize_paper_bloc.dart';

/// Represents the state of Screen7ResizePaper in the application.// ignore_for_file: must_be_immutable
class Screen7ResizePaperState extends Equatable {
  Screen7ResizePaperState(
      {this.valueoneController,
      this.valuetwoController,
      this.selectedDropDownValue,
      this.screen7ResizePaperModelObj});
  TextEditingController? valueoneController;
  TextEditingController? valuetwoController;
  SelectionPopupModel? selectedDropDownValue;
  Screen7ResizePaperModel? screen7ResizePaperModelObj;
  @override
  List<Object?> get props => [
        valueoneController,
        valuetwoController,
        selectedDropDownValue,
        screen7ResizePaperModelObj,
      ];
  Screen7ResizePaperState copyWith({
    TextEditingController? valueoneController,
    TextEditingController? valuetwoController,
    SelectionPopupModel? selectedDropDownValue,
    Screen7ResizePaperModel? screen7ResizePaperModelObj,
  }) {
    return Screen7ResizePaperState(
      valueoneController: valueoneController ?? this.valueoneController,
      valuetwoController: valuetwoController ?? this.valuetwoController,
      selectedDropDownValue:
          selectedDropDownValue ?? this.selectedDropDownValue,
      screen7ResizePaperModelObj:
          screen7ResizePaperModelObj ?? this.screen7ResizePaperModelObj,
    );
  }
}
