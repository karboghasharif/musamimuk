import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_22_qr_code_genertaor_model.dart';
part 'screen_22_qr_code_genertaor_event.dart';
part 'screen_22_qr_code_genertaor_state.dart';
//A bloc that manages the state of a Screen22QrCodeGenertaor according to the event that is dispatched to it.

class Screen22QrCodeGenertaorBloc
    extends Bloc<Screen22QrCodeGenertaorEvent, Screen22QrCodeGenertaorState> {
  Screen22QrCodeGenertaorBloc(super.initialState) {
    on<Screen22QrCodeGenertaorInitialEvent>(_onInitialize);
  }
  _onInitialize(
    Screen22QrCodeGenertaorInitialEvent event,
    Emitter<Screen22QrCodeGenertaorState> emit,
  ) async {}
}
