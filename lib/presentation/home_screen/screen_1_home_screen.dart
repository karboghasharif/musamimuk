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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRowView(context),
                        SizedBox(height: AppDs.space4.v),
                        AdvertisementBanner(
                          placement: 'home_banner',
                          limit: 5,
                          height: 120.v,
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
                        // AppSectionHeader(title: 'lbl_help'.tr),
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
                              imagePath: ImageConstant.imgEyeOnprimarycontainer,
                              label: 'msg_remove_background'.tr,
                              onTap: () => onTapEyeImage1(context),
                            ),
                          ],
                        ),
                        SizedBox(height: AppDs.space8.v),
                        Center(
                          child: AppQuickActionTile(
                            imagePath: ImageConstant.imgCupStarSvgrepoCom,
                            label: 'lbl_contest'.tr,
                            highlighted: true,
                            onTap: () => NavigatorService.pushNamed(
                              AppRoutes.screenContestScreen,
                            ),
                          ),
                        ),
                        SizedBox(height: AppDs.space8.v),
                        if (!isGuest) ...[
                          _buildRowPremiumPlan(context),
                          SizedBox(height: AppDs.space4.v),
                        ],
                        _buildRowSettingsAndHelp(context),
                        SizedBox(height: AppDs.space4.v),
                      ],
                    ),
                  ),
                );
              },
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

  Widget _buildRowPremiumPlan(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final isPro = _homeUserIsPro();

    return AppCard(
      elevated: true,
      onTap: () => onTapRowPremiumPlan(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgStarCircleSvgrepoCom,
            height: 46.adaptSize,
            width: 46.adaptSize,
          ),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'lbl_premium_plan'.tr,
                        variant: AppTextVariant.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDs.space2.h,
                        vertical: AppDs.space1.v,
                      ),
                      decoration: BoxDecoration(
                        color: isPro
                            ? primary
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppDs.radiusFull.adaptSize,
                        ),
                      ),
                      child: AppText(
                        isPro ? 'lbl_pro'.tr : 'lbl_free'.tr,
                        variant: AppTextVariant.caption,
                        color: isPro ? onPrimary : AppDs.textOnDarkPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDs.space1.v),
                AppText(
                  'msg_upgrade_to_access'.tr,
                  variant: AppTextVariant.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: primary, size: 28.adaptSize),
        ],
      ),
    );
  }

  Widget _buildRowSettingsAndHelp(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _HomeFooterActionCard(
            icon: Icons.tune_rounded,
            title: 'lbl_settings'.tr,
            subtitle: 'msg_home_settings_subtitle'.tr,
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        SizedBox(width: AppDs.space3.h),
        Expanded(
          child: _HomeFooterActionCard(
            icon: Icons.help_outline_rounded,
            title: 'lbl_help'.tr,
            subtitle: 'msg_home_help_subtitle'.tr,
            onTap: () => NavigatorService.pushNamed(AppRoutes.aboutUsScreen),
          ),
        ),
      ],
    );
  }

  onTapBtnPlusone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen2NewDesignScreen);
  }

  onTapTxtNewdesign(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen2NewDesignScreen);
  }

  onTapImgAppsaddoneone(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen16OnlineDesignsScreen);
  }

  onTapTxtOnlinedesigns(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen16OnlineDesignsScreen);
  }

  onTapEyeImage(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen18MyDesignsScreen);
  }

  onTapTxtRemoveText(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen18MyDesignsScreen);
  }

  onTapEyeImage1(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen19RemoveBackgroundScreen);
  }

  onTapTxtRemoveText1(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen19RemoveBackgroundScreen);
  }

  onTapRowPremiumPlan(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.screen1SubcriptionScreen);
  }
}

class _HomeFooterActionCard extends StatelessWidget {
  const _HomeFooterActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppDs.space2.adaptSize),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
            ),
            child: Icon(icon, color: primary, size: 22.adaptSize),
          ),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, variant: AppTextVariant.title, maxLines: 1),
                SizedBox(height: AppDs.space1.v),
                AppText(
                  subtitle,
                  variant: AppTextVariant.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
