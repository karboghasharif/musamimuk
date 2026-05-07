import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_13_transperancy_model.dart';
part 'screen_13_transperancy_event.dart';
part 'screen_13_transperancy_state.dart';

class Screen13TransperancyBloc
    extends Bloc<Screen13TransperancyEvent, Screen13TransperancyState> {
  Screen13TransperancyBloc(super.initialState) {
    on<Screen13TransperancyInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen13TransperancyInitialEvent event,
    Emitter<Screen13TransperancyState> emit,
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
