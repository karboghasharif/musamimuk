import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../widgets/app_navigation_drawer.dart';
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
                    horizontal: 27.h,
                    vertical: 46.v,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 3.v),
                        _buildRowView(context),
                        SizedBox(height: 5.v),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 24.h),
                            child: SizedBox(
                              width: 480.h,
                              height: 151.v,
                              child: const _HomeAdvertisingSlider(),
                            ),
                          ),
                        ),
                        SizedBox(height: 60.v),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 23.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 1.v),
                                child: _buildColumnEyeOne(
                                  context,
                                  eyeImage: ImageConstant.imgPlus,
                                  removeText: "lbl_new_design".tr,
                                  onTap: () {
                                    onTapBtnPlusone(context);
                                  },
                                ),
                              ),
                            // Column(
                            //   children: [
                            //     CustomIconButton(
                            //       height: 31.adaptSize,
                            //       width: 31.adaptSize,
                            //       decoration:
                            //           IconButtonStyleHelper.fillOnPrimaryContainer,
                            //       onTap: () {
                            //         onTapBtnPlusone(context);
                            //       },
                            //       child: CustomImageView(
                            //         imagePath: ImageConstant.imgPlus,
                            //       ),
                            //     ),
                            //     SizedBox(height: 19.v),
                            //     GestureDetector(
                            //       onTap: () {
                            //         onTapTxtNewdesign(context);
                            //       },
                            //       child: Text(
                            //         "lbl_new_design".tr,
                            //         style: CustomTextStyles.bodySmallInter,
                            //       ),
                            //     )
                            //   ],
                            // ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 1.v),
                                child: Column(
                                  children: [
                                    CustomImageView(
                                      imagePath: ImageConstant.imgAppsAdd1,
                                      height: 34.adaptSize,
                                      width: 34.adaptSize,
                                      onTap: () {
                                        onTapImgAppsaddoneone(context);
                                      },
                                    ),
                                    SizedBox(height: 17.v),
                                    GestureDetector(
                                      onTap: () {
                                        onTapTxtOnlinedesigns(context);
                                      },
                                      child: Text(
                                        "lbl_online_designs".tr,
                                        style: CustomTextStyles.bodySmallInter,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 1.v),
                                child: _buildColumnEyeOne(
                                  context,
                                  eyeImage: ImageConstant.imgAppsAdd2,
                                  removeText: "lbl_my_designs".tr,
                                  onTap: () {
                                    onTapEyeImage(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 41.v),
                        Padding(
                          padding: EdgeInsets.only(left: 31.h, right: 22.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 13.v),
                                child: Column(
                                  children: [
                                    CustomIconButton(
                                      height: 38.v,
                                      width: 40.h,
                                      padding: EdgeInsets.all(3.h),
                                      onTap: () =>
                                          _openTutorialsYoutube(context),
                                      child: CustomImageView(
                                        imagePath:
                                            ImageConstant.imgOverflowMenu,
                                      ),
                                    ),
                                    SizedBox(height: 13.v),
                                    GestureDetector(
                                      onTap: () =>
                                          _openTutorialsYoutube(context),
                                      child: Text(
                                        "lbl_tutorials".tr,
                                        style: CustomTextStyles.bodySmallInter,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 53),
                              InkWell(
                                onTap: () {
                                  NavigatorService.pushNamed(
                                    AppRoutes.enhancedQrGeneratorScreen,
                                  );
                                },
                                child: Column(
                                  children: [
                                    CustomImageView(
                                      imagePath:
                                          ImageConstant.imgQrCodeSvgrepoCom,
                                      height: 33.adaptSize,
                                      width: 33.adaptSize,
                                    ),
                                    SizedBox(height: 13.v),
                                    SizedBox(
                                      width: 73.h,
                                      child: Text(
                                        "msg_generate_qr_code".tr,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: CustomTextStyles.bodySmallInter,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 46),
                              Padding(
                                padding: EdgeInsets.only(bottom: 1.v),
                                child: _buildColumnEyeOne(
                                  context,
                                  eyeImage:
                                      ImageConstant.imgEyeOnprimarycontainer,
                                  removeText: "msg_remove_background".tr,
                                  onTap: () {
                                    onTapEyeImage1(context);
                                  },
                                ),
                              ),
                            // Expanded(
                            //   child: _buildColumnEyeOne(
                            //     context,
                            //     eyeImage: ImageConstant.imgEyeOnprimarycontainer,
                            //     removeText: "msg_remove_background".tr,
                            //     onTapEyeImage: () {
                            //       onTapEyeImage1(context);
                            //     },
                            //     onTapRemoveText: () {
                            //       onTapTxtRemoveText1(context);
                            //     },
                            //   ),
                            // )
                            ],
                          ),
                        ),
                        SizedBox(height: 35.v),
                        InkWell(
                          onTap: () {
                            NavigatorService.pushNamed(
                              AppRoutes.screenContestScreen,
                            );
                          },
                          child: CustomImageView(
                            imagePath: ImageConstant.imgCupStarSvgrepoCom,
                            height: 35.adaptSize,
                            width: 35.adaptSize,
                          ),
                        ),
                        SizedBox(height: 10.v),
                        Text(
                          "lbl_contest".tr,
                          style: CustomTextStyles.bodySmallInter,
                        ),
                        SizedBox(height: 24.v),
                        _buildRowPremiumPlan(context),
                        SizedBox(height: 17.v),
                        _buildRowSettingsAndHelp(context),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTapRowPremiumPlan(context),
        borderRadius: BorderRadius.circular(12.adaptSize),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.v),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.adaptSize),
            gradient: LinearGradient(
              colors: [
                appTheme.blueGray90001,
                appTheme.blueGray90001.withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(
              color: primary.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgStarCircleSvgrepoCom,
                height: 46.adaptSize,
                width: 46.adaptSize,
              ),
              SizedBox(width: 14.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "lbl_premium_plan".tr,
                            style: CustomTextStyles.titleSmallVisbyRoundCF
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.h,
                            vertical: 5.v,
                          ),
                          decoration: BoxDecoration(
                            color: isPro
                                ? primary
                                : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.adaptSize),
                          ),
                          child: Text(
                            isPro ? 'lbl_pro'.tr : 'lbl_free'.tr,
                            style: CustomTextStyles.bodySmallInter.copyWith(
                              color: isPro ? onPrimary : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.fSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.v),
                    Text(
                      "msg_upgrade_to_access".tr,
                      style: CustomTextStyles.bodySmallInter.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.h),
              Icon(
                Icons.chevron_right_rounded,
                color: primary,
                size: 28.adaptSize,
              ),
            ],
          ),
        ),
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
        SizedBox(width: 12.h),
        Expanded(
          child: _HomeFooterActionCard(
            icon: Icons.help_outline_rounded,
            title: 'lbl_help'.tr,
            subtitle: 'msg_home_help_subtitle'.tr,
            onTap: () =>
                NavigatorService.pushNamed(AppRoutes.aboutUsScreen),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnEyeOne(
    BuildContext context, {
    required String eyeImage,
    required String removeText,
    Function? onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap?.call();
      },
      child: Column(
        children: [
          CustomImageView(
            imagePath: eyeImage,
            height: 34.adaptSize,
            width: 34.adaptSize,
          ),
          SizedBox(height: 11.v),
          GestureDetector(
            child: SizedBox(
              width: 75.h,
              child: Text(
                removeText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CustomTextStyles.bodySmallInter.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(1),
                ),
              ),
            ),
          ),
        ],
      ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.adaptSize),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 14.v),
          decoration: BoxDecoration(
            color: appTheme.blueGray90001,
            borderRadius: BorderRadius.circular(12.adaptSize),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.adaptSize),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.adaptSize),
                ),
                child: Icon(icon, color: primary, size: 22.adaptSize),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CustomTextStyles.titleSmallVisbyRoundCF.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      subtitle,
                      style: CustomTextStyles.bodySmallInter.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.75),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto-advancing promo strip for the home header (text slides; swap copy or load from API later).
class _HomeAdvertisingSlider extends StatefulWidget {
  const _HomeAdvertisingSlider();

  @override
  State<_HomeAdvertisingSlider> createState() => _HomeAdvertisingSliderState();
}

class _HomeAdvertisingSliderState extends State<_HomeAdvertisingSlider> {
  static const List<String> _slideMessages = [
    'Advertise your ad here',
    'Promote your business to our community',
    'Show your offer — this space is yours',
    'Partner with us — get in touch today',
  ];

  late final PageController _pageController;
  Timer? _autoAdvance;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoAdvance = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_index + 1) % _slideMessages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.adaptSize),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slideMessages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.h,
                      vertical: 12.v,
                    ),
                    child: Center(
                      child: Text(
                        _slideMessages[i],
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              height: 1.25,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 8.v),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slideMessages.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.symmetric(horizontal: 3.h),
              width: active ? 18.h : 6.h,
              height: 6.v,
              decoration: BoxDecoration(
                color: active
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}
