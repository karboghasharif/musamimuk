import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/editor_ai_api_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/editor_ai/editor_ai_api_service.dart';
import '../wallet/bloc/wallet_bloc.dart';
import 'ai_studio_shared.dart';

/// ChatGPT image generation — prompt in, preview out, open in editor.
class AiStudioImageScreen extends StatefulWidget {
  const AiStudioImageScreen({super.key});

  static Widget builder(BuildContext context) => const AiStudioImageScreen();

  @override
  State<AiStudioImageScreen> createState() => _AiStudioImageScreenState();
}

class _AiStudioImageScreenState extends State<AiStudioImageScreen> {
  final _promptCtrl = TextEditingController();
  final _api = EditorAiApiService();
  bool _busy = false;
  String _size = '1024x1024';
  Uint8List? _imageBytes;
  String? _assetId;

  static const _suggestions = <String>[
    'Minimal Arabic calligraphy poster, soft sand tones',
    'Product photo of a ceramic mug on marble, studio light',
    'Flat illustration of a Saudi coffee shop logo',
    'Elegant wedding invite background with gold foil',
  ];

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      showAppToast('msg_ai_prompt_required'.tr, type: ToastificationType.warning);
      return;
    }
    if (!await AiStudioChrome.guardOpenAiImages(context)) return;

    setState(() {
      _busy = true;
      _imageBytes = null;
      _assetId = null;
    });
    try {
      final response = await _api.generateOpenAiImage(
        OpenAiImageRequest(prompt: prompt, size: _size, quality: 'medium'),
      );
      if (!mounted) return;
      AiStudioChrome.applyWallet(context, _api);
      final asset = response.assets.first;
      final bytes = asset.decodeBytes();
      if (bytes == null || bytes.isEmpty) {
        throw const EditorAiApiException(
          message: 'Empty image response',
          retryable: true,
        );
      }
      setState(() {
        _imageBytes = bytes;
        _assetId = asset.id;
      });
      showAppToast('msg_ai_image_ready'.tr, type: ToastificationType.success);
    } catch (error) {
      if (mounted) AiStudioChrome.toastAiError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openInEditor() {
    final bytes = _imageBytes;
    if (bytes == null) return;
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
      arguments: {
        'width': _size == '1536x1024' ? 1536.0 : 1024.0,
        'height': _size == '1536x1024' ? 1024.0 : 1024.0,
        'unit': 'px',
        'presetName': 'AI Image',
        'backgroundImageBytes': bytes,
        if (_assetId != null) 'generatedAssetIds': <String>[_assetId!],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: AiStudioChrome.appBar(context, 'lbl_ai_generate_images'.tr),
        body: ListView(
          padding: EdgeInsets.all(AppDs.space4.h),
          children: [
            Row(
              children: [
                AiStudioChrome.poweredByChatGpt(context),
                const Spacer(),
                BlocBuilderCoinHint(feature: WalletFeatureCost.aiOpenaiImages),
              ],
            ),
            SizedBox(height: AppDs.space4.v),
            AppText(
              'msg_ai_image_subtitle'.tr,
              variant: AppTextVariant.secondary,
            ),
            SizedBox(height: AppDs.space3.v),
            AiStudioPromptField(
              controller: _promptCtrl,
              hint: 'msg_ai_image_prompt_hint'.tr,
              onSubmitted: _busy ? null : _generate,
            ),
            SizedBox(height: AppDs.space3.v),
            AiStudioChrome.suggestionChips(
              suggestions: _suggestions,
              onTap: (tip) {
                _promptCtrl.text = tip;
                setState(() {});
              },
            ),
            SizedBox(height: AppDs.space4.v),
            AppText('lbl_ai_image_size'.tr, variant: AppTextVariant.caption),
            SizedBox(height: AppDs.space2.v),
            Wrap(
              spacing: AppDs.space2.h,
              children: [
                for (final size in OpenAiImageRequest.allowedSizes)
                  ChoiceChip(
                    label: Text(size),
                    selected: _size == size,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _size = size),
                    selectedColor: AiStudioChrome.accent.withValues(alpha: 0.35),
                    labelStyle: TextStyle(
                      color: AppDs.textOnDarkPrimary,
                      fontSize: 12.fSize,
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppDs.space4.v),
            AppPrimaryButton(
              label: _busy ? 'msg_ai_generating'.tr : 'lbl_ai_generate'.tr,
              onPressed: _busy ? null : _generate,
              isLoading: _busy,
            ),
            SizedBox(height: AppDs.space5.v),
            if (_busy)
              const AppLoadingBlock(message: null)
            else if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
                child: AspectRatio(
                  aspectRatio: _size == '1536x1024' ? 1536 / 1024 : 1,
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: AppDs.space3.v),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.refresh),
                      label: Text('lbl_ai_regenerate'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.5)),
                        minimumSize: Size(0, 48.v),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDs.space2.h),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openInEditor,
                      icon: const Icon(Icons.brush_outlined),
                      label: Text('lbl_ai_use_in_design'.tr),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: AppDs.onAccent,
                        minimumSize: Size(0, 48.v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small coin-cost hint for AI Studio headers.
class BlocBuilderCoinHint extends StatelessWidget {
  const BlocBuilderCoinHint({super.key, required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (p, n) => p.costs != n.costs,
      builder: (context, state) {
        final cost = context.read<WalletBloc>().costFor(feature);
        if (cost == null) return const SizedBox.shrink();
        return AppText(
          '$cost ${'lbl_coins'.tr}',
          variant: AppTextVariant.caption,
          color: AppDs.accentYellow,
        );
      },
    );
  }
}
