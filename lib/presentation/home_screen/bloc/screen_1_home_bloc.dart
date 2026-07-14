import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/public_repository.dart';
import '../models/screen_1_home_model.dart';
part 'screen_1_home_event.dart';
part 'screen_1_home_state.dart';

class Screen1HomeBloc extends Bloc<Screen1HomeEvent, Screen1HomeState> {
  Screen1HomeBloc(super.initialState) : _publicRepo = PublicRepository() {
    on<Screen1HomeInitialEvent>(_onInitialize);
  }

  final PublicRepository _publicRepo;

  Future<void> _onInitialize(
    Screen1HomeInitialEvent event,
    Emitter<Screen1HomeState> emit,
  ) async {
    emit(state.copyWith(isLoadingFeatured: true));
    final result = await _publicRepo.featuredDesigns();
    if (result is PublicSuccess<List<MediaItem>>) {
      emit(state.copyWith(
        isLoadingFeatured: false,
        featuredDesigns: result.data,
      ));
      return;
    }
    emit(state.copyWith(isLoadingFeatured: false, featuredDesigns: const []));
  }
}
