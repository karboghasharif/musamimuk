import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_export.dart';
import '../core/utils/app_toast.dart';
import '../data/repositories/auth_repository.dart';
import '../presentation/wallet/wallet_auth_sync.dart';

const _kGooglePlayListingUrl =
    'https://play.google.com/store/apps/details?id=com.musamimuk.app';

const Color kAppNavigationDrawerBackground = Color(0xFF1E2128);

/// Side navigation drawer (dark theme, primary accents) used from Home, editor, etc.
///
/// When [homePopsToRootHome] is true, "Home" clears the stack and opens [AppRoutes.screen1HomeScreen]
/// (use from Add New / deep screens). When false, "Home" only closes the drawer (use on Home).
class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key, this.homePopsToRootHome = false});

  final bool homePopsToRootHome;

  @override
  Widget build(BuildContext context) {
    final session = PrefUtils().getUserSession();
    final rawName = session?['name']?.toString().trim() ?? '';
    final displayName = rawName.isNotEmpty ? rawName : 'lbl_jonathan_saul'.tr;
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'J';
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final isGuest = PrefUtils().isGuestAccount();

    return Drawer(
      backgroundColor: kAppNavigationDrawerBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.h, 28.v, 24.h, 20.v),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    NavigatorService.pushNamed(AppRoutes.profileScreen);
                  },
                  borderRadius: BorderRadius.circular(16.h),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.v),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44.adaptSize,
                          backgroundColor: primary,
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 36.fSize,
                              fontWeight: FontWeight.w700,
                              color: onPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        SizedBox(height: 14.v),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Container(
                height: 2.v,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      primary.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.v),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
                children: [
                  _DrawerNavTile(
                    icon: Icons.home_outlined,
                    label: 'lbl_home'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      if (homePopsToRootHome) {
                        NavigatorService.pushNamedAndRemoveUntil(
                          AppRoutes.screen1HomeScreen,
                          routePredicate: false,
                        );
                      }
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.grid_view_outlined,
                    label: 'lbl_online_designs'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(
                        AppRoutes.screen16OnlineDesignsScreen,
                      );
                    },
                  ),
                  if (!isGuest)
                    _DrawerNavTile(
                      icon: Icons.add_to_photos_outlined,
                      label: 'lbl_my_designs'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        NavigatorService.pushNamed(
                          AppRoutes.screen18MyDesignsScreen,
                        );
                      },
                    ),
                  if (!isGuest)
                    _DrawerNavTile(
                      icon: Icons.favorite_border,
                      label: 'lbl_favorites'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        NavigatorService.pushNamed(AppRoutes.favoritesScreen);
                      },
                    ),
                  if (!isGuest)
                    _DrawerNavTile(
                      icon: Icons.notifications_outlined,
                      label: 'lbl_notifications'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        NavigatorService.pushNamed(
                          AppRoutes.notificationsScreen,
                        );
                      },
                    ),
                  _DrawerNavTile(
                    icon: Icons.qr_code_2_outlined,
                    label: 'msg_generate_qr_code'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(
                        AppRoutes.enhancedQrGeneratorScreen,
                      );
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.hide_image_outlined,
                    label: 'msg_remove_background'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(
                        AppRoutes.screen19RemoveBackgroundScreen,
                      );
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.monetization_on_outlined,
                    label: 'lbl_coin_store'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(AppRoutes.coinStoreScreen);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.workspace_premium_outlined,
                    label: 'lbl_premium_plan'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(
                        AppRoutes.screen1SubcriptionScreen,
                      );
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.tune_rounded,
                    label: 'lbl_settings'.tr,
                    onTap: () => _showLanguageDialog(context),
                  ),
                  _DrawerNavTile(
                    icon: Icons.help_outline_rounded,
                    label: 'lbl_help'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(AppRoutes.aboutUsScreen);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.star_outline,
                    label: 'lbl_rate_app'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      _showRateAppDialog(context);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.info_outline,
                    label: 'lbl_about_us'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(AppRoutes.aboutUsScreen);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.language_outlined,
                    label: 'lbl_language'.tr,
                    onTap: () => _showLanguageDialog(context),
                  ),
                  if (isGuest) ...[
                    _DrawerNavTile(
                      icon: Icons.login,
                      label: 'lbl_sign_in'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        NavigatorService.pushNamed(
                          AppRoutes.screen0LoginScreen,
                        );
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.person_add_outlined,
                      label: 'lbl_create_account'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        NavigatorService.pushNamed(
                          AppRoutes.guestUpgradeScreen,
                        );
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.logout,
                      label: 'lbl_log_out'.tr,
                      onTap: () => _drawerLogout(context),
                    ),
                  ] else
                    _DrawerNavTile(
                      icon: Icons.logout,
                      label: 'lbl_log_out'.tr,
                      onTap: () => _drawerLogout(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.h),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 26.adaptSize),
                SizedBox(width: 18.h),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showLanguageDialog(BuildContext drawerContext) async {
  final current = PrefUtils().getLanguageCode();
  final primary = theme.colorScheme.primary;

  await showDialog<void>(
    context: drawerContext,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: kAppNavigationDrawerBackground,
        title: Text(
          'lbl_language'.tr,
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'lbl_language_system'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: current == null
                  ? Icon(Icons.check, color: primary)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                Navigator.pop(drawerContext);
                await appLocaleNotifier.setLanguageCode(null);
              },
            ),
            ListTile(
              title: Text(
                'lbl_english'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: current == 'en'
                  ? Icon(Icons.check, color: primary)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                Navigator.pop(drawerContext);
                await appLocaleNotifier.setLanguageCode('en');
              },
            ),
            ListTile(
              title: Text(
                'lbl_arabic'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: current == 'ar'
                  ? Icon(Icons.check, color: primary)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                Navigator.pop(drawerContext);
                await appLocaleNotifier.setLanguageCode('ar');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('lbl_cancel'.tr, style: TextStyle(color: primary)),
          ),
        ],
      );
    },
  );
}

Future<void> _showRateAppDialog(BuildContext context) async {
  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final primary = theme.colorScheme.primary;
      final onPrimary = theme.colorScheme.onPrimary;
      return AlertDialog(
        backgroundColor: primary,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'lbl_rate_app'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'msg_rate_app_dialog_body'.tr,
          style: theme.textTheme.bodyLarge?.copyWith(color: onPrimary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: onPrimary),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('lbl_cancel'.tr),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: onPrimary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('lbl_open_play_store'.tr),
          ),
        ],
      );
    },
  );
  if (shouldOpen != true || !context.mounted) return;

  final uri = Uri.parse(_kGooglePlayListingUrl);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showAppToast('lbl_rate_app'.tr, type: ToastificationType.warning);
    }
  } catch (_) {
    if (context.mounted) {
      showAppToast('lbl_rate_app'.tr, type: ToastificationType.warning);
    }
  }
}

Future<void> _drawerLogout(BuildContext context) async {
  Navigator.pop(context);
  try {
    await AuthRepository().logout();
  } catch (_) {}
  try {
    await GoogleSignIn().signOut();
  } catch (_) {}
  syncWalletAfterAuth(forceReset: true);
  await SessionManager.instance.logout();
}
