import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/app_export.dart';
import '../../../data/models/login_request.dart';
import '../../../data/repositories/auth_repository.dart';
import '../models/screen_0_login_model.dart';
part 'screen_0_login_event.dart';
part 'screen_0_login_state.dart';

/// Shared backend account used when the user taps "Continue as guest".
const String _kGuestAccountEmail = 'guest@example.com';
const String _kGuestAccountPassword = 'secret1234';

class Screen0LoginBloc extends Bloc<Screen0LoginEvent, Screen0LoginState> {
  Screen0LoginBloc(super.initialState)
      : _authRepository = AuthRepository(),
        _googleSignIn = GoogleSignIn(
          scopes: const <String>['email', 'profile'],
        ) {
    on<Screen0LoginInitialEvent>(_onInitialize);
    on<ChangePasswordVisibilityEvent>(_changePasswordVisibility);
    on<RememberMeChangedEvent>(_onRememberMeChanged);
    on<LoginSubmitEvent>(_onLoginSubmit);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<ContinueAsGuestEvent>(_onContinueAsGuest);
  }

  final AuthRepository _authRepository;
  final GoogleSignIn _googleSignIn;

  Future<void> _persistLoginSuccess(
    LoginSuccess result, {
    required bool rememberMe,
    String? emailToSaveWhenRemembered,
  }) async {
    final prefs = PrefUtils();
    await prefs.clearOfflineHomeSession();
    await prefs.setRememberSession(rememberMe);
    if (rememberMe &&
        emailToSaveWhenRemembered != null &&
        emailToSaveWhenRemembered.trim().isNotEmpty) {
      await prefs.setSavedLoginEmail(emailToSaveWhenRemembered.trim());
    } else {
      await prefs.setSavedLoginEmail(null);
    }
    await prefs.setToken(result.data.token);
    if (result.data.user != null) {
      await prefs.setUserSession(result.data.user!.toJson());
    }
  }

  @override
  Future<void> close() {
    state.emailController?.dispose();
    state.passwordController?.dispose();
    return super.close();
  }

  _changePasswordVisibility(
    ChangePasswordVisibilityEvent event,
    Emitter<Screen0LoginState> emit,
  ) {
    emit(state.copyWith(isShowPassword: event.value));
  }

  _onRememberMeChanged(
    RememberMeChangedEvent event,
    Emitter<Screen0LoginState> emit,
  ) {
    emit(state.copyWith(rememberMe: event.value));
  }

  _onInitialize(
    Screen0LoginInitialEvent event,
    Emitter<Screen0LoginState> emit,
  ) async {
    await PrefUtils().init();
    final savedEmail = PrefUtils().getSavedLoginEmail();
    final emailController = TextEditingController(text: savedEmail ?? '');
    final passwordController = TextEditingController();
    emit(
      state.copyWith(
        emailController: emailController,
        passwordController: passwordController,
        isShowPassword: true,
        rememberMe: PrefUtils().getRememberSession(),
        loginError: null,
      ),
    );
    // If user already has session, redirect to home
    final token = PrefUtils().getToken();
    if (token != null && token.isNotEmpty) {
      emit(state.copyWith(loginSuccess: true));
    }
  }

  Future<void> _onLoginSubmit(
    LoginSubmitEvent event,
    Emitter<Screen0LoginState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, loginError: null));
    final result = await _authRepository.login(
      LoginRequest(email: event.email, password: event.password),
    );
    if (result is LoginSuccess) {
      await _persistLoginSuccess(
        result,
        rememberMe: event.rememberMe,
        emailToSaveWhenRemembered: event.email,
      );
      emit(
        state.copyWith(isLoading: false, loginError: null, loginSuccess: true),
      );
    } else if (result is LoginFailure) {
      emit(state.copyWith(isLoading: false, loginError: result.message));
    }
  }

  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<Screen0LoginState> emit,
  ) async {
    if (kIsWeb) {
      emit(
        state.copyWith(
          loginError: AppLocalization.translate('msg_google_sign_in_web'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoadingGoogle: true,
        loginError: null,
      ),
    );
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        emit(state.copyWith(isLoadingGoogle: false));
        return;
      }
      final prefs = PrefUtils();
      await prefs.setRememberSession(true);
      await prefs.setGoogleOfflineHomeSession(
        displayName: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
      );
      emit(
        state.copyWith(
          isLoadingGoogle: false,
          loginError: null,
          loginSuccess: true,
        ),
      );
    } on PlatformException catch (e) {
      emit(
        state.copyWith(
          isLoadingGoogle: false,
          loginError: e.message?.isNotEmpty == true
              ? e.message
              : AppLocalization.translate('msg_google_sign_in_failed'),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingGoogle: false,
          loginError: AppLocalization.translate('msg_google_sign_in_failed'),
        ),
      );
    }
  }

  Future<void> _onContinueAsGuest(
    ContinueAsGuestEvent event,
    Emitter<Screen0LoginState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingGuest: true,
        loginError: null,
      ),
    );
    final result = await _authRepository.login(
      LoginRequest(
        email: _kGuestAccountEmail,
        password: _kGuestAccountPassword,
      ),
    );
    if (result is LoginSuccess) {
      await _persistLoginSuccess(
        result,
        rememberMe: true,
        emailToSaveWhenRemembered: null,
      );
      emit(
        state.copyWith(
          isLoadingGuest: false,
          loginError: null,
          loginSuccess: true,
        ),
      );
    } else if (result is LoginFailure) {
      emit(
        state.copyWith(
          isLoadingGuest: false,
          loginError: result.message.isNotEmpty
              ? result.message
              : AppLocalization.translate('msg_guest_login_failed'),
        ),
      );
    }
  }
}
