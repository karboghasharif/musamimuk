// import 'package:flutter/material.dart';
// import 'package:equatable/equatable.dart';
// import '../../../core/app_export.dart';
// import '../models/add_text_input_language.dart';
// import '../models/screen_4_add_text_model.dart';
// part 'screen_4_add_text_event.dart';
// part 'screen_4_add_text_state.dart';

// /// A bloc that manages the state of a Screen4AddText according to the event that is dispatched to it.
// class Screen4AddTextBloc
//     extends Bloc<Screen4AddTextEvent, Screen4AddTextState> {
//   Screen4AddTextBloc(super.initialState) {
//     on<Screen4AddTextInitialEvent>(_onInitialize);
//     on<Screen4AddTextSetLanguageEvent>(_onSetLanguage);
//   }

//   void _onInitialize(
//     Screen4AddTextInitialEvent event,
//     Emitter<Screen4AddTextState> emit,
//   ) async {
//     emit(state.copyWith(
//       originalLanguageEditTextController: TextEditingController(),
//     ));
//   }

//   void _onSetLanguage(
//     Screen4AddTextSetLanguageEvent event,
//     Emitter<Screen4AddTextState> emit,
//   ) {
//     emit(state.copyWith(inputLanguage: event.language));
//   }

//   @override
//   Future<void> close() {
//     state.originalLanguageEditTextController?.dispose();
//     return super.close();
//   }
// }
