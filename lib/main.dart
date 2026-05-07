import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:musamimuk/presentation/add_new_screen/bloc/add_new_bloc.dart';
import 'package:toastification/toastification.dart';

import 'core/app_export.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]);
  // Load token + user session before any screen or ApiClient request reads prefs.
  await PrefUtils().init();
  final prefs = PrefUtils();
  if (!prefs.getRememberSession()) {
    await prefs.clearAuth();
  }
  appLocaleNotifier.syncFromPrefs();
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
                        builder: (context, child) {
                          AppLocalization.setMaterialAppBuilderContext(context);
                          return child ?? const SizedBox.shrink();
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
