import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/selectionPopupModel/selection_popup_model.dart';
import '../models/screen_7_resize_paper_model.dart';
part 'screen_7_resize_paper_event.dart';
part 'screen_7_resize_paper_state.dart';

/// A bloc that manages the state of a Screen7ResizePaper according to the event that is dispatched to it.
class Screen7ResizePaperBloc
    extends Bloc<Screen7ResizePaperEvent, Screen7ResizePaperState> {
  Screen7ResizePaperBloc(super.initialState) {
    on<Screen7ResizePaperInitialEvent>(_onInitialize);
    on<ResizePaperUnitSelectedEvent>(_onUnitSelected);
  }

  @override
  Future<void> close() {
    state.valueoneController?.dispose();
    state.valuetwoController?.dispose();
    return super.close();
  }

  List<SelectionPopupModel> fillDropdownItemList() {
    return [
      SelectionPopupModel(id: 1, title: 'lbl_pixels'.tr, isSelected: true),
      SelectionPopupModel(id: 2, title: 'lbl_unit_centimeters'.tr),
      SelectionPopupModel(id: 3, title: 'lbl_unit_inches'.tr),
    ];
  }

  void _onUnitSelected(
    ResizePaperUnitSelectedEvent event,
    Emitter<Screen7ResizePaperState> emit,
  ) {
    emit(state.copyWith(selectedDropDownValue: event.unit));
  }

  _onInitialize(
    Screen7ResizePaperInitialEvent event,
    Emitter<Screen7ResizePaperState> emit,
  ) async {
    final items = fillDropdownItemList();
    final selected = items.firstWhere(
      (e) => e.isSelected,
      orElse: () => items.first,
    );
    emit(state.copyWith(
      selectedDropDownValue: selected,
      screen7ResizePaperModelObj: state.screen7ResizePaperModelObj?.copyWith(
        dropdownItemList: items,
      ),
    ));
  }
}
