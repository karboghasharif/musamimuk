import 'package:equatable/equatable.dart';

import '../../../core/app_export.dart';
import '../../../data/models/contest_submission.dart';
import '../../../data/repositories/contest_repository.dart';

part 'contest_feed_event.dart';
part 'contest_feed_state.dart';

class ContestFeedBloc extends Bloc<ContestFeedEvent, ContestFeedState> {
  ContestFeedBloc(super.initialState, {ContestRepository? repository})
    : _repo = repository ?? ContestRepository.instance {
    on<ContestFeedInitialEvent>(_onInitial);
    on<ContestFeedRefreshEvent>(_onRefresh);
    on<ContestFeedLoadMoreEvent>(_onLoadMore);
    on<ContestFeedSortChangedEvent>(_onSortChanged);
    on<ContestFeedFeaturedFilterEvent>(_onFeaturedFilter);
    on<ContestFeedToggleLikeEvent>(_onToggleLike);
    on<ContestFeedShareEvent>(_onShare);
    on<ContestFeedRecordViewEvent>(_onRecordView);
    on<ContestFeedClearErrorEvent>(_onClearError);
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

  Future<void> _onSortChanged(
    ContestFeedSortChangedEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    final sort = event.sort == 'likes' ? 'likes' : 'recent';
    if (state.sort == sort) return;
    emit(state.copyWith(sort: sort));
    await _fetchPage(emit, reset: true, showInitialLoader: true);
  }

  Future<void> _onFeaturedFilter(
    ContestFeedFeaturedFilterEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    if (state.featuredOnly == event.featuredOnly) return;
    emit(state.copyWith(featuredOnly: event.featuredOnly));
    await _fetchPage(emit, reset: true, showInitialLoader: true);
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
        clearLoadMoreError: true,
      ),
    );

    final result = await _repo.feedSubmissions(
      page: nextPage,
      perPage: 20,
      contestId: state.contestId,
      featured: state.featuredOnly ? true : null,
      sort: state.sort,
    );
    if (generation != _loadGeneration) return;

    if (result is ContestFailure) {
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: reset ? result.message : null,
          loadMoreError: reset ? null : result.message,
        ),
      );
      return;
    }

    final success = result as ContestSubmissionsResult;
    final merged = reset
        ? success.submissions
        : [...state.items, ...success.submissions];
    final pageMeta = success.page;
    final hasMore = pageMeta?.hasMore ?? (success.submissions.length >= 20);

    emit(
      state.copyWith(
        items: merged,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: hasMore,
        page: pageMeta?.nextPage ?? (reset ? 2 : state.page + 1),
        clearError: true,
        clearLoadMoreError: true,
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
    final previousLikes = current.likesCount ?? 0;

    emit(state.copyWith(likingIds: {...state.likingIds, id}, clearError: true));

    final optimisticLikes = currentlyLiked
        ? (previousLikes > 0 ? previousLikes - 1 : 0)
        : previousLikes + 1;
    final optimistic = current.copyWith(
      isLiked: !currentlyLiked,
      likesCount: optimisticLikes,
    );
    final optimisticItems = [...state.items];
    optimisticItems[index] = optimistic;
    emit(state.copyWith(items: optimisticItems));

    final result = await _repo.toggleSubmissionLike(
      id,
      currentlyLiked: currentlyLiked,
    );

    final likingIds = {...state.likingIds}..remove(id);

    if (result is ContestInteractionResult) {
      final items = [...state.items];
      final idx = items.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        items[idx] = items[idx].applyInteraction(result.state);
      }
      emit(state.copyWith(items: items, likingIds: likingIds));
      return;
    }

    if (result is ContestFailure) {
      if (result.statusCode == 404) {
        final items = [...state.items]..removeWhere((s) => s.id == id);
        emit(
          state.copyWith(
            items: items,
            likingIds: likingIds,
            errorMessage: result.message,
          ),
        );
        return;
      }
      final reverted = [...state.items];
      final idx = reverted.indexWhere((s) => s.id == id);
      if (idx >= 0) reverted[idx] = current;
      emit(
        state.copyWith(
          items: reverted,
          likingIds: likingIds,
          errorMessage: result.message,
        ),
      );
      return;
    }

    emit(state.copyWith(likingIds: likingIds));
  }

  Future<void> _onShare(
    ContestFeedShareEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    final id = event.submissionId;
    if (state.sharingIds.contains(id)) return;

    emit(
      state.copyWith(
        sharingIds: {...state.sharingIds, id},
        clearPendingShare: true,
        clearError: true,
      ),
    );

    final result = await _repo.recordSubmissionShare(
      id,
      channel: event.channel,
      source: event.source,
    );

    final sharingIds = {...state.sharingIds}..remove(id);

    if (result is ContestInteractionResult) {
      final items = [...state.items];
      final idx = items.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        items[idx] = items[idx].applyInteraction(result.state);
      }
      final shareUrl = result.shareUrl?.trim();
      emit(
        state.copyWith(
          items: items,
          sharingIds: sharingIds,
          pendingShareUrl: (shareUrl != null && shareUrl.isNotEmpty)
              ? shareUrl
              : null,
          pendingShareSubmissionId: id,
        ),
      );
      return;
    }

    if (result is ContestFailure) {
      if (result.statusCode == 404) {
        final items = [...state.items]..removeWhere((s) => s.id == id);
        emit(
          state.copyWith(
            items: items,
            sharingIds: sharingIds,
            errorMessage: result.message,
          ),
        );
        return;
      }
      emit(
        state.copyWith(sharingIds: sharingIds, errorMessage: result.message),
      );
      return;
    }

    emit(state.copyWith(sharingIds: sharingIds));
  }

  Future<void> _onRecordView(
    ContestFeedRecordViewEvent event,
    Emitter<ContestFeedState> emit,
  ) async {
    final id = event.submissionId;
    if (id <= 0 || state.viewedIds.contains(id)) return;

    emit(state.copyWith(viewedIds: {...state.viewedIds, id}));

    final result = await _repo.interactSubmission(id, action: 'view');
    if (result is ContestInteractionResult) {
      final items = [...state.items];
      final idx = items.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        items[idx] = items[idx].applyInteraction(result.state);
        emit(state.copyWith(items: items));
      }
    } else if (result is ContestFailure && result.statusCode == 404) {
      final items = [...state.items]..removeWhere((s) => s.id == id);
      emit(state.copyWith(items: items));
    }
  }

  void _onClearError(
    ContestFeedClearErrorEvent event,
    Emitter<ContestFeedState> emit,
  ) {
    emit(
      state.copyWith(
        clearError: true,
        clearLoadMoreError: true,
        clearPendingShare: true,
      ),
    );
  }
}
