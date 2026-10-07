import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/deeplink/app_deep_link_service.dart';
import '../../../data/repositories/app_version_repository.dart';
import '../../force_update/force_update_screen.dart';
import '../models/screen_twentythree_model.dart';
part 'screen_twentythree_event.dart';
part 'screen_twentythree_state.dart';

/// A bloc that manages the state of a ScreenTwentythree according to the event that is dispatched to it.
class ScreenTwentythreeBloc
    extends Bloc<ScreenTwentythreeEvent, ScreenTwentythreeState> {
  ScreenTwentythreeBloc(super.initialState) {
    on<ScreenTwentythreeInitialEvent>(_onInitialize);
  }

  String _launchRoute() {
    if (!PrefUtils().isLoggedIn() || PrefUtils().isGuestAccount()) {
      return AppRoutes.screen1HomeScreen;
    }
    return switch (PrefUtils().getWorkMode()) {
      PrefUtils.workModeShop => AppRoutes.printShopHomeScreen,
      PrefUtils.workModeRider => AppRoutes.printRiderHomeScreen,
      _ => AppRoutes.screen1HomeScreen,
    };
  }

  _onInitialize(
    ScreenTwentythreeInitialEvent event,
    Emitter<ScreenTwentythreeState> emit,
  ) async {
    final gate = await AppVersionRepository().evaluateGate(
      arabic: AppLocalization.activeLanguageCode() == 'ar',
    );
    if (gate.blocked) {
      await NavigatorService.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ForceUpdateScreen(decision: gate),
        ),
        (_) => false,
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 3000));
    if (PrefUtils().isLoggedIn() || PrefUtils().hasOfflineHomeAccess()) {
      await NavigatorService.popAndPushNamed(_launchRoute());
    } else {
      await NavigatorService.popAndPushNamed(AppRoutes.screen0LoginScreen);
    }
    // Apply any cold-start / pending App Link after the root screen is ready.
    AppDeepLinkService.instance.markNavigationReady();
  }
}
