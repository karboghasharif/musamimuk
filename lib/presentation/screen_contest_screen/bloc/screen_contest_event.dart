part of 'screen_contest_bloc.dart';

/// Abstract class for all events that can be dispatched from the///ScreenContest widget.////// Events must be immutable and implement the [Equatable] interface.
class ScreenContestEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the ScreenContest widget is first created.
class ScreenContestInitialEvent extends ScreenContestEvent {
  @override
  List<Object?> get props => [];
}

/// Loads contest list from API.
class ScreenContestLoadEvent extends ScreenContestEvent {
  ScreenContestLoadEvent({this.forceRefresh = false});
  final bool forceRefresh;
  @override
  List<Object?> get props => [forceRefresh];
}
