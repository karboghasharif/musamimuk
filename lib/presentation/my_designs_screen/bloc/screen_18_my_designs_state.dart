part of 'screen_18_my_designs_bloc.dart';

class Screen18MyDesignsState extends Equatable {
  Screen18MyDesignsState({
    this.searchController,
    this.screen18MyDesignsModelObj,
    this.isLoading = false,
    this.errorMessage,
    this.visibilityTab = MyDesignsVisibilityTab.public,
    this.deletingDesignId,
    this.deleteFeedback,
    this.folders = const [],
    this.selectedFolderId,
    this.folderFeedback,
  });

  final TextEditingController? searchController;
  final Screen18MyDesignsModel? screen18MyDesignsModelObj;
  final bool isLoading;
  final String? errorMessage;
  final MyDesignsVisibilityTab visibilityTab;
  final int? deletingDesignId;
  final String? deleteFeedback;
  final List<DesignFolder> folders;

  /// `null` = All designs; [DesignFolderStore.unfiledId] = Unfiled; else folder id.
  final String? selectedFolderId;
  final String? folderFeedback;

  @override
  List<Object?> get props => [
        searchController,
        screen18MyDesignsModelObj,
        isLoading,
        errorMessage,
        visibilityTab,
        deletingDesignId,
        deleteFeedback,
        folders,
        selectedFolderId,
        folderFeedback,
      ];

  Screen18MyDesignsState copyWith({
    TextEditingController? searchController,
    Screen18MyDesignsModel? screen18MyDesignsModelObj,
    bool? isLoading,
    String? errorMessage,
    MyDesignsVisibilityTab? visibilityTab,
    int? deletingDesignId,
    bool clearDeletingDesignId = false,
    String? deleteFeedback,
    bool clearDeleteFeedback = false,
    List<DesignFolder>? folders,
    String? selectedFolderId,
    bool clearSelectedFolderId = false,
    String? folderFeedback,
    bool clearFolderFeedback = false,
  }) {
    return Screen18MyDesignsState(
      searchController: searchController ?? this.searchController,
      screen18MyDesignsModelObj:
          screen18MyDesignsModelObj ?? this.screen18MyDesignsModelObj,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      visibilityTab: visibilityTab ?? this.visibilityTab,
      deletingDesignId: clearDeletingDesignId
          ? null
          : (deletingDesignId ?? this.deletingDesignId),
      deleteFeedback: clearDeleteFeedback
          ? null
          : (deleteFeedback ?? this.deleteFeedback),
      folders: folders ?? this.folders,
      selectedFolderId: clearSelectedFolderId
          ? null
          : (selectedFolderId ?? this.selectedFolderId),
      folderFeedback: clearFolderFeedback
          ? null
          : (folderFeedback ?? this.folderFeedback),
    );
  }
}
