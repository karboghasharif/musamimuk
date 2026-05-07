part of 'screen_twentythree_bloc.dart';

/// Abstract class for all events that can be dispatched from the///ScreenTwentythree widget.////// Events must be immutable and implement the [Equatable] interface.
class ScreenTwentythreeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the ScreenTwentythree widget is first created.
class ScreenTwentythreeInitialEvent extends ScreenTwentythreeEvent {
  @override
  List<Object?> get props => [];
}
