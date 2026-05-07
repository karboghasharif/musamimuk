part of 'screen_contest_bloc.dart';

/// Represents the state of ScreenContest in the application.// ignore_for_file: must_be_immutable
class ScreenContestState extends Equatable {
  const ScreenContestState({
    this.screenContestModelObj,
    this.isLoading = false,
    this.errorMessage,
  });
  final ScreenContestModel? screenContestModelObj;
  final bool isLoading;
  final String? errorMessage;
  @override
  List<Object?> get props => [screenContestModelObj, isLoading, errorMessage];
  ScreenContestState copyWith({
    ScreenContestModel? screenContestModelObj,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ScreenContestState(
      screenContestModelObj:
          screenContestModelObj ?? this.screenContestModelObj,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
