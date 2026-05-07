import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_11_color_wheel_tab_container_model.dart';
part 'screen_11_color_wheel_tab_container_event.dart';
part 'screen_11_color_wheel_tab_container_state.dart';

class Screen11ColorWheelTabContainerBloc extends Bloc<
    Screen11ColorWheelTabContainerEvent, Screen11ColorWheelTabContainerState> {
  Screen11ColorWheelTabContainerBloc(
      super.initialState) {
    on<Screen11ColorWheelTabContainerInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen11ColorWheelTabContainerInitialEvent event,
    Emitter<Screen11ColorWheelTabContainerState> emit,
  ) async {}
}
