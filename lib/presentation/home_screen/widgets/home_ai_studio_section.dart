import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/wallet_cost_guard.dart';

/// Home “AI Studio” grid — ChatGPT-powered tools via Musamimuk backend.
class HomeAiStudioSection extends StatelessWidget {
  const HomeAiStudioSection({
    super.key,
    required this.isPro,
    this.creditsLabel,
  });

  final bool isPro;

  /// Optional credits / plan chip text (falls back to Free / Pro).
  final String? creditsLabel;

  Future<void> _openAiTool(String route) async {
    if (!SessionManager.instance.requireAuthenticated(routeName: route)) {
      return;
    }
    NavigatorService.pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final isGuest = PrefUtils().isGuestAccount();

    final actions = <_AiStudioAction>[
      _AiStudioAction(
        label: 'lbl_ai_generate_images'.tr,
        icon: Icons.auto_awesome_outlined,
        colors: const [Color(0xFF1FA97A), Color(0xFF12805C)],
        onTap: () => _openAiTool(AppRoutes.aiStudioImageScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_generate_designs'.tr,
        icon: Icons.brush_outlined,
        colors: const [Color(0xFF7B5CFF), Color(0xFF5A3FD6)],
        onTap: () => _openAiTool(AppRoutes.aiStudioDesignScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_generate_videos'.tr,
        icon: Icons.play_circle_outline_rounded,
        colors: const [Color(0xFFFF7A45), Color(0xFFE24B2D)],
        onTap: () => _comingSoonVideo(context),
      ),
      _AiStudioAction(
        label: 'lbl_ai_chat'.tr,
        icon: Icons.chat_bubble_outline_rounded,
        colors: const [Color(0xFF3B5BDB), Color(0xFF2641A8)],
        onTap: () => _openAiTool(AppRoutes.aiStudioChatScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_vision'.tr,
        icon: Icons.camera_alt_outlined,
        colors: const [Color(0xFF4DABF7), Color(0xFF1C7ED6)],
        onTap: () => _openAiTool(AppRoutes.aiStudioVisionScreen),
      ),
      _AiStudioAction(
        label: 'lbl_ai_gallery'.tr,
        icon: Icons.photo_library_outlined,
        colors: const [Color(0xFF9775FA), Color(0xFF7048E8)],
        onTap: () =>
            NavigatorService.pushNamed(AppRoutes.screen18MyDesignsScreen),
      ),
      _AiStudioAction(
        label: 'lbl_remove_bg'.tr,
        icon: Icons.layers_clear_outlined,
        colors: const [Color(0xFFFF6B9D), Color(0xFFE64980)],
        onTap: () => NavigatorService.pushNamed(
          AppRoutes.screen19RemoveBackgroundScreen,
        ),
      ),
      _AiStudioAction(
        label: 'lbl_ai_get_inspired'.tr,
        icon: Icons.lightbulb_outline_rounded,
        colors: const [Color(0xFF845EF7), Color(0xFF5F3DC4)],
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
              Icon(
                Icons.auto_awesome,
                color: primary,
                size: 20.adaptSize,
              ),
              SizedBox(width: AppDs.space2.h),
              Expanded(
                child: AppText(
                  'lbl_ai_studio'.tr,
                  variant: AppTextVariant.title,
                  color: primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: AppDs.space2.h),
                padding: EdgeInsets.symmetric(
                  horizontal: AppDs.space2.h,
                  vertical: 4.v,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withValues(alpha: 0.18),
                  borderRadius:
                      BorderRadius.circular(AppDs.radiusFull.adaptSize),
                ),
                child: AppText(
                  'lbl_chatgpt'.tr,
                  variant: AppTextVariant.caption,
                  color: const Color(0xFF10A37F),
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
                    color: primary,
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
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
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
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: action.colors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: action.colors.last.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
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
