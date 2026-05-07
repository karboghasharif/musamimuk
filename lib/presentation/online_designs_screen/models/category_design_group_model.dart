import 'package:equatable/equatable.dart';
import 'rectanglelistsection_item_model.dart';

/// Designs under one category heading (used when "For you" shows all designs).
class CategoryDesignGroupModel extends Equatable {
  const CategoryDesignGroupModel({
    required this.categoryHeading,
    required this.categoryId,
    required this.items,
  });

  final String categoryHeading;
  final int categoryId;
  final List<RectanglelistsectionItemModel> items;

  @override
  List<Object?> get props => [categoryHeading, categoryId, items];
}
