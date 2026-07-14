part of 'screen_16_online_designs_bloc.dart';

class _UnsetCategory {
  const _UnsetCategory();
}

const _unsetCategory = _UnsetCategory();

class Screen16OnlineDesignsState extends Equatable {
  Screen16OnlineDesignsState({
    this.searchController,
    this.screen16OnlineDesignsModelObj,
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategoryId,
    this.categoryOptions = const [],
  });
  final TextEditingController? searchController;
  final Screen16OnlineDesignsModel? screen16OnlineDesignsModelObj;
  final bool isLoading;
  final String? errorMessage;
  /// When non-null, only designs in this category are shown (after search).
  final int? selectedCategoryId;
  /// Distinct categories from the last successful `GET /designs` response.
  final List<MediaCategoryRef> categoryOptions;
  @override
  List<Object?> get props => [
        searchController,
        screen16OnlineDesignsModelObj,
        isLoading,
        errorMessage,
        selectedCategoryId,
        categoryOptions,
      ];
  Screen16OnlineDesignsState copyWith({
    TextEditingController? searchController,
    Screen16OnlineDesignsModel? screen16OnlineDesignsModelObj,
    bool? isLoading,
    String? errorMessage,
    Object? selectedCategoryId = _unsetCategory,
    List<MediaCategoryRef>? categoryOptions,
  }) {
    return Screen16OnlineDesignsState(
      searchController: searchController ?? this.searchController,
      screen16OnlineDesignsModelObj:
          screen16OnlineDesignsModelObj ?? this.screen16OnlineDesignsModelObj,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategoryId: identical(selectedCategoryId, _unsetCategory)
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      categoryOptions: categoryOptions ?? this.categoryOptions,
    );
  }
}
