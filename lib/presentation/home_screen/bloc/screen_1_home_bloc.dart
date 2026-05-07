import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_1_home_model.dart';
part 'screen_1_home_event.dart';
part 'screen_1_home_state.dart';

class Screen1HomeBloc extends Bloc<Screen1HomeEvent, Screen1HomeState> {
  Screen1HomeBloc(super.initialState) {
    on<Screen1HomeInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen1HomeInitialEvent event,
    Emitter<Screen1HomeState> emit,
  ) async {
    emit(state.copyWith());
  }
}
