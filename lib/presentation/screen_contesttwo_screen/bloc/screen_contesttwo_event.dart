part of 'screen_contesttwo_bloc.dart';

/// Abstract class for all events that can be dispatched from the///ScreenContesttwo widget.////// Events must be immutable and implement the [Equatable] interface.
class ScreenContesttwoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the ScreenContesttwo widget is first created.
class ScreenContesttwoInitialEvent extends ScreenContesttwoEvent {
  ScreenContesttwoInitialEvent({
    required this.contestId,
    this.contestFromList,
  });
  final int contestId;
  /// Header fields from [GET /api/contest/list] (avoids GET /api/contest/:id).
  final ContestItem? contestFromList;
  @override
  List<Object?> get props => [contestId, contestFromList];
}
