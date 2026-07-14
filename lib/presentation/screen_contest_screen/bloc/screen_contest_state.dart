part of 'screen_contest_bloc.dart';

class ScreenContestState extends Equatable {
  const ScreenContestState({
    this.screenContestModelObj,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.categories = const [],
    this.selectedCategoryId,
    this.selectedStatus = 'all',
    this.searchQuery = '',
    this.hasMore = false,
    this.currentPage = 1,
  });

  final ScreenContestModel? screenContestModelObj;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<CategoryItem> categories;
  final int? selectedCategoryId;
  final String selectedStatus;
  final String searchQuery;
  final bool hasMore;
  final int currentPage;

  @override
  List<Object?> get props => [
        screenContestModelObj,
        isLoading,
        isLoadingMore,
        errorMessage,
        categories,
        selectedCategoryId,
        selectedStatus,
        searchQuery,
        hasMore,
        currentPage,
      ];

  ScreenContestState copyWith({
    ScreenContestModel? screenContestModelObj,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    List<CategoryItem>? categories,
    int? selectedCategoryId,
    bool clearCategoryFilter = false,
    String? selectedStatus,
    String? searchQuery,
    bool? hasMore,
    int? currentPage,
  }) {
    return ScreenContestState(
      screenContestModelObj:
          screenContestModelObj ?? this.screenContestModelObj,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategoryFilter
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}
