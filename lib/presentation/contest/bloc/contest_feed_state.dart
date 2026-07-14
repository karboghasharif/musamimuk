part of 'contest_feed_bloc.dart';

class ContestFeedState extends Equatable {
  const ContestFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.errorMessage,
    this.likingIds = const {},
  });

  final List<ContestSubmission> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final Set<int> likingIds;

  ContestFeedState copyWith({
    List<ContestSubmission>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
    Set<int>? likingIds,
  }) {
    return ContestFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      likingIds: likingIds ?? this.likingIds,
    );
  }

  @override
  List<Object?> get props => [
        items,
        isLoading,
        isRefreshing,
        isLoadingMore,
        hasMore,
        page,
        errorMessage,
        likingIds,
      ];
}
