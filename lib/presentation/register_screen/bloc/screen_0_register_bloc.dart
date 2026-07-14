import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/repositories/auth_repository.dart';
import '../models/screen_0_register_model.dart';
part 'screen_0_register_event.dart';
part 'screen_0_register_state.dart';

class Screen0RegisterBloc
    extends Bloc<Screen0RegisterEvent, Screen0RegisterState> {
  Screen0RegisterBloc(super.initialState) : _authRepository = AuthRepository() {
    on<Screen0RegisterInitialEvent>(_onInitialize);
    on<ChangePasswordVisibilityEvent>(_changePasswordVisibility);
    on<RegisterSubmitEvent>(_onRegisterSubmit);
  }

  final AuthRepository _authRepository;

  @override
  Future<void> close() {
    state.userProfileController?.dispose();
    state.emailFieldController?.dispose();
    state.passwordFieldController?.dispose();
    state.passwordConfirmationController?.dispose();
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

  _onInitialize(
    Screen0RegisterInitialEvent event,
    Emitter<Screen0RegisterState> emit,
  ) async {
    emit(state.copyWith(
      userProfileController: TextEditingController(),
      emailFieldController: TextEditingController(),
      passwordFieldController: TextEditingController(),
      passwordConfirmationController: TextEditingController(),
      isShowPassword: true,
      registerError: null,
    ));
  }

  Future<void> _onRegisterSubmit(
    RegisterSubmitEvent event,
    Emitter<Screen0RegisterState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, registerError: null));
    try {
      final result = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
      );
      if (result is RegisterSuccess) {
        final prefs = PrefUtils();
        await prefs.clearOfflineHomeSession();
        await prefs.setRememberSession(true);
        final data = result.data.data;
        if (data == null || data.token.isEmpty) {
          emit(state.copyWith(
            isLoading: false,
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
        emit(state.copyWith(
          isLoading: false,
          registerError: null,
          registerSuccess: true,
        ));
      } else if (result is RegisterFailure) {
        emit(state.copyWith(
          isLoading: false,
          registerError: result.message,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          registerError: 'Registration failed',
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        registerError: 'Registration failed',
      ));
    }
  }
}
