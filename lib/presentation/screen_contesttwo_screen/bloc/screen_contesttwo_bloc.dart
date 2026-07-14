import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/contest_design_entry.dart';
import '../../../data/models/contest_detail.dart';
import '../../../data/models/contest_item.dart';
import '../../../data/models/contest_user_context.dart';
import '../../../data/repositories/contest_repository.dart';
import '../models/screen_contesttwo_model.dart';
import '../models/userprofile_item_model.dart';
part 'screen_contesttwo_event.dart';
part 'screen_contesttwo_state.dart';

class ScreenContesttwoBloc
    extends Bloc<ScreenContesttwoEvent, ScreenContesttwoState> {
  ScreenContesttwoBloc(
    super.initialState, {
    ContestRepository? repository,
  }) : _repo = repository ?? ContestRepository.instance {
    on<ScreenContesttwoInitialEvent>(_onLoad);
    on<ScreenContesttwoRefreshEvent>(_onLoad);
    on<ScreenContesttwoJoinEvent>(_onJoin);
    on<ScreenContesttwoActionEvent>(_onAction);
    on<ScreenContesttwoClearPendingEvent>(
      (event, emit) => emit(state.copyWith(clearPendingAction: true)),
    );
  }

  final ContestRepository _repo;
  int _loadGeneration = 0;

  Future<void> _onLoad(
    ScreenContesttwoEvent event,
    Emitter<ScreenContesttwoState> emit,
  ) async {
    final contestId = event is ScreenContesttwoInitialEvent
        ? event.contestId
        : event is ScreenContesttwoRefreshEvent
        ? event.contestId
        : state.detail?.contest.id ?? 0;
    final contestFromList = event is ScreenContesttwoInitialEvent
        ? event.contestFromList
        : event is ScreenContesttwoRefreshEvent
        ? event.contestFromList
        : null;
    final generation = ++_loadGeneration;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      ContestDetail? detail;
      if (contestId > 0) {
        final detailRes = await _repo.getDetail(contestId);
        if (generation != _loadGeneration) return;
        if (detailRes is ContestFailure) {
          if (contestFromList == null) {
            emit(state.copyWith(isLoading: false, errorMessage: detailRes.message));
            return;
          }
        } else if (detailRes is ContestDetailResult) {
          detail = _mergeDetailUser(
            detailRes.detail,
            contestFromList: contestFromList,
            previousUser: state.detail?.user,
          );
        }
      }

      final contest = detail?.contest ?? contestFromList;
      if (contest == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'msg_missing_contest_data'.tr,
        ));
        return;
      }

      List<ContestDesignEntry> entries = const [];
      if (isContestResultsAnnounced(contest, hasWinners: false)) {
        final acceptedRes = await _repo.acceptedDesigns(contest.id);
        if (generation != _loadGeneration) return;
        if (acceptedRes is ContestAcceptedDesignsResult) {
          entries = acceptedRes.entries;
        }
      }

      final stats = detail?.stats ??
          await _repo.submissionStats(
            contest.id,
            contest: contest,
            acceptedFromEntries: entries.length,
          );
      if (generation != _loadGeneration) return;

      final hasWinners = entries.any((e) => e.position != null);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: null,
        detail: detail ?? ContestDetail(
          contest: contest,
          countdown: contest.countdown,
          user: _mergeUserContexts(null, contestFromList?.user, state.detail?.user),
        ),
        contestName: contest.name,
        bannerUrl: contest.fileUrl,
        startDate: contest.startDate,
        endDate: contest.endDate,
        acceptedCount: stats?.accepted ?? entries.length,
        submittedCount: stats?.submitted ?? contest.submissionsCount,
        rejectedCount: stats?.rejected ?? contest.rejectedCount,
        participantsCount: detail?.participantsCount ?? contest.participantsCount,
        prizeText: detail?.prize?.displayText().isNotEmpty == true
            ? detail!.prize!.displayText()
            : contest.prizeDisplay,
        status: contest.status,
        resultsAnnounced: isContestResultsAnnounced(contest, hasWinners: hasWinners),
        screenContesttwoModelObj:
            (state.screenContesttwoModelObj ?? const ScreenContesttwoModel())
                .copyWith(userprofileItemList: _mapEntriesToUi(entries)),
      ));
    } catch (_) {
      if (generation != _loadGeneration) return;
      emit(state.copyWith(isLoading: false, errorMessage: 'Something went wrong'));
    }
  }

  Future<void> _onJoin(
    ScreenContesttwoJoinEvent event,
    Emitter<ScreenContesttwoState> emit,
  ) async {
    emit(state.copyWith(isActionLoading: true, errorMessage: null));
    final result = await _repo.joinContest(event.contestId);
    if (result is ContestFailure) {
      emit(state.copyWith(isActionLoading: false, errorMessage: result.message));
      return;
    }

    ContestUserContext? joinedUser;
    if (result is ContestMessageResult && result.data != null) {
      joinedUser = ContestUserContext.fromJoinPayload(result.data);
    }

    final currentDetail = state.detail;
    if (joinedUser != null && currentDetail != null) {
      final merged = joinedUser.joined
          ? joinedUser
          : joinedUser.copyWith(joined: true, canJoin: false);
      emit(
        state.copyWith(
          isActionLoading: false,
          detail: ContestDetail(
            contest: currentDetail.contest,
            user: merged.canSubmit != true
                ? merged.copyWith(canSubmit: true)
                : merged,
            countdown: currentDetail.countdown,
            stats: currentDetail.stats,
            prize: currentDetail.prize,
            participantsCount: currentDetail.participantsCount,
            raw: currentDetail.raw,
          ),
        ),
      );
    } else if (currentDetail != null) {
      final prev = currentDetail.user;
      emit(
        state.copyWith(
          isActionLoading: false,
          detail: ContestDetail(
            contest: currentDetail.contest,
            user: (prev ?? const ContestUserContext()).copyWith(
              joined: true,
              canJoin: false,
              canSubmit: prev?.canSubmit ?? true,
            ),
            countdown: currentDetail.countdown,
            stats: currentDetail.stats,
            prize: currentDetail.prize,
            participantsCount: currentDetail.participantsCount,
            raw: currentDetail.raw,
          ),
        ),
      );
    } else {
      emit(state.copyWith(isActionLoading: false));
    }
  }

  ContestDetail? _mergeDetailUser(
    ContestDetail? detail, {
    ContestItem? contestFromList,
    ContestUserContext? previousUser,
  }) {
    if (detail == null) return null;
    var user = _mergeUserContexts(
      detail.user,
      contestFromList?.user,
      previousUser,
    );
    if (previousUser?.joined == true) {
      user = (user ?? const ContestUserContext()).copyWith(
        joined: true,
        canJoin: false,
        canSubmit: user?.hasSubmitted == true
            ? false
            : (user?.canSubmit ?? previousUser?.canSubmit ?? true),
      );
    }
    if (user == detail.user) return detail;
    return ContestDetail(
      contest: detail.contest,
      user: user,
      countdown: detail.countdown,
      stats: detail.stats,
      prize: detail.prize,
      participantsCount: detail.participantsCount,
      raw: detail.raw,
    );
  }

  ContestUserContext? _mergeUserContexts(
    ContestUserContext? api,
    ContestUserContext? fromList,
    ContestUserContext? previous,
  ) {
    return ContestUserContext.merge(
      ContestUserContext.merge(api, fromList),
      previous,
    );
  }

  Future<void> _onAction(
    ScreenContesttwoActionEvent event,
    Emitter<ScreenContesttwoState> emit,
  ) async {
    emit(state.copyWith(pendingAction: event.actionKey));
    switch (event.actionKey) {
      case 'join':
        add(ScreenContesttwoJoinEvent(contestId: event.contestId));
        break;
      case 'submit':
      case 'gallery':
      case 'winners':
      case 'results':
      case 'notify':
        emit(state.copyWith(clearPendingAction: false));
        break;
      default:
        emit(state.copyWith(clearPendingAction: true));
    }
  }

  List<UserprofileItemModel> _mapEntriesToUi(List<ContestDesignEntry> list) {
    return list
        .map(
          (entry) => UserprofileItemModel(
            userImage: entry.design.fileUrl,
            username: entry.displayName ?? entry.design.creatorName,
            placePosition: entry.position,
            id: entry.design.id.toString(),
          ),
        )
        .toList();
  }
}
