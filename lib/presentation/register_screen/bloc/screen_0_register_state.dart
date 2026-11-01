part of 'screen_0_register_bloc.dart';

class Screen0RegisterState extends Equatable {
  Screen0RegisterState({
    this.userProfileController,
    this.emailFieldController,
    this.passwordFieldController,
    this.passwordConfirmationController,
    this.isShowPassword = true,
    this.accountType = Screen0RegisterBloc.accountTypeDesigner,
    this.screen0RegisterModelObj,
    this.isLoading = false,
    this.registerError,
    this.registerSuccess = false,
  });
  TextEditingController? userProfileController;
  TextEditingController? emailFieldController;
  TextEditingController? passwordFieldController;
  TextEditingController? passwordConfirmationController;
  Screen0RegisterModel? screen0RegisterModelObj;
  bool isShowPassword;
  /// designer | shop | rider — account signup intent (KYC follows for shop/rider).
  String accountType;
  bool isLoading;
  String? registerError;
  bool registerSuccess;
  @override
  List<Object?> get props => [
        userProfileController,
        emailFieldController,
        passwordFieldController,
        passwordConfirmationController,
        isShowPassword,
        accountType,
        screen0RegisterModelObj,
        isLoading,
        registerError,
        registerSuccess,
      ];
  Screen0RegisterState copyWith({
    TextEditingController? userProfileController,
    TextEditingController? emailFieldController,
    TextEditingController? passwordFieldController,
    TextEditingController? passwordConfirmationController,
    bool? isShowPassword,
    String? accountType,
    Screen0RegisterModel? screen0RegisterModelObj,
    bool? isLoading,
    String? registerError,
    bool? registerSuccess,
  }) {
    return Screen0RegisterState(
      userProfileController:
          userProfileController ?? this.userProfileController,
      emailFieldController: emailFieldController ?? this.emailFieldController,
      passwordFieldController:
          passwordFieldController ?? this.passwordFieldController,
      passwordConfirmationController: passwordConfirmationController ??
          this.passwordConfirmationController,
      isShowPassword: isShowPassword ?? this.isShowPassword,
      accountType: accountType ?? this.accountType,
      screen0RegisterModelObj:
          screen0RegisterModelObj ?? this.screen0RegisterModelObj,
      isLoading: isLoading ?? this.isLoading,
      registerError: registerError,
      registerSuccess: registerSuccess ?? this.registerSuccess,
    );
  }
}
