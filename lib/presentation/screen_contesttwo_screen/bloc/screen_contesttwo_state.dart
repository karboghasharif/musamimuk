part of 'screen_contesttwo_bloc.dart';

class ScreenContesttwoState extends Equatable {
  const ScreenContesttwoState({
    this.screenContesttwoModelObj,
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.contestName,
    this.bannerUrl,
    this.startDate,
    this.endDate,
    this.acceptedCount,
    this.submittedCount,
    this.rejectedCount,
    this.participantsCount,
    this.prizeText,
    this.status,
    this.resultsAnnounced = false,
    this.detail,
    this.pendingAction,
  });

  final ScreenContesttwoModel? screenContesttwoModelObj;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final String? contestName;
  final String? bannerUrl;
  final String? startDate;
  final String? endDate;
  final int? acceptedCount;
  final int? submittedCount;
  final int? rejectedCount;
  final int? participantsCount;
  final String? prizeText;
  final String? status;
  final bool resultsAnnounced;
  final ContestDetail? detail;
  final String? pendingAction;

  @override
  List<Object?> get props => [
        screenContesttwoModelObj,
        isLoading,
        isActionLoading,
        errorMessage,
        contestName,
        bannerUrl,
        startDate,
        endDate,
        acceptedCount,
        submittedCount,
        rejectedCount,
        participantsCount,
        prizeText,
        status,
        resultsAnnounced,
        detail,
        pendingAction,
      ];

  ScreenContesttwoState copyWith({
    ScreenContesttwoModel? screenContesttwoModelObj,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    String? contestName,
    String? bannerUrl,
    String? startDate,
    String? endDate,
    int? acceptedCount,
    int? submittedCount,
    int? rejectedCount,
    int? participantsCount,
    String? prizeText,
    String? status,
    bool? resultsAnnounced,
    ContestDetail? detail,
    String? pendingAction,
    bool clearPendingAction = false,
  }) {
    return ScreenContesttwoState(
      screenContesttwoModelObj:
          screenContesttwoModelObj ?? this.screenContesttwoModelObj,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: errorMessage,
      contestName: contestName ?? this.contestName,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      submittedCount: submittedCount ?? this.submittedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      participantsCount: participantsCount ?? this.participantsCount,
      prizeText: prizeText ?? this.prizeText,
      status: status ?? this.status,
      resultsAnnounced: resultsAnnounced ?? this.resultsAnnounced,
      detail: detail ?? this.detail,
      pendingAction:
          clearPendingAction ? null : (pendingAction ?? this.pendingAction),
    );
  }
}
