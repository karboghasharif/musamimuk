part of 'screen_0_login_bloc.dart';

class Screen0LoginState extends Equatable {
  Screen0LoginState({
    this.emailController,
    this.passwordController,
    this.isShowPassword = true,
    this.rememberMe = true,
    this.screen0LoginModelObj,
    this.isLoading = false,
    this.isLoadingGoogle = false,
    this.isLoadingApple = false,
    this.isLoadingGuest = false,
    this.loginError,
    this.loginSuccess = false,
  });
  TextEditingController? emailController;
  TextEditingController? passwordController;
  Screen0LoginModel? screen0LoginModelObj;
  bool isShowPassword;
  bool rememberMe;
  bool isLoading;
  bool isLoadingGoogle;
  bool isLoadingApple;
  bool isLoadingGuest;
  String? loginError;
  bool loginSuccess;
  @override
  List<Object?> get props => [
        emailController,
        passwordController,
        isShowPassword,
        rememberMe,
        screen0LoginModelObj,
        isLoading,
        isLoadingGoogle,
        isLoadingApple,
        isLoadingGuest,
        loginError,
        loginSuccess,
      ];
  Screen0LoginState copyWith({
    TextEditingController? emailController,
    TextEditingController? passwordController,
    bool? isShowPassword,
    bool? rememberMe,
    Screen0LoginModel? screen0LoginModelObj,
    bool? isLoading,
    bool? isLoadingGoogle,
    bool? isLoadingApple,
    bool? isLoadingGuest,
    String? loginError,
    bool? loginSuccess,
  }) {
    return Screen0LoginState(
      emailController: emailController ?? this.emailController,
      passwordController: passwordController ?? this.passwordController,
      isShowPassword: isShowPassword ?? this.isShowPassword,
      rememberMe: rememberMe ?? this.rememberMe,
      screen0LoginModelObj: screen0LoginModelObj ?? this.screen0LoginModelObj,
      isLoading: isLoading ?? this.isLoading,
      isLoadingGoogle: isLoadingGoogle ?? this.isLoadingGoogle,
      isLoadingApple: isLoadingApple ?? this.isLoadingApple,
      isLoadingGuest: isLoadingGuest ?? this.isLoadingGuest,
      loginError: loginError,
      loginSuccess: loginSuccess ?? this.loginSuccess,
    );
  }
}
