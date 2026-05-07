import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_9_background_color_tab_container_model.dart';
part 'screen_9_background_color_tab_container_event.dart';
part 'screen_9_background_color_tab_container_state.dart';

/// A bloc that manages the state of a Screen9BackgroundColorTabContainer according to the event that is dispatched to it.
class Screen9BackgroundColorTabContainerBloc extends Bloc<
    Screen9BackgroundColorTabContainerEvent,
    Screen9BackgroundColorTabContainerState> {
  Screen9BackgroundColorTabContainerBloc(
      super.initialState) {
    on<Screen9BackgroundColorTabContainerInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen9BackgroundColorTabContainerInitialEvent event,
    Emitter<Screen9BackgroundColorTabContainerState> emit,
  ) async {}
}
