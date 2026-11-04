/// Offline pack category shown in the Design Pack browser.
enum DesignPackCategory {
  borders,
  patterns,
  shapes,
  specialtext,
  emoji,
}

extension DesignPackCategoryX on DesignPackCategory {
  String get layerKind => switch (this) {
        DesignPackCategory.borders => 'design_pack_border',
        DesignPackCategory.patterns => 'design_pack_pattern',
        DesignPackCategory.shapes => 'design_pack_shape',
        DesignPackCategory.specialtext => 'design_pack_specialtext',
        DesignPackCategory.emoji => 'design_pack_emoji',
      };

  String get labelKey => switch (this) {
        DesignPackCategory.borders => 'lbl_design_pack_borders',
        DesignPackCategory.patterns => 'lbl_design_pack_patterns',
        DesignPackCategory.shapes => 'lbl_design_pack_shapes',
        DesignPackCategory.specialtext => 'lbl_design_pack_specialtext',
        DesignPackCategory.emoji => 'lbl_design_pack_emoji',
      };
}

/// One browsable / insertable offline pack asset.
class DesignPackItem {
  const DesignPackItem({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.subcategory,
    this.thumbPath,
  });

  final String id;
  final String name;
  final DesignPackCategory category;
  final String assetPath;
  final String? subcategory;
  final String? thumbPath;

  bool get isSvg => assetPath.toLowerCase().endsWith('.svg');

  String get layerKind => category.layerKind;
}
