part of 'screen_18_my_designs_bloc.dart';

class Screen18MyDesignsState extends Equatable {
  Screen18MyDesignsState(
      {this.searchController,
      this.screen18MyDesignsModelObj,
      this.isLoading = false,
      this.errorMessage});
  final TextEditingController? searchController;
  final Screen18MyDesignsModel? screen18MyDesignsModelObj;
  final bool isLoading;
  final String? errorMessage;
  @override
  List<Object?> get props =>
      [searchController, screen18MyDesignsModelObj, isLoading, errorMessage];
  Screen18MyDesignsState copyWith({
    TextEditingController? searchController,
    Screen18MyDesignsModel? screen18MyDesignsModelObj,
    bool? isLoading,
    String? errorMessage,
  }) {
    return Screen18MyDesignsState(
      searchController: searchController ?? this.searchController,
      screen18MyDesignsModelObj:
          screen18MyDesignsModelObj ?? this.screen18MyDesignsModelObj,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
