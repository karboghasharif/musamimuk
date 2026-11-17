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
    this.referralCode,
  });
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? referralCode;
  @override
  List<Object?> get props => [
        name,
        email,
        password,
        passwordConfirmation,
        referralCode,
      ];
}

/// Sign in / create account with Google, then continue to the selected role KYC.
class RegisterWithGoogleEvent extends Screen0RegisterEvent {}

/// Already signed-in non-guest user continues to shop/rider KYC without re-registering.
class ContinueExistingSessionEvent extends Screen0RegisterEvent {}
