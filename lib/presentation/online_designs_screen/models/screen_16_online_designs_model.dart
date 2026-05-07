import 'package:equatable/equatable.dart';
import 'category_design_group_model.dart';
import 'listsection_item_model.dart';
import 'rectanglelistsection_item_model.dart';

class Screen16OnlineDesignsModel extends Equatable {
  Screen16OnlineDesignsModel({
    this.rectanglelistsectionItemList = const [],
    this.listsectionItemList = const [],
    this.featuredImageUrls = const [],
    this.featuredTiles = const [],
    this.forYouGroupedSections = const [],
  });
  final List<RectanglelistsectionItemModel> rectanglelistsectionItemList;
  final List<ListsectionItemModel> listsectionItemList;
  /// First up to 3 design thumbnails for the hero row (catalog API).
  final List<String> featuredImageUrls;
  /// Same designs as [featuredImageUrls], with metadata for preview / badges.
  final List<RectanglelistsectionItemModel> featuredTiles;
  /// When "For you" is selected: one section per category with [CategoryDesignGroupModel.items].
  final List<CategoryDesignGroupModel> forYouGroupedSections;
  Screen16OnlineDesignsModel copyWith({
    List<RectanglelistsectionItemModel>? rectanglelistsectionItemList,
    List<ListsectionItemModel>? listsectionItemList,
    List<String>? featuredImageUrls,
    List<RectanglelistsectionItemModel>? featuredTiles,
    List<CategoryDesignGroupModel>? forYouGroupedSections,
  }) {
    return Screen16OnlineDesignsModel(
      rectanglelistsectionItemList:
          rectanglelistsectionItemList ?? this.rectanglelistsectionItemList,
      listsectionItemList: listsectionItemList ?? this.listsectionItemList,
      featuredImageUrls: featuredImageUrls ?? this.featuredImageUrls,
      featuredTiles: featuredTiles ?? this.featuredTiles,
      forYouGroupedSections:
          forYouGroupedSections ?? this.forYouGroupedSections,
    );
  }

  @override
  List<Object?> get props => [
        rectanglelistsectionItemList,
        listsectionItemList,
        featuredImageUrls,
        featuredTiles,
        forYouGroupedSections,
      ];
}
