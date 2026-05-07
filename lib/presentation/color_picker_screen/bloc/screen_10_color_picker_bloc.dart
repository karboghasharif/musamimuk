import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_10_color_picker_model.dart';
part 'screen_10_color_picker_event.dart';
part 'screen_10_color_picker_state.dart';

class Screen10ColorPickerBloc
    extends Bloc<Screen10ColorPickerEvent, Screen10ColorPickerState> {
  Screen10ColorPickerBloc(super.initialState) {
    on<Screen10ColorPickerInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen10ColorPickerInitialEvent event,
    Emitter<Screen10ColorPickerState> emit,
  ) async {}
}
