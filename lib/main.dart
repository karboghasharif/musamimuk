import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:musamimuk/presentation/add_new_screen/bloc/add_new_bloc.dart';
import 'package:toastification/toastification.dart';

import 'core/app_export.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/guest_upgrade/guest_upgrade_prompt.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const startupBackground = Color(0xFF252A30);
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: startupBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  // Load token + user session before any screen or ApiClient request reads prefs.
  await PrefUtils().init();
  final prefs = PrefUtils();
  if (!prefs.getRememberSession()) {
    await prefs.clearAuth();
  } else if (prefs.isLoggedIn() && !prefs.isGuestAccount()) {
    final sessionRes = await AuthRepository().refreshSession();
    if (sessionRes is ProfileSuccess) {
      await prefs.setUserSession(sessionRes.user.toJson());
    } else if (!prefs.isLoggedIn()) {
      // Session refresh failed and auth was cleared — splash routes to Login.
    } else if (sessionRes is ProfileFailure) {
      // Network or other non-expiry failure: keep cached session for offline use.
    }
  }
  appLocaleNotifier.syncFromPrefs();
  // Route guest 403s (account-only actions) to the upgrade prompt.
  SessionManager.instance.guestForbiddenHandler =
      (message) => showGuestUpgradePrompt(message);
  runApp(const MyApp());
}

/// [ListenableBuilder] wraps only [MaterialApp] so locale changes rebuild
/// routes without recreating [BlocProvider] trees above it.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AddNewBloc>(
              create: (context) => AddNewBloc(AddNewState()),
            ),
          ],
          child: BlocProvider(
            create: (context) =>
                ThemeBloc(ThemeState(themeType: PrefUtils().getThemeData())),
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return ListenableBuilder(
                  listenable: appLocaleNotifier,
                  builder: (context, _) {
                    final code = appLocaleNotifier.languageCode;
                    final Locale? localeOverride =
                        (code == 'ar' || code == 'en') ? Locale(code!) : null;

                    return ToastificationWrapper( 
                      config: const ToastificationConfig(
                        alignment: Alignment.bottomCenter,
                      ),
                      child: MaterialApp(
                        key: ValueKey<int>(appLocaleNotifier.localeRevision),
                        theme: theme,
                        title: 'Musamimuk',
                        navigatorKey: NavigatorService.navigatorKey,
                        debugShowCheckedModeBanner: false,
                        localizationsDelegates: const [
                          AppLocalizationDelegate(),
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        supportedLocales: const [Locale('en'), Locale('ar')],
                        locale: localeOverride,
                        localeListResolutionCallback: localeOverride != null
                            ? null
                            : (locales, supported) =>
                                  AppLocalization.resolveMatchingLocale(
                                    locales,
                                    supported.toList(growable: false),
                                  ),
                        navigatorObservers: [AppRouteObserver.instance],
                        builder: (context, child) {
                          AppLocalization.setMaterialAppBuilderContext(context);
                          return ListenableBuilder(
                            listenable: GlobalLoadingController.instance,
                            builder: (context, _) {
                              final loading =
                                  GlobalLoadingController.instance.isLoading;
                              return AppLoadingOverlay(
                                isLoading: loading,
                                message:
                                    GlobalLoadingController.instance.message,
                                child: child ?? const SizedBox.shrink(),
                              );
                            },
                          );
                        },
                        initialRoute: AppRoutes.initialRoute,
                        routes: AppRoutes.routes,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
