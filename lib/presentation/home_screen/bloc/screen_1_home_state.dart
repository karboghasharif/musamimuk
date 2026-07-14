part of 'screen_1_home_bloc.dart';

class Screen1HomeState extends Equatable {
  const Screen1HomeState({
    this.screen1HomeModelObj,
    this.featuredDesigns = const [],
    this.isLoadingFeatured = false,
  });

  final Screen1HomeModel? screen1HomeModelObj;
  final List<MediaItem> featuredDesigns;
  final bool isLoadingFeatured;

  @override
  List<Object?> get props => [
        screen1HomeModelObj,
        featuredDesigns,
        isLoadingFeatured,
      ];

  Screen1HomeState copyWith({
    Screen1HomeModel? screen1HomeModelObj,
    List<MediaItem>? featuredDesigns,
    bool? isLoadingFeatured,
  }) {
    return Screen1HomeState(
      screen1HomeModelObj: screen1HomeModelObj ?? this.screen1HomeModelObj,
      featuredDesigns: featuredDesigns ?? this.featuredDesigns,
      isLoadingFeatured: isLoadingFeatured ?? this.isLoadingFeatured,
    );
  }
}
