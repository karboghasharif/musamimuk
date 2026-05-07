import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_15_menu_bar_model.dart';
part 'screen_15_menu_bar_event.dart';
part 'screen_15_menu_bar_state.dart';

class Screen15MenuBarBloc
    extends Bloc<Screen15MenuBarEvent, Screen15MenuBarState> {
  Screen15MenuBarBloc(super.initialState) {
    on<Screen15MenuBarInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen15MenuBarInitialEvent event,
    Emitter<Screen15MenuBarState> emit,
  ) async {}
}
