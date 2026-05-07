part of 'screen_9_background_color_bloc.dart';

/// Abstract class for all events that can be dispatched from the///Screen9BackgroundColor widget.////// Events must be immutable and implement the [Equatable] interface.
class Screen9BackgroundColorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Screen9BackgroundColor widget is first created.
class Screen9BackgroundColorInitialEvent extends Screen9BackgroundColorEvent {
  @override
  List<Object?> get props => [];
}
