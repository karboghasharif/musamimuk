import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_1_subcription_model.dart';
part 'screen_1_subcription_event.dart';
part 'screen_1_subcription_state.dart';

class Screen1SubcriptionBloc
    extends Bloc<Screen1SubcriptionEvent, Screen1SubcriptionState> {
  Screen1SubcriptionBloc(super.initialState) {
    on<Screen1SubcriptionInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen1SubcriptionInitialEvent event,
    Emitter<Screen1SubcriptionState> emit,
  ) async {}
}
