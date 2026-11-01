part of 'screen_0_register_bloc.dart';

class Screen0RegisterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class Screen0RegisterInitialEvent extends Screen0RegisterEvent {
  @override
  List<Object?> get props => [];
}

class ChangePasswordVisibilityEvent extends Screen0RegisterEvent {
  ChangePasswordVisibilityEvent({required this.value});
  bool value;
  @override
  List<Object?> get props => [value];
}

class ChangeRegisterAccountTypeEvent extends Screen0RegisterEvent {
  ChangeRegisterAccountTypeEvent({required this.accountType});
  final String accountType;
  @override
  List<Object?> get props => [accountType];
}

class RegisterSubmitEvent extends Screen0RegisterEvent {
  RegisterSubmitEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  @override
  List<Object?> get props => [
        name,
        email,
        password,
        passwordConfirmation,
      ];
}
