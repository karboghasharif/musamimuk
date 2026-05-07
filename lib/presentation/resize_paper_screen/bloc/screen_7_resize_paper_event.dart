part of 'screen_7_resize_paper_bloc.dart';

/// Abstract class for all events that can be dispatched from the///Screen7ResizePaper widget.////// Events must be immutable and implement the [Equatable] interface.
class Screen7ResizePaperEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Screen7ResizePaper widget is first created.
class Screen7ResizePaperInitialEvent extends Screen7ResizePaperEvent {
  @override
  List<Object?> get props => [];
}

class ResizePaperUnitSelectedEvent extends Screen7ResizePaperEvent {
  ResizePaperUnitSelectedEvent({required this.unit});
  final SelectionPopupModel unit;
  @override
  List<Object?> get props => [unit];
}
