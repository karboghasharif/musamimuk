part of 'screen_1_home_bloc.dart';

class Screen1HomeState extends Equatable {
  const Screen1HomeState({
    this.screen1HomeModelObj,
    this.featuredDesigns = const [],
    this.isLoadingFeatured = false,
    this.adsRefreshToken = 0,
  });

  final Screen1HomeModel? screen1HomeModelObj;
  final List<MediaItem> featuredDesigns;
  final bool isLoadingFeatured;

  /// Bumped on pull-to-refresh so [AdvertisementBanner] refetches.
  final int adsRefreshToken;

  @override
  List<Object?> get props => [
    screen1HomeModelObj,
    featuredDesigns,
    isLoadingFeatured,
    adsRefreshToken,
  ];

  Screen1HomeState copyWith({
    Screen1HomeModel? screen1HomeModelObj,
    List<MediaItem>? featuredDesigns,
    bool? isLoadingFeatured,
    int? adsRefreshToken,
  }) {
    return Screen1HomeState(
      screen1HomeModelObj: screen1HomeModelObj ?? this.screen1HomeModelObj,
      featuredDesigns: featuredDesigns ?? this.featuredDesigns,
      isLoadingFeatured: isLoadingFeatured ?? this.isLoadingFeatured,
      adsRefreshToken: adsRefreshToken ?? this.adsRefreshToken,
    );
  }
}
