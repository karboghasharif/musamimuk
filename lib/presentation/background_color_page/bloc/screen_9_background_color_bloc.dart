import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_9_background_color_model.dart';
part 'screen_9_background_color_event.dart';
part 'screen_9_background_color_state.dart';

/// A bloc that manages the state of a Screen9BackgroundColor according to the event that is dispatched to it.
class Screen9BackgroundColorBloc
    extends Bloc<Screen9BackgroundColorEvent, Screen9BackgroundColorState> {
  Screen9BackgroundColorBloc(super.initialState) {
    on<Screen9BackgroundColorInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen9BackgroundColorInitialEvent event,
    Emitter<Screen9BackgroundColorState> emit,
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
