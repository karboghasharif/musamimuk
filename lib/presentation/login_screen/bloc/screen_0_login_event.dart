part of 'screen_0_login_bloc.dart';

class Screen0LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class Screen0LoginInitialEvent extends Screen0LoginEvent {
  @override
  List<Object?> get props => [];
}

class ChangePasswordVisibilityEvent extends Screen0LoginEvent {
  ChangePasswordVisibilityEvent({required this.value});
  bool value;
  @override
  List<Object?> get props => [value];
}

class RememberMeChangedEvent extends Screen0LoginEvent {
  RememberMeChangedEvent({required this.value});
  final bool value;
  @override
  List<Object?> get props => [value];
}

class LoginSubmitEvent extends Screen0LoginEvent {
  LoginSubmitEvent({
    required this.email,
    required this.password,
    required this.rememberMe,
  });
  final String email;
  final String password;
  final bool rememberMe;
  @override
  List<Object?> get props => [email, password, rememberMe];
}

class LoginWithGoogleEvent extends Screen0LoginEvent {
  @override
  List<Object?> get props => [];
}

class LoginWithAppleEvent extends Screen0LoginEvent {
  @override
  List<Object?> get props => [];
}

class ContinueAsGuestEvent extends Screen0LoginEvent {
  @override
  List<Object?> get props => [];
}
