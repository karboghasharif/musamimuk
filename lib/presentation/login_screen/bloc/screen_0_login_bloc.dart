import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/app_export.dart';
import '../../../data/models/login_request.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../wallet/wallet_auth_sync.dart';
import '../models/screen_0_login_model.dart';
part 'screen_0_login_event.dart';
part 'screen_0_login_state.dart';

class Screen0LoginBloc extends Bloc<Screen0LoginEvent, Screen0LoginState> {
  Screen0LoginBloc({
    AuthRepository? authRepository,
    GoogleSignIn? googleSignIn,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const <String>['email', 'profile'],
            ),
        super(
          Screen0LoginState(
            screen0LoginModelObj: const Screen0LoginModel(),
            emailController: TextEditingController(
              text: PrefUtils().getSavedLoginEmail() ?? '',
            ),
            passwordController: TextEditingController(),
            rememberMe: PrefUtils().getRememberSession(),
          ),
        ) {
    on<Screen0LoginInitialEvent>(_onInitialize);
    on<ChangePasswordVisibilityEvent>(_changePasswordVisibility);
    on<RememberMeChangedEvent>(_onRememberMeChanged);
    on<LoginSubmitEvent>(_onLoginSubmit);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<LoginWithAppleEvent>(_onLoginWithApple);
    on<ContinueAsGuestEvent>(_onContinueAsGuest);
  }

  final AuthRepository _authRepository;
  final GoogleSignIn _googleSignIn;

  bool get _authBusy =>
      state.isLoading ||
      state.isLoadingGoogle ||
      state.isLoadingApple ||
      state.isLoadingGuest;

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
    syncWalletAfterAuth(walletFromAuth: result.data.wallet);
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
    // Controllers are created in the constructor so Login never races prefs init.
    // Clear any stuck app-wide overlay that would absorb taps on this screen.
    GlobalLoadingController.instance.reset();
    await PrefUtils().init();
    final savedEmail = PrefUtils().getSavedLoginEmail();
    final emailController = state.emailController;
    if (emailController != null &&
        savedEmail != null &&
        savedEmail.isNotEmpty &&
        emailController.text.trim().isEmpty) {
      emailController.text = savedEmail;
    }
    emit(
      state.copyWith(
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
    if (_authBusy) return;
    emit(state.copyWith(isLoading: true, loginError: null));
    try {
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
          state.copyWith(
            isLoading: false,
            loginError: null,
            loginSuccess: true,
          ),
        );
      } else if (result is LoginFailure) {
        emit(state.copyWith(isLoading: false, loginError: result.message));
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            loginError: 'Something went wrong',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          loginError: 'Something went wrong',
        ),
      );
    }
  }

  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<Screen0LoginState> emit,
  ) async {
    if (_authBusy) return;
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
      // Clear a stale Google session so the account picker appears again.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

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
      debugPrint('GoogleSignIn PlatformException: code=${e.code} message=${e.message}');
      emit(
        state.copyWith(
          isLoadingGoogle: false,
          loginError: _googleSignInErrorMessage(e),
        ),
      );
    } catch (e, st) {
      debugPrint('GoogleSignIn failed: $e\n$st');
      emit(
        state.copyWith(
          isLoadingGoogle: false,
          loginError: AppLocalization.translate('msg_google_sign_in_failed'),
        ),
      );
    }
  }

  String _googleSignInErrorMessage(PlatformException e) {
    final code = e.code.toLowerCase();
    // Android DEVELOPER_ERROR / common misconfig codes.
    if (code == 'sign_in_failed' ||
        code == '10' ||
        code.contains('developer') ||
        (e.message?.contains('ApiException: 10') ?? false) ||
        (e.message?.contains('DEVELOPER_ERROR') ?? false)) {
      return AppLocalization.translate('msg_google_sign_in_misconfigured');
    }
    if (e.message?.isNotEmpty == true) return e.message!;
    return AppLocalization.translate('msg_google_sign_in_failed');
  }

  Future<void> _onLoginWithApple(
    LoginWithAppleEvent event,
    Emitter<Screen0LoginState> emit,
  ) async {
    if (_authBusy) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      emit(
        state.copyWith(
          loginError: AppLocalization.translate('msg_apple_sign_in_unavailable'),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoadingApple: true,
        loginError: null,
      ),
    );
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        emit(
          state.copyWith(
            isLoadingApple: false,
            loginError:
                AppLocalization.translate('msg_apple_sign_in_unavailable'),
          ),
        );
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final given = credential.givenName?.trim() ?? '';
      final family = credential.familyName?.trim() ?? '';
      final displayName = [given, family]
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim();

      final prefs = PrefUtils();
      await prefs.setRememberSession(true);
      await prefs.setAppleOfflineHomeSession(
        displayName: displayName.isEmpty ? null : displayName,
        email: credential.email,
      );
      emit(
        state.copyWith(
          isLoadingApple: false,
          loginError: null,
          loginSuccess: true,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('AppleSignIn auth exception: ${e.code} ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(state.copyWith(isLoadingApple: false));
        return;
      }
      emit(
        state.copyWith(
          isLoadingApple: false,
          loginError: e.message.isNotEmpty
              ? e.message
              : AppLocalization.translate('msg_apple_sign_in_failed'),
        ),
      );
    } catch (e, st) {
      debugPrint('AppleSignIn failed: $e\n$st');
      emit(
        state.copyWith(
          isLoadingApple: false,
          loginError: AppLocalization.translate('msg_apple_sign_in_failed'),
        ),
      );
    }
  }

  Future<void> _onContinueAsGuest(
    ContinueAsGuestEvent event,
    Emitter<Screen0LoginState> emit,
  ) async {
    if (_authBusy) return;
    emit(
      state.copyWith(
        isLoadingGuest: true,
        loginError: null,
      ),
    );
    try {
      final prefs = PrefUtils();
      final deviceId = await prefs.getOrCreateDeviceId();
      final result = await _authRepository.guestLogin(deviceId);
      if (result is LoginSuccess) {
        await prefs.setRememberSession(true);
        await prefs.setSavedLoginEmail(null);
        // Keep the legacy local marker so splash / offline gates still work.
        await prefs.markGuestOfflineHome();
        await prefs.setToken(result.data.token);
        if (result.data.user != null) {
          await prefs.setUserSession(result.data.user!.toJson());
        }
        syncWalletAfterAuth();
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
      } else {
        emit(
          state.copyWith(
            isLoadingGuest: false,
            loginError: AppLocalization.translate('msg_guest_login_failed'),
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingGuest: false,
          loginError: AppLocalization.translate('msg_guest_login_failed'),
        ),
      );
    }
  }
}
