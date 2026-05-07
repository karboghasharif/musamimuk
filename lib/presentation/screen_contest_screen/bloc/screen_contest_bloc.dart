import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/contest_item.dart';
import '../../../data/repositories/contest_repository.dart';
import '../models/certificatedesign_item_model.dart';
import '../models/screen_contest_model.dart';
part 'screen_contest_event.dart';
part 'screen_contest_state.dart';

/// A bloc that manages the state of a ScreenContest according to the event that is dispatched to it.
class ScreenContestBloc extends Bloc<ScreenContestEvent, ScreenContestState> {
  ScreenContestBloc(
    super.initialState, {
    ContestRepository? repository,
  }) : _repo = repository ?? ContestRepository.instance {
    on<ScreenContestInitialEvent>(_onInitialize);
    on<ScreenContestLoadEvent>(_onLoad);
  }
  final ContestRepository _repo;

  _onInitialize(
    ScreenContestInitialEvent event,
    Emitter<ScreenContestState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    add(ScreenContestLoadEvent());
  }

  Future<void> _onLoad(
    ScreenContestLoadEvent event,
    Emitter<ScreenContestState> emit,
  ) async {
    if (event.forceRefresh) {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }
    final result = await _repo.list(forceRefresh: event.forceRefresh);
    if (result is ContestFailure) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.message,
        screenContestModelObj: state.screenContestModelObj?.copyWith(
          openContestItemList: const [],
          closedContestItemList: const [],
        ),
      ));
      return;
    }
    final success = result as ContestListResult;
    List<ContestItem> open = success.openContests ?? const [];
    List<ContestItem> closed = success.closedContests ?? const [];
    if (open.isEmpty && closed.isEmpty) {
      open = List<ContestItem>.from(success.items);
    }
    emit(state.copyWith(
      isLoading: false,
      errorMessage: null,
      screenContestModelObj: (state.screenContestModelObj ?? const ScreenContestModel()).copyWith(
        openContestItemList: open.map(_mapContestToUi).toList(),
        closedContestItemList: closed.map(_mapContestToUi).toList(),
      ),
    ));
  }

  CertificatedesignItemModel _mapContestToUi(ContestItem c) {
    final dateText = formatContestDateRangeDisplay(c.startDate, c.endDate);
    return CertificatedesignItemModel(
      certificateText: c.name,
      designsText: dateText.isEmpty ? 'View details' : dateText,
      image: c.fileUrl,
      id: c.id.toString(),
      contestJson: c.toJson(),
    );
  }
}
