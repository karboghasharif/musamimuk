import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/contest_item.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/contest_repository.dart';
import '../models/screen_contesttwo_model.dart';
import '../models/userprofile_item_model.dart';
part 'screen_contesttwo_event.dart';
part 'screen_contesttwo_state.dart';

/// A bloc that manages the state of a ScreenContesttwo according to the event that is dispatched to it.
class ScreenContesttwoBloc
    extends Bloc<ScreenContesttwoEvent, ScreenContesttwoState> {
  ScreenContesttwoBloc(
    super.initialState, {
    ContestRepository? repository,
  }) : _repo = repository ?? ContestRepository.instance {
    on<ScreenContesttwoInitialEvent>(_onInitialize);
  }
  final ContestRepository _repo;

  _onInitialize(
    ScreenContesttwoInitialEvent event,
    Emitter<ScreenContesttwoState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    ContestItem? contest = event.contestFromList;

    if (contest == null && event.contestId > 0) {
      final listRes = await _repo.list();
      if (listRes is ContestFailure) {
        emit(state.copyWith(isLoading: false, errorMessage: listRes.message));
        return;
      }
      contest =
          (listRes as ContestListResult).findContestById(event.contestId);
      if (contest == null) {
        final byIdRes = await _repo.getById(event.contestId);
        if (byIdRes is ContestFailure) {
          emit(
            state.copyWith(isLoading: false, errorMessage: byIdRes.message),
          );
          return;
        }
        contest = (byIdRes as ContestDetailResult).item;
      }
    }

    if (contest == null) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'msg_missing_contest_data'.tr,
      ));
      return;
    }

    final submissionContestId = contest.id;
    List<MediaItem> accepted = const [];
    if (submissionContestId > 0) {
      final acceptedRes = await _repo.acceptedDesigns(submissionContestId);
      if (acceptedRes is ContestFailure) {
        emit(
          state.copyWith(isLoading: false, errorMessage: acceptedRes.message),
        );
        return;
      }
      accepted = (acceptedRes as ContestAcceptedDesignsResult).designs;
    }

    final users = _mapAcceptedToUi(accepted);

    emit(state.copyWith(
      isLoading: false,
      errorMessage: null,
      contestName: contest.name,
      bannerUrl: contest.fileUrl,
      startDate: contest.startDate,
      endDate: contest.endDate,
      acceptedCount: accepted.length,
      screenContesttwoModelObj:
          (state.screenContesttwoModelObj ?? const ScreenContesttwoModel())
              .copyWith(
        userprofileItemList: users,
      ),
    ));
  }

  List<UserprofileItemModel> _mapAcceptedToUi(List<MediaItem> list) {
    return List<UserprofileItemModel>.generate(list.length, (index) {
      final item = list[index];
      final badge = index == 0
          ? ImageConstant.img2ndPlace1
          : index == 1
              ? ImageConstant.img2ndPlace1
              : index == 2
                  ? ImageConstant.img2ndPlace1
                  : null;
      return UserprofileItemModel(
        userImage: item.fileUrl,
        username: item.name,
        userImage1: badge,
        id: item.id.toString(),
      );
    });
  }
}
