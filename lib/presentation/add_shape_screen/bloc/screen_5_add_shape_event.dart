part of 'screen_5_add_shape_bloc.dart';

/// Abstract class for all events that can be dispatched from the///Screen5AddShape widget.////// Events must be immutable and implement the [Equatable] interface.
class Screen5AddShapeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event that is dispatched when the Screen5AddShape widget is first created.
class Screen5AddShapeInitialEvent extends Screen5AddShapeEvent {
  @override
  List<Object?> get props => [];
}

///event for OTP auto fill// ignore_for_file: must_be_immutable
class ChangeOTPEvent extends Screen5AddShapeEvent {
  ChangeOTPEvent({required this.code});
  String code;
  @override
  List<Object?> get props => [code];
}
