import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_twentythree_model.dart';
part 'screen_twentythree_event.dart';
part 'screen_twentythree_state.dart';

/// A bloc that manages the state of a ScreenTwentythree according to the event that is dispatched to it.
class ScreenTwentythreeBloc
    extends Bloc<ScreenTwentythreeEvent, ScreenTwentythreeState> {
  ScreenTwentythreeBloc(super.initialState) {
    on<ScreenTwentythreeInitialEvent>(_onInitialize);
  }
  _onInitialize(
    ScreenTwentythreeInitialEvent event,
    Emitter<ScreenTwentythreeState> emit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (PrefUtils().isLoggedIn() || PrefUtils().hasOfflineHomeAccess()) {
      NavigatorService.popAndPushNamed(AppRoutes.screen1HomeScreen);
    } else {
      NavigatorService.popAndPushNamed(AppRoutes.screen0LoginScreen);
    }
  }
}
