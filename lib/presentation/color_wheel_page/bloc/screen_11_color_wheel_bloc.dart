import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_11_color_wheel_model.dart';
part 'screen_11_color_wheel_event.dart';
part 'screen_11_color_wheel_state.dart';

class Screen11ColorWheelBloc
    extends Bloc<Screen11ColorWheelEvent, Screen11ColorWheelState> {
  Screen11ColorWheelBloc(super.initialState) {
    on<Screen11ColorWheelInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen11ColorWheelInitialEvent event,
    Emitter<Screen11ColorWheelState> emit,
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
