import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_12_swatch_model.dart';
part 'screen_12_swatch_event.dart';
part 'screen_12_swatch_state.dart';

class Screen12SwatchBloc
    extends Bloc<Screen12SwatchEvent, Screen12SwatchState> {
  Screen12SwatchBloc(super.initialState) {
    on<Screen12SwatchInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen12SwatchInitialEvent event,
    Emitter<Screen12SwatchState> emit,
  ) async {}
}
