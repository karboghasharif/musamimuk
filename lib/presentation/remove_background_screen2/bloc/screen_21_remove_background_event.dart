part of 'screen_21_remove_background_bloc.dart';

/// Abstract class for all events that can be dispatched from the///Screen21RemoveBackground widget.////// Events must be immutable and implement the [Equatable] interface.
class Screen21RemoveBackgroundEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Event that is dispatched when the Screen21RemoveBackground widget is first created.
class Screen21RemoveBackgroundInitialEvent
    extends Screen21RemoveBackgroundEvent {
  @override
  List<Object?> get props => [];
}
