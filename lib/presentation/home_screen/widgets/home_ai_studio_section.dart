import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../../ai_studio/ai_studio_image_tools_screen.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/wallet_cost_guard.dart';

/// Home “AI Studio” grid — brand-aligned dark + yellow tool entry points.
class HomeAiStudioSection extends StatelessWidget {
  const HomeAiStudioSection({
    super.key,
    required this.isPro,
    this.creditsLabel,
  });

  final bool isPro;

  /// Optional credits / plan chip text (falls back to Free / Pro).
  final String? creditsLabel;

  Future<void> _openAiTool(String route, {dynamic arguments}) async {
    if (!SessionManager.instance.requireAuthenticated(
      routeName: route,
      arguments: arguments,
    )) {
      return;
    }
    NavigatorService.pushNamed(route, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = PrefUtils().isGuestAccount();

    final actions = <_AiStudioAction>[
      _AiStudioAction(
        label: 'lbl_ai_generate_images'.tr,
        icon: Icons.auto_awesome_outlined,
        onTap: () => _openAiTool(AppRoutes.aiStudioImageScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_generate_designs'.tr,
        icon: Icons.brush_outlined,
        onTap: () => _openAiTool(AppRoutes.aiStudioDesignScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_generate_videos'.tr,
        icon: Icons.play_circle_outline_rounded,
        onTap: () => _comingSoonVideo(context),
      ),
      _AiStudioAction(
        label: 'lbl_ai_upscale'.tr,
        icon: Icons.high_quality_outlined,
        onTap: () => _openAiTool(
          AppRoutes.aiStudioImageToolsScreen,
          arguments: AiStudioImageToolMode.upscale,
        ),
      ),
      _AiStudioAction(
        label: 'lbl_ai_inpaint'.tr,
        icon: Icons.format_paint_outlined,
        onTap: () => _openAiTool(
          AppRoutes.aiStudioImageToolsScreen,
          arguments: AiStudioImageToolMode.inpaint,
        ),
      ),
      _AiStudioAction(
        label: 'lbl_ai_chat'.tr,
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () => _openAiTool(AppRoutes.aiStudioChatScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_vision'.tr,
        icon: Icons.camera_alt_outlined,
        onTap: () => _openAiTool(AppRoutes.aiStudioVisionScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_gallery'.tr,
        icon: Icons.photo_library_outlined,
        onTap: () =>
            NavigatorService.pushNamed(AppRoutes.screen18MyDesignsScreen),
      ),
      _AiStudioAction(
        label: 'lbl_remove_bg'.tr,
        icon: Icons.layers_clear_outlined,
        onTap: () => NavigatorService.pushNamed(
          AppRoutes.screen19RemoveBackgroundScreen,
        ),
      ),
      _AiStudioAction(
        label: 'lbl_ai_get_inspired'.tr,
        icon: Icons.lightbulb_outline_rounded,
        onTap: () =>
            NavigatorService.pushNamed(AppRoutes.screen16OnlineDesignsScreen),
      ),
    ];

    return AppCard(
      elevated: true,
      padding: EdgeInsets.fromLTRB(
        AppDs.space4.h,
        AppDs.space4.v,
        AppDs.space4.h,
        AppDs.space3.v,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32.adaptSize,
                height: 32.adaptSize,
                decoration: BoxDecoration(
                  color: AppDs.accentYellow.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppDs.radiusSm),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppDs.accentYellow,
                  size: 18.adaptSize,
                ),
              ),
              SizedBox(width: AppDs.space2.h),
              Expanded(
                child: AppText(
                  'lbl_ai_studio'.tr,
                  variant: AppTextVariant.title,
                  color: AppDs.textOnDarkPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              BlocBuilder<WalletBloc, WalletState>(
                buildWhen: (p, n) => p.balance != n.balance,
                builder: (context, walletState) {
                  final chipText = creditsLabel?.trim().isNotEmpty == true
                      ? creditsLabel!.trim()
                      : (isGuest
                          ? (isPro ? 'lbl_pro'.tr : 'lbl_free'.tr)
                          : '${walletState.coinBalance} ${'lbl_coins'.tr}');
                  return Material(
                    color: AppDs.accentYellow,
                    borderRadius:
                        BorderRadius.circular(AppDs.radiusFull.adaptSize),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => openCoinStore(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDs.space3.h,
                          vertical: AppDs.space1.v + 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              size: 16.adaptSize,
                              color: AppDs.onAccent,
                            ),
                            SizedBox(width: 4.h),
                            AppText(
                              chipText,
                              variant: AppTextVariant.caption,
                              color: AppDs.onAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: AppDs.space2.v),
          AppText(
            'msg_ai_studio_subtitle'.tr,
            variant: AppTextVariant.secondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppDs.space4.v),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppDs.space3.v,
              crossAxisSpacing: AppDs.space2.h,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _AiStudioTile(action: action);
            },
          ),
        ],
      ),
    );
  }

  void _comingSoonVideo(BuildContext context) {
    showAppToast(
      'msg_ai_video_coming_soon'.tr,
      type: ToastificationType.info,
    );
  }
}

class _AiStudioAction {
  const _AiStudioAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _AiStudioTile extends StatelessWidget {
  const _AiStudioTile({required this.action});

  final _AiStudioAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppDs.space1.v),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48.adaptSize,
                height: 48.adaptSize,
                decoration: BoxDecoration(
                  color: AppDs.atelierInk,
                  borderRadius: BorderRadius.circular(AppDs.radiusMd),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  action.icon,
                  color: AppDs.accentYellow,
                  size: 22.adaptSize,
                ),
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                action.label,
                variant: AppTextVariant.caption,
                color: AppDs.textOnDarkPrimary,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
