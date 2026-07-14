import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/listrectangle_item_model.dart';
import '../models/screen_20_remove_background_model.dart';
part 'screen_20_remove_background_event.dart';
part 'screen_20_remove_background_state.dart';

/// A bloc that manages the state of a Screen20RemoveBackground according to the event that is dispatched to it.
class Screen20RemoveBackgroundBloc
    extends Bloc<Screen20RemoveBackgroundEvent, Screen20RemoveBackgroundState> {
  Screen20RemoveBackgroundBloc(super.initialState) {
    on<Screen20RemoveBackgroundInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen20RemoveBackgroundInitialEvent event,
    Emitter<Screen20RemoveBackgroundState> emit,
  ) async {
    emit(state.copyWith(
        screen20RemoveBackgroundModelObj:
            state.screen20RemoveBackgroundModelObj?.copyWith(
      listrectangleItemList: fillListrectangleItemList(),
    )));
  }

  List<ListrectangleItemModel> fillListrectangleItemList() {
    return const [];
  }
}
