import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/advertisement_repository.dart';
import '../../../data/repositories/public_repository.dart';
import '../models/screen_1_home_model.dart';
part 'screen_1_home_event.dart';
part 'screen_1_home_state.dart';

class Screen1HomeBloc extends Bloc<Screen1HomeEvent, Screen1HomeState> {
  Screen1HomeBloc(super.initialState) : _publicRepo = PublicRepository() {
    on<Screen1HomeInitialEvent>(_onInitialize);
    on<Screen1HomeRefreshEvent>(_onRefresh);
  }

  final PublicRepository _publicRepo;

  Future<void> _onInitialize(
    Screen1HomeInitialEvent event,
    Emitter<Screen1HomeState> emit,
  ) async {
    await _loadFeatured(emit, bumpAdsToken: false);
  }

  Future<void> _onRefresh(
    Screen1HomeRefreshEvent event,
    Emitter<Screen1HomeState> emit,
  ) async {
    AdvertisementRepository.clearAdsCache(placement: 'home_banner');
    emit(state.copyWith(adsRefreshToken: state.adsRefreshToken + 1));
    await _loadFeatured(emit, bumpAdsToken: false);
  }

  Future<void> _loadFeatured(
    Emitter<Screen1HomeState> emit, {
    required bool bumpAdsToken,
  }) async {
    emit(
      state.copyWith(
        isLoadingFeatured: true,
        adsRefreshToken: bumpAdsToken
            ? state.adsRefreshToken + 1
            : state.adsRefreshToken,
      ),
    );
    final result = await _publicRepo.featuredDesigns();
    if (result is PublicSuccess<List<MediaItem>>) {
      emit(
        state.copyWith(isLoadingFeatured: false, featuredDesigns: result.data),
      );
      return;
    }
    emit(state.copyWith(isLoadingFeatured: false, featuredDesigns: const []));
  }
}
