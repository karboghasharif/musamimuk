import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/imagelist_item_model.dart';
import '../models/screen_19_remove_background_model.dart';
part 'screen_19_remove_background_event.dart';
part 'screen_19_remove_background_state.dart';

class Screen19RemoveBackgroundBloc
    extends Bloc<Screen19RemoveBackgroundEvent, Screen19RemoveBackgroundState> {
  Screen19RemoveBackgroundBloc(super.initialState) {
    on<Screen19RemoveBackgroundInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen19RemoveBackgroundInitialEvent event,
    Emitter<Screen19RemoveBackgroundState> emit,
  ) async {
    emit(state.copyWith(
        screen19RemoveBackgroundModelObj:
            state.screen19RemoveBackgroundModelObj?.copyWith(
      imagelistItemList: fillImagelistItemList(),
    )));
  }

  List<ImagelistItemModel> fillImagelistItemList() {
    return const [];
  }
}
