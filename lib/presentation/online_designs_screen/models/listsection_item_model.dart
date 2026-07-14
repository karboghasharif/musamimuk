class ListsectionItemModel {
  ListsectionItemModel({
    this.rectangle,
    this.id,
    this.name,
    this.isFeatured = false,
    this.tier,
    this.previewDetails,
    this.categoryName,
    this.downloadsCount,
    this.trendingScore,
    this.designDataRaw,
    this.width,
    this.height,
  });

  String? rectangle;
  String? id;
  String? name;
  bool isFeatured;
  String? tier;
  String? previewDetails;
  String? categoryName;
  int? downloadsCount;
  int? trendingScore;
  String? designDataRaw;
  int? width;
  int? height;
}
