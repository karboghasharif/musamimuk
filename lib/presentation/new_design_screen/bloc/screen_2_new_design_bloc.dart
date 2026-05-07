import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_2_new_design_model.dart';
part 'screen_2_new_design_event.dart';
part 'screen_2_new_design_state.dart';
//A bloc that manages the state of a Screen2NewDesign according to the event that is dispatched to it.

class Screen2NewDesignBloc
    extends Bloc<Screen2NewDesignEvent, Screen2NewDesignState> {
  Screen2NewDesignBloc(super.initialState) {
    on<Screen2NewDesignInitialEvent>(_onInitialize);
  }
  Future<void> _onInitialize(
    Screen2NewDesignInitialEvent event,
    Emitter<Screen2NewDesignState> emit,
  ) async {
    emit(state.copyWith(
        screen2NewDesignModelObj: const Screen2NewDesignModel()));
  }
}
