import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_12_swatch_tab_container_model.dart';
part 'screen_12_swatch_tab_container_event.dart';
part 'screen_12_swatch_tab_container_state.dart';

class Screen12SwatchTabContainerBloc extends Bloc<
    Screen12SwatchTabContainerEvent, Screen12SwatchTabContainerState> {
  Screen12SwatchTabContainerBloc(super.initialState) {
    on<Screen12SwatchTabContainerInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen12SwatchTabContainerInitialEvent event,
    Emitter<Screen12SwatchTabContainerState> emit,
  ) async {
    emit(state.copyWith(
      edittextController: TextEditingController(),
      edittextoneController: TextEditingController(),
      edittexttwoController: TextEditingController(),
      edittextthreeController: TextEditingController(),
      edittextfourController: TextEditingController(),
    ));
  }
}
