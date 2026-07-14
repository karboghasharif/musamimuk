part of 'guest_upgrade_bloc.dart';

sealed class GuestUpgradeEvent extends Equatable {
  const GuestUpgradeEvent();

  @override
  List<Object?> get props => [];
}

class GuestUpgradeInitialEvent extends GuestUpgradeEvent {
  const GuestUpgradeInitialEvent();
}

class GuestUpgradePasswordVisibilityEvent extends GuestUpgradeEvent {
  const GuestUpgradePasswordVisibilityEvent(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

class GuestUpgradeSubmitEvent extends GuestUpgradeEvent {
  const GuestUpgradeSubmitEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.country = '',
    this.imagePath,
  });

  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String country;
  final String? imagePath;

  @override
  List<Object?> get props =>
      [name, email, password, passwordConfirmation, country, imagePath];
}
