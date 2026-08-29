import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/editor_ai/editor_ai_api_service.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../wallet/bloc/wallet_bloc.dart';
import '../wallet/wallet_cost_guard.dart';

/// Shared chrome for ChatGPT-powered AI Studio tools.
class AiStudioChrome {
  AiStudioChrome._();

  static const Color accent = Color(0xFF10A37F);

  static PreferredSizeWidget appBar(BuildContext context, String title) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        onTap: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: AppbarTitle(text: title),
    );
  }

  static Widget poweredByChatGpt(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space3.h,
        vertical: AppDs.space1.v + 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 14.adaptSize, color: accent),
          SizedBox(width: 6.h),
          AppText(
            'lbl_powered_by_chatgpt'.tr,
            variant: AppTextVariant.caption,
            color: accent,
          ),
        ],
      ),
    );
  }

  static Widget suggestionChips({
    required List<String> suggestions,
    required ValueChanged<String> onTap,
  }) {
    return Wrap(
      spacing: AppDs.space2.h,
      runSpacing: AppDs.space2.v,
      children: [
        for (final tip in suggestions)
          ActionChip(
            label: Text(tip, maxLines: 1, overflow: TextOverflow.ellipsis),
            onPressed: () => onTap(tip),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            labelStyle: TextStyle(
              color: AppDs.textOnDarkPrimary,
              fontSize: 12.fSize,
            ),
          ),
      ],
    );
  }

  static Future<bool> guardOpenAiEditor(BuildContext context) {
    return ensureCanSpendCoins(
      context: context,
      feature: WalletFeatureCost.aiOpenaiEditor,
    );
  }

  static Future<bool> guardOpenAiImages(BuildContext context) {
    return ensureCanSpendCoins(
      context: context,
      feature: WalletFeatureCost.aiOpenaiImages,
    );
  }

  static void applyWallet(BuildContext context, EditorAiApiService api) {
    final wallet = api.lastWalletFromResponse;
    if (wallet == null || !context.mounted) return;
    context.read<WalletBloc>().add(WalletApplyServerBalanceEvent(wallet));
  }

  static String friendlyAiError(Object error) {
    if (error is EditorAiApiException) {
      if (error.insufficientCoins) {
        return 'msg_insufficient_coins'.tr;
      }
      if (error.requiresSignIn) {
        return 'msg_sign_in_required'.tr;
      }
      return error.message;
    }
    return 'msg_ai_request_failed'.tr;
  }

  static void toastAiError(Object error) {
    showAppToast(friendlyAiError(error), type: ToastificationType.error);
  }
}

/// Compresses a picked image into a ChatGPT vision data URL.
Future<String?> aiStudioImageToDataUrl(XFile file) async {
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;

  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 768,
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) return null;

  final encoded = base64Encode(Uint8List.view(byteData.buffer));
  return 'data:image/png;base64,$encoded';
}

class AiStudioPromptField extends StatelessWidget {
  const AiStudioPromptField({
    super.key,
    required this.controller,
    required this.hint,
    this.minLines = 3,
    this.maxLines = 6,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(color: AppDs.textOnDarkPrimary, fontSize: 15.fSize),
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppDs.textOnDarkSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
          borderSide: const BorderSide(color: AiStudioChrome.accent, width: 1.4),
        ),
        contentPadding: EdgeInsets.all(AppDs.space4.h),
      ),
    );
  }
}
