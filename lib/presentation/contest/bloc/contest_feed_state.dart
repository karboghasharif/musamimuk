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
    this.loadMoreError,
    this.likingIds = const {},
    this.sharingIds = const {},
    this.viewedIds = const {},
    this.sort = 'recent',
    this.featuredOnly = false,
    this.contestId,
    this.pendingShareUrl,
    this.pendingShareSubmissionId,
  });

  final List<ContestSubmission> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final String? loadMoreError;
  final Set<int> likingIds;
  final Set<int> sharingIds;
  final Set<int> viewedIds;
  final String sort;
  final bool featuredOnly;
  final int? contestId;

  /// Set after a successful share API call so the UI can open the share sheet.
  final String? pendingShareUrl;
  final int? pendingShareSubmissionId;

  ContestFeedState copyWith({
    List<ContestSubmission>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    String? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
    Set<int>? likingIds,
    Set<int>? sharingIds,
    Set<int>? viewedIds,
    String? sort,
    bool? featuredOnly,
    int? contestId,
    bool clearContestId = false,
    String? pendingShareUrl,
    int? pendingShareSubmissionId,
    bool clearPendingShare = false,
  }) {
    return ContestFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
      likingIds: likingIds ?? this.likingIds,
      sharingIds: sharingIds ?? this.sharingIds,
      viewedIds: viewedIds ?? this.viewedIds,
      sort: sort ?? this.sort,
      featuredOnly: featuredOnly ?? this.featuredOnly,
      contestId: clearContestId ? null : (contestId ?? this.contestId),
      pendingShareUrl: clearPendingShare
          ? null
          : (pendingShareUrl ?? this.pendingShareUrl),
      pendingShareSubmissionId: clearPendingShare
          ? null
          : (pendingShareSubmissionId ?? this.pendingShareSubmissionId),
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
    loadMoreError,
    likingIds,
    sharingIds,
    viewedIds,
    sort,
    featuredOnly,
    contestId,
    pendingShareUrl,
    pendingShareSubmissionId,
  ];
}
