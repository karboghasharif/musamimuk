part of 'screen_contesttwo_bloc.dart';

class ScreenContesttwoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScreenContesttwoInitialEvent extends ScreenContesttwoEvent {
  ScreenContesttwoInitialEvent({
    required this.contestId,
    this.contestFromList,
  });
  final int contestId;
  final ContestItem? contestFromList;
  @override
  List<Object?> get props => [contestId, contestFromList];
}

class ScreenContesttwoRefreshEvent extends ScreenContesttwoEvent {
  ScreenContesttwoRefreshEvent({
    required this.contestId,
    this.contestFromList,
  });
  final int contestId;
  final ContestItem? contestFromList;
  @override
  List<Object?> get props => [contestId, contestFromList];
}

class ScreenContesttwoJoinEvent extends ScreenContesttwoEvent {
  ScreenContesttwoJoinEvent({required this.contestId});
  final int contestId;
  @override
  List<Object?> get props => [contestId];
}

class ScreenContesttwoActionEvent extends ScreenContesttwoEvent {
  ScreenContesttwoActionEvent({required this.actionKey, required this.contestId});
  final String actionKey;
  final int contestId;
  @override
  List<Object?> get props => [actionKey, contestId];
}

class ScreenContesttwoClearPendingEvent extends ScreenContesttwoEvent {}
