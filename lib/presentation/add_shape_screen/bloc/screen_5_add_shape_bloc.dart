import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../core/app_export.dart';
import '../models/screen_5_add_shape_model.dart';
part 'screen_5_add_shape_event.dart';
part 'screen_5_add_shape_state.dart';

/// A bloc that manages the state of a Screen5AddShape according to the event that is dispatched to it.
class Screen5AddShapeBloc
    extends Bloc<Screen5AddShapeEvent, Screen5AddShapeState> with CodeAutoFill {
  Screen5AddShapeBloc(super.initialState) {
    on<Screen5AddShapeInitialEvent>(_onInitialize);
    on<ChangeOTPEvent>(_changeOTP);
  }
  @override
  codeUpdated() {
    add(ChangeOTPEvent(code: code!));
  }

  _changeOTP(
    ChangeOTPEvent event,
    Emitter<Screen5AddShapeState> emit,
  ) {
    emit(state.copyWith(
      otpController: TextEditingController(text: event.code),
    ));
  }

  _onInitialize(
    Screen5AddShapeInitialEvent event,
    Emitter<Screen5AddShapeState> emit,
  ) async {
    emit(state.copyWith(
      searchController: TextEditingController(),
      otpController: TextEditingController(),
    ));
    listenForCode();
  }
}
