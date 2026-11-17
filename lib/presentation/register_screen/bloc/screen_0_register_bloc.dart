import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/app_export.dart';
import '../../../data/models/login_request.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../notifications/notification_inbox_controller.dart';
import '../../print/print_open_orders_sync.dart';
import '../../subscription/push_auth_sync.dart';
import '../../subscription/revenue_cat_auth_sync.dart';
import '../../wallet/wallet_auth_sync.dart';
import '../models/screen_0_register_model.dart';
part 'screen_0_register_event.dart';
part 'screen_0_register_state.dart';

class Screen0RegisterBloc
    extends Bloc<Screen0RegisterEvent, Screen0RegisterState> {
  Screen0RegisterBloc(
    super.initialState, {
    AuthRepository? authRepository,
    GoogleSignIn? googleSignIn,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const <String>['email', 'profile', 'openid'],
            ) {
    on<Screen0RegisterInitialEvent>(_onInitialize);
    on<ChangePasswordVisibilityEvent>(_changePasswordVisibility);
    on<ChangeRegisterAccountTypeEvent>(_changeAccountType);
    on<RegisterSubmitEvent>(_onRegisterSubmit);
    on<RegisterWithGoogleEvent>(_onRegisterWithGoogle);
    on<ContinueExistingSessionEvent>(_onContinueExistingSession);
  }

  static const String accountTypeDesigner = 'designer';
  static const String accountTypeShop = 'shop';
  static const String accountTypeRider = 'rider';

  final AuthRepository _authRepository;
  final GoogleSignIn _googleSignIn;

  bool get _authBusy => state.isLoading || state.isLoadingGoogle;

  @override
  Future<void> close() {
    state.userProfileController?.dispose();
    state.emailFieldController?.dispose();
    state.passwordFieldController?.dispose();
    state.passwordConfirmationController?.dispose();
    state.referralCodeController?.dispose();
    return super.close();
  }

  _changePasswordVisibility(
    ChangePasswordVisibilityEvent event,
    Emitter<Screen0RegisterState> emit,
  ) {
    emit(state.copyWith(
      isShowPassword: event.value,
    ));
  }

  void _changeAccountType(
    ChangeRegisterAccountTypeEvent event,
    Emitter<Screen0RegisterState> emit,
  ) {
    final type = event.accountType;
    if (type != accountTypeDesigner &&
        type != accountTypeShop &&
        type != accountTypeRider) {
      return;
    }
    emit(state.copyWith(accountType: type));
  }

  _onInitialize(
    Screen0RegisterInitialEvent event,
    Emitter<Screen0RegisterState> emit,
  ) async {
    final pending = PrefUtils().getPendingReferralCode() ?? '';
    final prefs = PrefUtils();
    final token = prefs.getToken();
    final hasSession = token != null &&
        token.isNotEmpty &&
        !prefs.isGuestAccount();
    emit(state.copyWith(
      userProfileController: TextEditingController(),
      emailFieldController: TextEditingController(),
      passwordFieldController: TextEditingController(),
      passwordConfirmationController: TextEditingController(),
      referralCodeController: TextEditingController(text: pending),
      isShowPassword: true,
      accountType: accountTypeDesigner,
      hasExistingSession: hasSession,
      registerError: null,
    ));
  }

  Future<void> _onContinueExistingSession(
    ContinueExistingSessionEvent event,
    Emitter<Screen0RegisterState> emit,
  ) async {
    if (_authBusy) return;
    final prefs = PrefUtils();
    final token = prefs.getToken();
    if (token == null || token.isEmpty || prefs.isGuestAccount()) {
      emit(state.copyWith(
        registerError: AppLocalization.translate('msg_session_required'),
      ));
      return;
    }
    if (state.accountType != accountTypeShop &&
        state.accountType != accountTypeRider) {
      emit(state.copyWith(
        registerError:
            AppLocalization.translate('msg_register_pick_shop_or_rider'),
      ));
      return;
    }
    emit(state.copyWith(isLoading: true, registerError: null));
    await _applyWorkModeForAccountType(prefs);
    syncPrintOpenOrdersAfterAuth();
    NotificationInboxController.instance.start();
    emit(state.copyWith(
      isLoading: false,
      registerError: null,
      registerSuccess: true,
      hasExistingSession: true,
    ));
  }

  Future<void> _onRegisterSubmit(
    RegisterSubmitEvent event,
    Emitter<Screen0RegisterState> emit,
  ) async {
    if (_authBusy) return;

    // Same Google/email account already signed in → attach shop/rider profile.
    final prefs = PrefUtils();
    final existingToken = prefs.getToken();
    if (existingToken != null &&
        existingToken.isNotEmpty &&
        !prefs.isGuestAccount() &&
        (state.accountType == accountTypeShop ||
            state.accountType == accountTypeRider)) {
      await _onContinueExistingSession(
        ContinueExistingSessionEvent(),
        emit,
      );
      return;
    }

    emit(state.copyWith(isLoading: true, registerError: null));
    try {
      final result = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
        referralCode: event.referralCode,
      );
      if (result is RegisterSuccess) {
        await _finishWithRegisterSuccess(result, emit);
        return;
      }
      if (result is RegisterFailure) {
        // Email already exists (e.g. prior Google shop login) → sign in and continue.
        if (_isEmailAlreadyTaken(result.message)) {
          final loginResult = await _authRepository.login(
            LoginRequest(email: event.email, password: event.password),
          );
          if (loginResult is LoginSuccess) {
            await _finishWithLoginSuccess(loginResult, emit);
            return;
          }
          if (loginResult is LoginFailure) {
            emit(state.copyWith(
              isLoading: false,
              registerError: AppLocalization.translate(
                'msg_email_exists_use_login_or_google',
              ),
            ));
            return;
          }
        }
        emit(state.copyWith(
          isLoading: false,
          registerError: result.message,
        ));
        return;
      }
      emit(state.copyWith(
        isLoading: false,
        registerError: 'Registration failed',
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        registerError: 'Registration failed',
      ));
    }
  }

  Future<void> _onRegisterWithGoogle(
    RegisterWithGoogleEvent event,
    Emitter<Screen0RegisterState> emit,
  ) async {
    if (_authBusy) return;
    if (kIsWeb) {
      emit(state.copyWith(
        registerError: AppLocalization.translate('msg_google_sign_in_web'),
      ));
      return;
    }
    emit(state.copyWith(
      isLoadingGoogle: true,
      registerError: null,
    ));
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        emit(state.copyWith(isLoadingGoogle: false));
        return;
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken?.trim();
      final accessToken = googleAuth.accessToken?.trim();
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        emit(state.copyWith(
          isLoadingGoogle: false,
          registerError:
              AppLocalization.translate('msg_google_sign_in_no_token'),
        ));
        return;
      }

      final result = await _authRepository.googleLogin(
        idToken: idToken,
        accessToken: accessToken,
      );
      if (result is LoginSuccess) {
        await _finishWithLoginSuccess(
          result,
          emit,
          emailToSave: account.email,
        );
        return;
      }
      if (result is LoginFailure) {
        emit(state.copyWith(
          isLoadingGoogle: false,
          registerError: result.message.isNotEmpty
              ? result.message
              : AppLocalization.translate('msg_google_sign_in_failed'),
        ));
        return;
      }
      emit(state.copyWith(
        isLoadingGoogle: false,
        registerError: AppLocalization.translate('msg_google_sign_in_failed'),
      ));
    } on PlatformException catch (e) {
      debugPrint(
        'GoogleSignIn PlatformException: code=${e.code} message=${e.message}',
      );
      emit(state.copyWith(
        isLoadingGoogle: false,
        registerError: _googleSignInErrorMessage(e),
      ));
    } catch (e, st) {
      debugPrint('GoogleSignIn failed: $e\n$st');
      emit(state.copyWith(
        isLoadingGoogle: false,
        registerError: AppLocalization.translate('msg_google_sign_in_failed'),
      ));
    }
  }

  Future<void> _finishWithRegisterSuccess(
    RegisterSuccess result,
    Emitter<Screen0RegisterState> emit,
  ) async {
    final prefs = PrefUtils();
    await prefs.clearOfflineHomeSession();
    await prefs.setRememberSession(true);
    final data = result.data.data;
    if (data == null || data.token.isEmpty) {
      emit(state.copyWith(
        isLoading: false,
        isLoadingGoogle: false,
        registerError: result.data.message.isNotEmpty
            ? result.data.message
            : 'Registration failed',
      ));
      return;
    }
    await prefs.setToken(data.token);
    if (data.user != null) {
      await prefs.setUserSession(data.user!.toJson());
    }
    syncWalletAfterAuth(walletFromAuth: data.wallet);
    // ignore: unawaited_futures
    syncRevenueCatAfterAuth();
    // ignore: unawaited_futures
    syncPushTokenAfterAuth();
    await _applyWorkModeForAccountType(prefs);
    syncPrintOpenOrdersAfterAuth();
    NotificationInboxController.instance.start();
    emit(state.copyWith(
      isLoading: false,
      isLoadingGoogle: false,
      registerError: null,
      registerSuccess: true,
      hasExistingSession: true,
    ));
  }

  Future<void> _finishWithLoginSuccess(
    LoginSuccess result,
    Emitter<Screen0RegisterState> emit, {
    String? emailToSave,
  }) async {
    final prefs = PrefUtils();
    await prefs.clearOfflineHomeSession();
    await prefs.setRememberSession(true);
    if (emailToSave != null && emailToSave.trim().isNotEmpty) {
      await prefs.setSavedLoginEmail(emailToSave.trim());
    }
    await prefs.setToken(result.data.token);
    if (result.data.user != null) {
      await prefs.setUserSession(result.data.user!.toJson());
    }
    syncWalletAfterAuth(walletFromAuth: result.data.wallet);
    // ignore: unawaited_futures
    syncRevenueCatAfterAuth();
    // ignore: unawaited_futures
    syncPushTokenAfterAuth();
    await _applyWorkModeForAccountType(prefs);
    syncPrintOpenOrdersAfterAuth();
    NotificationInboxController.instance.start();
    emit(state.copyWith(
      isLoading: false,
      isLoadingGoogle: false,
      registerError: null,
      registerSuccess: true,
      hasExistingSession: true,
    ));
  }

  Future<void> _applyWorkModeForAccountType(PrefUtils prefs) async {
    if (state.accountType == accountTypeShop) {
      // Optimistic flag so the switcher offers Design during first-time KYC.
      await prefs.setHasPrintShopProfile(true);
      await prefs.setWorkMode(PrefUtils.workModeShop);
    } else if (state.accountType == accountTypeRider) {
      await prefs.setHasPrintRiderProfile(true);
      await prefs.setWorkMode(PrefUtils.workModeRider);
    } else {
      await prefs.setWorkMode(PrefUtils.workModeNormal);
    }
  }

  bool _isEmailAlreadyTaken(String message) {
    final lower = message.toLowerCase();
    const markers = [
      'already been taken',
      'already taken',
      'already exists',
      'email has already',
      'email already',
      'unique',
      'duplicate',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  String _googleSignInErrorMessage(PlatformException e) {
    final code = e.code.toLowerCase();
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
}
