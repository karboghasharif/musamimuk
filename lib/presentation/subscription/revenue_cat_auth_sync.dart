import '../../core/utils/pref_utils.dart';
import '../../data/models/user_session.dart';
import '../../data/services/revenue_cat/revenue_cat_service.dart';

/// Keep RevenueCat identity aligned with Musamimuk auth (login / logout).
Future<void> syncRevenueCatAfterAuth({bool forceAnonymous = false}) async {
  final rc = RevenueCatService.instance;
  if (!rc.isConfigured) return;

  final prefs = PrefUtils();
  if (forceAnonymous || !prefs.isLoggedIn() || prefs.isGuestAccount()) {
    await rc.logOut();
    return;
  }

  final sessionMap = prefs.getUserSession();
  if (sessionMap == null) {
    await rc.logOut();
    return;
  }

  final session = UserSession.fromJson(sessionMap);
  if (session.id <= 0) {
    await rc.logOut();
    return;
  }

  await rc.logIn(session.id.toString());
  await rc.setUserAttributes(
    email: session.email,
    displayName: session.name,
  );
}
