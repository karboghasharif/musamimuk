import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_21_remove_background_model.dart';
part 'screen_21_remove_background_event.dart';
part 'screen_21_remove_background_state.dart';

/// A bloc that manages the state of a Screen21RemoveBackground according to the event that is dispatched to it.
class Screen21RemoveBackgroundBloc
    extends Bloc<Screen21RemoveBackgroundEvent, Screen21RemoveBackgroundState> {
  Screen21RemoveBackgroundBloc(super.initialState) {
    on<Screen21RemoveBackgroundInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen21RemoveBackgroundInitialEvent event,
    Emitter<Screen21RemoveBackgroundState> emit,
  ) async {}
}
