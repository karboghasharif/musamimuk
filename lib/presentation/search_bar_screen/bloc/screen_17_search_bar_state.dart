part of 'screen_17_search_bar_bloc.dart';

class Screen17SearchBarState extends Equatable {
  Screen17SearchBarState(
      {this.searchController,
      this.screen17SearchBarModelObj,
      this.isLoading = false,
      this.errorMessage,
      this.results = const []});
  final TextEditingController? searchController;
  final Screen17SearchBarModel? screen17SearchBarModelObj;
  final bool isLoading;
  final String? errorMessage;
  final List<MediaItem> results;
  @override
  List<Object?> get props => [
        searchController,
        screen17SearchBarModelObj,
        isLoading,
        errorMessage,
        results,
      ];
  Screen17SearchBarState copyWith({
    TextEditingController? searchController,
    Screen17SearchBarModel? screen17SearchBarModelObj,
    bool? isLoading,
    String? errorMessage,
    List<MediaItem>? results,
  }) {
    return Screen17SearchBarState(
      searchController: searchController ?? this.searchController,
      screen17SearchBarModelObj:
          screen17SearchBarModelObj ?? this.screen17SearchBarModelObj,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      results: results ?? this.results,
    );
  }
}
