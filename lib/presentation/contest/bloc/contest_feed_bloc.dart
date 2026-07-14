import 'package:equatable/equatable.dart';

import '../../../core/app_export.dart';
import '../../../data/models/contest_submission.dart';
import '../../../data/repositories/contest_repository.dart';

part 'contest_feed_event.dart';
part 'contest_feed_state.dart';

class ContestFeedBloc extends Bloc<ContestFeedEvent, ContestFeedState> {
  ContestFeedBloc(
    super.initialState, {
    ContestRepository? repository,
  }) : _repo = repository ?? ContestRepository.instance {
    on<ContestFeedInitialEvent>(_onInitial);
    on<ContestFeedRefreshEvent>(_onRefresh);
    on<ContestFeedLoadMoreEvent>(_onLoadMore);
    on<ContestFeedToggleLikeEvent>(_onToggleLike);
    on<ContestFeedShareRecordedEvent>(_onShareRecorded);
  }

  final ContestRepository _repo;
  int _loadGeneration = 0;

  Future<void> _onInitial(
    ContestFeedInitialEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    await _fetchPage(emit, reset: true, showInitialLoader: true);
  }

  Future<void> _onRefresh(
    ContestFeedRefreshEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    await _fetchPage(emit, reset: true, showInitialLoader: false);
  }

  Future<void> _onLoadMore(
    ContestFeedLoadMoreEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await _fetchPage(emit, reset: false);
  }

  Future<void> _fetchPage(
    Emitter<ContestFeedState> emit, {
    required bool reset,
    bool showInitialLoader = false,
  }) async {
    final generation = ++_loadGeneration;
    final nextPage = reset ? 1 : state.page;

    emit(
      state.copyWith(
        isLoading: showInitialLoader,
        isRefreshing: !showInitialLoader && reset,
        isLoadingMore: !reset,
        clearError: reset,
      ),
    );

    final result = await _repo.feedSubmissions(page: nextPage);
    if (generation != _loadGeneration) return;

    if (result is ContestFailure) {
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: result.message,
        ),
      );
      return;
    }

    final success = result as ContestSubmissionsResult;
    final merged = reset
        ? success.submissions
        : [...state.items, ...success.submissions];
    final pageMeta = success.page;

    emit(
      state.copyWith(
        items: merged,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: pageMeta?.hasMore ?? false,
        page: pageMeta?.nextPage ?? (reset ? 2 : state.page + 1),
        clearError: true,
      ),
    );
  }

  Future<void> _onToggleLike(
    ContestFeedToggleLikeEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    final id = event.submissionId;
    if (state.likingIds.contains(id)) return;

    final index = state.items.indexWhere((s) => s.id == id);
    if (index < 0) return;

    final current = state.items[index];
    final currentlyLiked = current.isLiked ?? false;

    emit(state.copyWith(likingIds: {...state.likingIds, id}));

    final optimistic = current.copyWith(
      isLiked: !currentlyLiked,
      likesCount: (current.likesCount ?? 0) + (currentlyLiked ? -1 : 1),
    );
    final optimisticItems = [...state.items];
    optimisticItems[index] = optimistic;
    emit(state.copyWith(items: optimisticItems));

    final result = await _repo.toggleSubmissionLike(
      id,
      currentlyLiked: currentlyLiked,
    );

    final likingIds = {...state.likingIds}..remove(id);
    if (result is ContestLikeResult) {
      final resolved = current.copyWith(
        isLiked: result.isLiked,
        likesCount: result.likesCount,
      );
      final items = [...state.items];
      final idx = items.indexWhere((s) => s.id == id);
      if (idx >= 0) items[idx] = resolved;
      emit(state.copyWith(items: items, likingIds: likingIds));
      return;
    }

    if (result is ContestFailure) {
      final reverted = [...state.items];
      reverted[index] = current;
      emit(
        state.copyWith(
          items: reverted,
          likingIds: likingIds,
          errorMessage: result.message,
        ),
      );
    } else {
      emit(state.copyWith(likingIds: likingIds));
    }
  }

  void _onShareRecorded(
    ContestFeedShareRecordedEvent event,
    Emitter<ContestFeedState> emit,
  ) {
    final index = state.items.indexWhere((s) => s.id == event.submissionId);
    if (index < 0) return;

    final current = state.items[index];
    final nextCount = event.sharesCount ??
        ((current.sharesCount ?? 0) + 1);
    final items = [...state.items];
    items[index] = current.copyWith(sharesCount: nextCount);
    emit(state.copyWith(items: items));
  }
}
