import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/advertisement_banner.dart';
import '../../widgets/custom_icon_button.dart';
import 'bloc/screen_1_home_bloc.dart';
import 'models/screen_1_home_model.dart';
import 'widgets/home_ai_studio_section.dart';

/// Musamimuk (مصممك) tutorials on YouTube.
const String _kTutorialsYoutubeChannelUrl =
    'https://www.youtube.com/channel/UCy3n3823yqIwG6FK2ebWrGg';

Future<void> _openTutorialsYoutube(BuildContext context) async {
  final uri = Uri.parse(_kTutorialsYoutubeChannelUrl);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showAppToast(
        'msg_could_not_open_link'.tr,
        type: ToastificationType.error,
      );
    }
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        'msg_could_not_open_link'.tr,
        type: ToastificationType.error,
      );
    }
  }
}

bool _homeUserIsPro() {
  final map = PrefUtils().getUserSession();
  if (map == null) return false;
  final session = UserSession.fromJson(map);
  final raw = session.subscriptionPlan?.trim() ?? '';
  if (raw.isEmpty) return false;
  final s = raw.toLowerCase();
  if (s == '1' || s == 'true' || s == 'yes') return true;
  return s.contains('pro') ||
      s.contains('premium') ||
      s.contains('paid') ||
      s.contains('subscriber') ||
      s.contains('gold') ||
      s.contains('vip');
}

class Screen1HomeScreen extends StatelessWidget {
  const Screen1HomeScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen1HomeBloc>(
      create: (context) => Screen1HomeBloc(
        Screen1HomeState(screen1HomeModelObj: const Screen1HomeModel()),
      )..add(Screen1HomeInitialEvent()),
      child: const Screen1HomeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = PrefUtils().isGuestAccount();
    return ListenableBuilder(
      listenable: appLocaleNotifier,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            drawer: AppNavigationDrawer(
              key: ValueKey<Object>(
                Object.hash(
                  appLocaleNotifier.languageCode,
                  appLocaleNotifier.localeRevision,
                ),
              ),
            ),
            body: Builder(
              builder: (context) {
                return Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDs.space4.h,
                    vertical: AppDs.space6.v,
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final bloc = context.read<Screen1HomeBloc>();
                      bloc.add(Screen1HomeRefreshEvent());
                      await bloc.stream.firstWhere(
                        (state) => !state.isLoadingFeatured,
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRowView(context),
                          SizedBox(height: AppDs.space4.v),
                          BlocBuilder<Screen1HomeBloc, Screen1HomeState>(
                            buildWhen: (prev, next) =>
                                prev.adsRefreshToken != next.adsRefreshToken,
                            builder: (context, state) {
                              return AdvertisementBanner(
                                placement: 'home_banner',
                                limit: 5,
                                aspectRatio: 16 / 5,
                                refreshToken: state.adsRefreshToken,
                              );
                            },
                          ),
                          SizedBox(height: AppDs.space6.v),
                          _buildFeaturedDesigns(context),
                          SizedBox(height: AppDs.space8.v),
                          // AppSectionHeader(
                          //   title: 'lbl_new_design'.tr,
                          //   subtitle: 'msg_choose_from_below'.tr,
                          // ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              AppQuickActionTile(
                                imagePath: ImageConstant.imgPlus,
                                label: 'lbl_new_design'.tr,
                                highlighted: true,
                                onTap: () => onTapBtnPlusone(context),
                              ),
                              AppQuickActionTile(
                                imagePath: ImageConstant.imgAppsAdd1,
                                label: 'lbl_online_designs'.tr,
                                onTap: () => onTapImgAppsaddoneone(context),
                              ),
                              isGuest
                                  ? AppQuickActionTile(
                                      icon: Icons.login,
                                      label: 'lbl_sign_in'.tr,
                                      onTap: () => NavigatorService.pushNamed(
                                        AppRoutes.screen0LoginScreen,
                                      ),
                                    )
                                  : AppQuickActionTile(
                                      imagePath: ImageConstant.imgAppsAdd2,
                                      label: 'lbl_my_designs'.tr,
                                      onTap: () => onTapEyeImage(context),
                                    ),
                            ],
                          ),
                          SizedBox(height: AppDs.space8.v),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              AppQuickActionTile(
                                imagePath: ImageConstant.imgOverflowMenu,
                                label: 'lbl_tutorials'.tr,
                                onTap: () => _openTutorialsYoutube(context),
                              ),
                              AppQuickActionTile(
                                imagePath: ImageConstant.imgQrCodeSvgrepoCom,
                                label: 'msg_generate_qr_code'.tr,
                                onTap: () => NavigatorService.pushNamed(
                                  AppRoutes.enhancedQrGeneratorScreen,
                                ),
                              ),
                              AppQuickActionTile(
                                imagePath: ImageConstant.imgCupStarSvgrepoCom,
                                label: 'lbl_contest'.tr,
                                highlighted: true,
                                onTap: () => NavigatorService.pushNamed(
                                  AppRoutes.screenContestScreen,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppDs.space8.v),
                          HomeAiStudioSection(isPro: _homeUserIsPro()),
                          SizedBox(height: AppDs.space4.v),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            bottomNavigationBar: _HomeBottomNavBar(isGuest: isGuest),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: _HomeNewDesignFab(
              onPressed: () => onTapBtnPlusone(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedDesigns(BuildContext context) {
    return BlocBuilder<Screen1HomeBloc, Screen1HomeState>(
      builder: (context, state) {
        if (state.isLoadingFeatured) {
          return const AppHorizontalListSkeleton();
        }
        if (state.featuredDesigns.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(title: 'lbl_featured'.tr),
            SizedBox(height: AppDs.space3.v),
            SizedBox(
              height: 120.v,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.featuredDesigns.length,
                separatorBuilder: (_, _) => SizedBox(width: AppDs.space3.h),
                itemBuilder: (context, index) {
                  final item = state.featuredDesigns[index];
                  return InkWell(
                    onTap: () => NavigatorService.pushNamed(
                      AppRoutes.screen16OnlineDesignsScreen,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDs.radiusMd.adaptSize,
                      ),
                      child: CustomImageView(
                        imagePath: item.fileUrl,
                        width: 120.h,
                        height: 120.v,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRowView(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: 'msg_home_open_menu'.tr,
          child: Material(
            color: primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14.adaptSize),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.v),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3.v,
                      width: 30.h,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(1.h),
                      ),
                    ),
                    SizedBox(height: 7.v),
                    Container(
                      height: 3.v,
                      width: 19.h,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(1.h),
                      ),
                    ),
                    SizedBox(height: 7.v),
                    Container(
                      height: 3.v,
                      width: 10.h,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(1.h),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        CustomIconButton(
          height: 44.adaptSize,
          width: 44.adaptSize,
          padding: EdgeInsets.all(8.h),
          decoration: IconButtonStyleHelper.fillBlueGray,
          onTap: () {
            NavigatorService.pushNamed(AppRoutes.profileScreen);
          },
          child: CustomImageView(imagePath: ImageConstant.imgLockGray900),
        ),
      ],
    );
  }

  void onTapBtnPlusone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen2NewDesignScreen);
  }

  void onTapTxtNewdesign(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen2NewDesignScreen);
  }

  void onTapImgAppsaddoneone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen16OnlineDesignsScreen);
  }

  void onTapTxtOnlinedesigns(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen16OnlineDesignsScreen);
  }

  void onTapEyeImage(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen18MyDesignsScreen);
  }

  void onTapTxtRemoveText(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen18MyDesignsScreen);
  }

