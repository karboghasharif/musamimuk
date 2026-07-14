import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/repositories/auth_repository.dart';

part 'guest_upgrade_event.dart';
part 'guest_upgrade_state.dart';

/// Converts the current guest session into a full account via `/user/upgrade`.
class GuestUpgradeBloc extends Bloc<GuestUpgradeEvent, GuestUpgradeState> {
  GuestUpgradeBloc(super.initialState, {AuthRepository? repository})
      : _authRepository = repository ?? AuthRepository() {
    on<GuestUpgradeInitialEvent>(_onInitialize);
    on<GuestUpgradePasswordVisibilityEvent>(_onTogglePassword);
    on<GuestUpgradeSubmitEvent>(_onSubmit);
  }

  final AuthRepository _authRepository;

  @override
  Future<void> close() {
    state.nameController?.dispose();
    state.emailController?.dispose();
    state.passwordController?.dispose();
    state.confirmController?.dispose();
    return super.close();
  }

  void _onInitialize(
    GuestUpgradeInitialEvent event,
    Emitter<GuestUpgradeState> emit,
  ) {
    final session = PrefUtils().getUserSession();
    final prefillEmail = session?['email']?.toString();
    final prefillName = session?['name']?.toString();
    emit(state.copyWith(
      nameController: TextEditingController(
        text: (prefillName != null && prefillName.toLowerCase() != 'guest')
            ? prefillName
            : '',
      ),
      emailController: TextEditingController(
        text: (prefillEmail != null && !prefillEmail.contains('@guest.local'))
            ? prefillEmail
            : '',
      ),
      passwordController: TextEditingController(),
      confirmController: TextEditingController(),
      isShowPassword: true,
      errorMessage: null,
    ));
  }

  void _onTogglePassword(
    GuestUpgradePasswordVisibilityEvent event,
    Emitter<GuestUpgradeState> emit,
  ) {
    emit(state.copyWith(isShowPassword: event.value));
  }

  Future<void> _onSubmit(
    GuestUpgradeSubmitEvent event,
    Emitter<GuestUpgradeState> emit,
  ) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await _authRepository.upgradeGuest(
        name: event.name,
        email: event.email,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
        country: event.country,
        imagePath: event.imagePath,
      );
      if (result is RegisterSuccess) {
        final data = result.data.data;
        if (data == null || data.token.isEmpty) {
          emit(state.copyWith(
            isLoading: false,
            errorMessage: result.data.message.isNotEmpty
                ? result.data.message
                : AppLocalization.translate('msg_upgrade_failed'),
          ));
          return;
        }
        final prefs = PrefUtils();
        // Guest token is revoked server-side; replace it and drop guest markers.
        await prefs.setRememberSession(true);
        await prefs.clearOfflineHomeSession();
        await prefs.setToken(data.token);
        if (data.user != null) {
          await prefs.setUserSession(data.user!.toJson());
        }
        emit(state.copyWith(
          isLoading: false,
          errorMessage: null,
          upgradeSuccess: true,
        ));
      } else if (result is RegisterFailure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.message.isNotEmpty
              ? result.message
              : AppLocalization.translate('msg_upgrade_failed'),
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: AppLocalization.translate('msg_upgrade_failed'),
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: AppLocalization.translate('msg_upgrade_failed'),
      ));
    }
  }
}
