import 'dart:async';

import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/category_item.dart';
import '../../../data/models/contest_item.dart';
import '../../../data/repositories/contest_repository.dart';
import '../models/certificatedesign_item_model.dart';
import '../models/screen_contest_model.dart';
part 'screen_contest_event.dart';
part 'screen_contest_state.dart';

class ScreenContestBloc extends Bloc<ScreenContestEvent, ScreenContestState> {
  ScreenContestBloc(
    super.initialState, {
    ContestRepository? repository,
  }) : _repo = repository ?? ContestRepository.instance {
    on<ScreenContestInitialEvent>(_onInitialize);
    on<ScreenContestLoadEvent>(_onLoad);
    on<ScreenContestFilterEvent>(_onFilter);
  }

  final ContestRepository _repo;
  int _loadGeneration = 0;
  Timer? _searchDebounce;

  Future<void> _onInitialize(
    ScreenContestInitialEvent event,
    Emitter<ScreenContestState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await _loadCategories(emit);
    if (!emit.isDone) {
      add(ScreenContestLoadEvent());
    }
  }

  Future<void> _loadCategories(Emitter<ScreenContestState> emit) async {
    final result = await _repo.categoryList();
    if (emit.isDone) return;
    if (result is ContestCategoriesResult) {
      emit(state.copyWith(categories: result.categories));
    }
  }

  Future<void> _onFilter(
    ScreenContestFilterEvent event,
    Emitter<ScreenContestState> emit,
  ) async {
    _searchDebounce?.cancel();
    emit(
      state.copyWith(
        clearCategoryFilter: event.updateCategory && event.categoryId == null,
        selectedCategoryId: event.updateCategory
            ? event.categoryId
            : state.selectedCategoryId,
        selectedStatus: event.updateStatus
            ? (event.status ?? 'all')
            : state.selectedStatus,
        searchQuery: event.search ?? state.searchQuery,
        currentPage: 1,
      ),
    );
    if (event.search != null) {
      _searchDebounce = Timer(const Duration(milliseconds: 400), () {
        add(ScreenContestLoadEvent(forceRefresh: true));
      });
      return;
    }
    add(ScreenContestLoadEvent(forceRefresh: true));
  }

  Future<void> _onLoad(
    ScreenContestLoadEvent event,
    Emitter<ScreenContestState> emit,
  ) async {
    final generation = ++_loadGeneration;
    final loadMore = event.loadMore;
    final page = loadMore ? state.currentPage + 1 : 1;

    emit(
      state.copyWith(
        isLoading: !loadMore,
        isLoadingMore: loadMore,
        errorMessage: null,
        currentPage: loadMore ? state.currentPage : 1,
      ),
    );

    try {
      final search = state.searchQuery.trim();
      final ContestResult result;
      if (search.isNotEmpty && !PrefUtils().isGuestAccount()) {
        result = await _repo.search(
          query: search,
          page: page,
          categoryId: state.selectedCategoryId,
          status: state.selectedStatus == 'all' ? null : state.selectedStatus,
        );
      } else {
        result = await _repo.publicList(
          page: page,
          categoryId: state.selectedCategoryId,
          status: state.selectedStatus == 'all' ? null : state.selectedStatus,
          search: search.isEmpty ? null : search,
        );
      }

      if (generation != _loadGeneration) return;

      if (result is ContestFailure) {
        emit(state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: result.message,
        ));
        return;
      }

      final success = result as ContestListResult;
      final mapped = success.items.map(_mapContestToUi).toList();
      final existing = loadMore
          ? List<CertificatedesignItemModel>.from(
              state.screenContestModelObj?.contestItemList ?? const [],
            )
          : <CertificatedesignItemModel>[];

      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: null,
        hasMore: success.page?.hasMore ?? false,
        currentPage: page,
        screenContestModelObj:
            (state.screenContestModelObj ?? const ScreenContestModel()).copyWith(
          contestItemList: [...existing, ...mapped],
        ),
      ));
    } catch (_) {
      if (generation != _loadGeneration) return;
      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: 'Something went wrong',
      ));
    }
  }

  CertificatedesignItemModel _mapContestToUi(ContestItem c) {
    final prize = c.prizeDisplay;

    return CertificatedesignItemModel(
      certificateText: c.name,
      image: c.fileUrl,
      id: c.id.toString(),
      contestJson: c.toJson(),
      showResultAnnounced: isContestResultsAnnounced(c, hasWinners: false),
      status: c.status,
      countdown: c.countdown,
      prizeText: prize.isEmpty ? null : prize,
      participantsCount: c.participantsCount,
      submissionsCount: c.submissionsCount,
      categoryName: c.category?.name,
      dateRange: formatContestDateRangeDisplay(c.startDate, c.endDate),
      primaryAction: c.user?.actionKey,
      hasJoined: c.user?.joined ?? false,
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
