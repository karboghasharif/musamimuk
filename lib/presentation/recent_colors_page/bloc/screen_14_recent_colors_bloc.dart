import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_14_recent_colors_model.dart';
part 'screen_14_recent_colors_event.dart';
part 'screen_14_recent_colors_state.dart';

class Screen14RecentColorsBloc
    extends Bloc<Screen14RecentColorsEvent, Screen14RecentColorsState> {
  Screen14RecentColorsBloc(super.initialState) {
    on<Screen14RecentColorsInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen14RecentColorsInitialEvent event,
    Emitter<Screen14RecentColorsState> emit,
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