  void onTapEyeImage1(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen19RemoveBackgroundScreen);
  }

  void onTapTxtRemoveText1(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen19RemoveBackgroundScreen);
  }

  void onTapRowPremiumPlan(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen1SubcriptionScreen);
  }
}

class _HomeNewDesignFab extends StatelessWidget {
  const _HomeNewDesignFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return Tooltip(
      message: 'lbl_new_design'.tr,
      child: SizedBox(
        width: 60.adaptSize,
        height: 60.adaptSize,
        child: FloatingActionButton(
          onPressed: onPressed,
          elevation: 4,
          highlightElevation: 8,
          backgroundColor: primary,
          foregroundColor: AppDs.onAccent,
          shape: const CircleBorder(),
          child: Icon(Icons.add_rounded, size: 32.adaptSize),
        ),
      ),
    );
  }
}

class _HomeBottomNavBar extends StatelessWidget {
  const _HomeBottomNavBar({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppDs.surfaceRaised,
      elevation: 8,
      height: 68.v,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _HomeNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'lbl_home'.tr,
                selected: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: _HomeNavItem(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                label: 'lbl_online_designs'.tr,
                onTap: () => NavigatorService.pushNamed(
                  AppRoutes.screen16OnlineDesignsScreen,
                ),
              ),
            ),
            SizedBox(width: 64.h),
            Expanded(
              child: _HomeNavItem(
                icon: Icons.emoji_events_outlined,
                selectedIcon: Icons.emoji_events_rounded,
                label: 'lbl_contest'.tr,
                onTap: () => NavigatorService.pushNamed(
                  AppRoutes.screenContestScreen,
                ),
              ),
            ),
            Expanded(
              child: _HomeNavItem(
                icon: isGuest ? Icons.login : Icons.folder_outlined,
                selectedIcon: isGuest ? Icons.login : Icons.folder_rounded,
                label: isGuest ? 'lbl_sign_in'.tr : 'lbl_my_designs'.tr,
                onTap: () {
                  if (isGuest) {
                    NavigatorService.pushNamed(AppRoutes.screen0LoginScreen);
                  } else {
                    NavigatorService.pushNamed(
                      AppRoutes.screen18MyDesignsScreen,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final color = selected ? primary : AppDs.textOnDarkSecondary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? selectedIcon : icon,
            color: color,
            size: 22.adaptSize,
          ),
          SizedBox(height: 2.v),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.fSize,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
