part of 'guest_upgrade_bloc.dart';

// ignore_for_file: must_be_immutable
class GuestUpgradeState extends Equatable {
  GuestUpgradeState({
    this.nameController,
    this.emailController,
    this.passwordController,
    this.confirmController,
    this.isShowPassword = true,
    this.isLoading = false,
    this.errorMessage,
    this.upgradeSuccess = false,
  });

  TextEditingController? nameController;
  TextEditingController? emailController;
  TextEditingController? passwordController;
  TextEditingController? confirmController;
  bool isShowPassword;
  bool isLoading;
  String? errorMessage;
  bool upgradeSuccess;

  GuestUpgradeState copyWith({
    TextEditingController? nameController,
    TextEditingController? emailController,
    TextEditingController? passwordController,
    TextEditingController? confirmController,
    bool? isShowPassword,
    bool? isLoading,
    String? errorMessage,
    bool? upgradeSuccess,
  }) {
    return GuestUpgradeState(
      nameController: nameController ?? this.nameController,
      emailController: emailController ?? this.emailController,
      passwordController: passwordController ?? this.passwordController,
      confirmController: confirmController ?? this.confirmController,
      isShowPassword: isShowPassword ?? this.isShowPassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      upgradeSuccess: upgradeSuccess ?? this.upgradeSuccess,
    );
  }

  @override
  List<Object?> get props => [
        nameController,
        emailController,
        passwordController,
        confirmController,
        isShowPassword,
        isLoading,
        errorMessage,
        upgradeSuccess,
      ];
}
