part of 'screen_4_add_text_bloc.dart';

/// Abstract class for all events that can be dispatched from the///Screen4AddText widget.////// Events must be immutable and implement the [Equatable] interface.
class Screen4AddTextEvent extends Equatable {
  const Screen4AddTextEvent();

  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Screen4AddText widget is first created.
class Screen4AddTextInitialEvent extends Screen4AddTextEvent {
  const Screen4AddTextInitialEvent();

  @override
  List<Object?> get props => [];
}

class Screen4AddTextSetLanguageEvent extends Screen4AddTextEvent {
  const Screen4AddTextSetLanguageEvent(this.language);

  final AddTextInputLanguage language;

  @override
  List<Object?> get props => [language];
}
