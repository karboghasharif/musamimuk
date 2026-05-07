part of 'screen_contesttwo_bloc.dart';

/// Represents the state of ScreenContesttwo in the application.// ignore_for_file: must_be_immutable
class ScreenContesttwoState extends Equatable {
  const ScreenContesttwoState({
    this.screenContesttwoModelObj,
    this.isLoading = false,
    this.errorMessage,
    this.contestName,
    this.bannerUrl,
    this.startDate,
    this.endDate,
    this.acceptedCount,
  });
  final ScreenContesttwoModel? screenContesttwoModelObj;
  final bool isLoading;
  final String? errorMessage;
  final String? contestName;
  final String? bannerUrl;
  final String? startDate;
  final String? endDate;
  final int? acceptedCount;
  @override
  List<Object?> get props => [
        screenContesttwoModelObj,
        isLoading,
        errorMessage,
        contestName,
        bannerUrl,
        startDate,
        endDate,
        acceptedCount,
      ];
  ScreenContesttwoState copyWith(
      {ScreenContesttwoModel? screenContesttwoModelObj,
      bool? isLoading,
      String? errorMessage,
      String? contestName,
      String? bannerUrl,
      String? startDate,
      String? endDate,
      int? acceptedCount}) {
    return ScreenContesttwoState(
      screenContesttwoModelObj:
          screenContesttwoModelObj ?? this.screenContesttwoModelObj,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      contestName: contestName ?? this.contestName,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      acceptedCount: acceptedCount ?? this.acceptedCount,
    );
  }
}
