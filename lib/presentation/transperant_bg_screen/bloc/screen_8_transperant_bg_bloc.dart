import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_8_transperant_bg_model.dart';
part 'screen_8_transperant_bg_event.dart';
part 'screen_8_transperant_bg_state.dart';

/// A bloc that manages the state of a Screen8TransperantBg according to the event that is dispatched to it.
class Screen8TransperantBgBloc
    extends Bloc<Screen8TransperantBgEvent, Screen8TransperantBgState> {
  Screen8TransperantBgBloc(super.initialState) {
    on<Screen8TransperantBgInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen8TransperantBgInitialEvent event,
    Emitter<Screen8TransperantBgState> emit,
  ) async {}
}
