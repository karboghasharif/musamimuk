import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_6_add_logos_model.dart';
part 'screen_6_add_logos_event.dart';
part 'screen_6_add_logos_state.dart';

/// A bloc that manages the state of a Screen6AddLogos according to the event that is dispatched to it.
class Screen6AddLogosBloc
    extends Bloc<Screen6AddLogosEvent, Screen6AddLogosState> {
  Screen6AddLogosBloc(super.initialState) {
    on<Screen6AddLogosInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen6AddLogosInitialEvent event,
    Emitter<Screen6AddLogosState> emit,
  ) async {
    emit(state.copyWith(
      searchController: TextEditingController(),
    ));
  }
}
