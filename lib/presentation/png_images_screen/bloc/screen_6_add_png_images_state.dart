part of 'screen_6_add_png_images_bloc.dart';

/// Represents the state of Screen6AddPngImages in the application.// ignore_for_file: must_be_immutable
class Screen6AddPngImagesState extends Equatable {
  Screen6AddPngImagesState(
      {this.searchController, this.screen6AddPngImagesModelObj});
  TextEditingController? searchController;
  Screen6AddPngImagesModel? screen6AddPngImagesModelObj;
  @override
  List<Object?> get props => [searchController, screen6AddPngImagesModelObj];
  Screen6AddPngImagesState copyWith({
    TextEditingController? searchController,
    Screen6AddPngImagesModel? screen6AddPngImagesModelObj,
  }) {
    return Screen6AddPngImagesState(
      searchController: searchController ?? this.searchController,
      screen6AddPngImagesModelObj:
          screen6AddPngImagesModelObj ?? this.screen6AddPngImagesModelObj,
    );
  }
}
