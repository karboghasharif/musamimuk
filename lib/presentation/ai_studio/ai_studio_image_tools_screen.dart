import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/config/editor_ai_config.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/editor_ai_api_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/editor_ai/editor_ai_api_service.dart';
import '../add_new_screen/widgets/musami_ai_inpaint_sheet.dart';
import '../wallet/wallet_cost_guard.dart';
import 'ai_studio_image_screen.dart';
import 'ai_studio_shared.dart';

enum AiStudioImageToolMode { upscale, inpaint }

/// Gallery → Upscale or Inpaint → preview → open in editor.
class AiStudioImageToolsScreen extends StatefulWidget {
  const AiStudioImageToolsScreen({super.key, required this.mode});

  final AiStudioImageToolMode mode;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final mode = args is AiStudioImageToolMode
        ? args
        : AiStudioImageToolMode.upscale;
    return AiStudioImageToolsScreen(mode: mode);
  }

  @override
  State<AiStudioImageToolsScreen> createState() =>
      _AiStudioImageToolsScreenState();
}

class _AiStudioImageToolsScreenState extends State<AiStudioImageToolsScreen> {
  final _api = EditorAiApiService();
  final _picker = ImagePicker();
  bool _busy = false;
  Uint8List? _source;
  Uint8List? _result;
  int _resultW = 1024;
  int _resultH = 1024;
  int _scale = 2;

  bool get _isUpscale => widget.mode == AiStudioImageToolMode.upscale;

  Future<void> _pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _source = bytes;
      _result = null;
    });
  }

  Future<void> _run() async {
    final source = _source;
    if (source == null || source.isEmpty) {
      showAppToast(
        'msg_ai_pick_image_first'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    final feature = _isUpscale
        ? WalletFeatureCost.aiOpenaiUpscale
        : WalletFeatureCost.aiOpenaiInpaint;
    if (!await ensureCanSpendCoins(context: context, feature: feature)) {
      return;
    }
    if (!mounted) return;

    String? prompt;
    Uint8List? mask;
    if (!_isUpscale) {
      final painted = await showMusamiAiInpaintSheet(
        context: context,
        imageBytes: source,
      );
      if (painted == null || !mounted) return;
      prompt = painted.prompt;
      mask = painted.maskPng;
    }

    setState(() => _busy = true);
    try {
      final EditorAiImageToolResponse response;
      if (_isUpscale) {
        response = await _api.upscaleImage(
          EditorAiUpscaleRequest(
            imageBase64: base64Encode(source),
            scale: _scale,
          ),
        );
      } else {
        response = await _api.inpaintImage(
          EditorAiInpaintRequest(
            imageBase64: base64Encode(source),
            maskBase64: base64Encode(mask!),
            prompt: prompt!,
          ),
        );
      }
      if (!mounted) return;
      AiStudioChrome.applyWallet(context, _api);
      final out = response.decodeBytes();
      if (out == null || out.isEmpty) {
        throw const EditorAiApiException(
          message: 'Empty AI image response',
          retryable: true,
        );
      }
      setState(() {
        _result = out;
        _resultW = response.width;
        _resultH = response.height;
      });
      showAppToast(
        _isUpscale ? 'msg_ai_upscale_done'.tr : 'msg_ai_inpaint_done'.tr,
        type: ToastificationType.success,
      );
    } catch (error) {
      if (mounted) AiStudioChrome.toastAiError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openInEditor() {
    final bytes = _result;
    if (bytes == null) return;
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
      arguments: {
        'width': _resultW.toDouble(),
        'height': _resultH.toDouble(),
        'unit': 'px',
        'presetName': _isUpscale ? 'AI Upscale' : 'AI Inpaint',
        'backgroundImageBytes': bytes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isUpscale ? 'lbl_ai_upscale'.tr : 'lbl_ai_inpaint'.tr;
    final feature = _isUpscale
        ? WalletFeatureCost.aiOpenaiUpscale
        : WalletFeatureCost.aiOpenaiInpaint;

    return Scaffold(
      backgroundColor: AppDs.surfaceBase,
      appBar: AiStudioChrome.appBar(context, title),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space3.v,
                AppDs.space4.h,
                AppDs.space4.v,
              ),
              children: [
                AiStudioChrome.toolbar(
                  kind: EditorAiProviderKind.openAi,
                  coinHint: BlocBuilderCoinHint(feature: feature),
                ),
                SizedBox(height: AppDs.space3.v),
                Text(
                  _isUpscale
                      ? 'msg_ai_upscale_studio_hint'.tr
                      : 'msg_ai_inpaint_studio_hint'.tr,
                  style: TextStyle(
                    color: AppDs.textOnDarkSecondary,
                    fontSize: 13.fSize,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: AppDs.space4.v),
                AiStudioChrome.previewStage(
                  height: 240,
                  onTap: _busy ? null : _pick,
                  child: _source == null
                      ? AiStudioChrome.emptyPreviewHint(
                          icon: Icons.add_photo_alternate_outlined,
                          message: 'msg_ai_tap_to_pick_image'.tr,
                        )
                      : Image.memory(_source!, fit: BoxFit.contain),
                ),
                SizedBox(height: AppDs.space3.v),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _pick,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _source == null
                              ? 'lbl_ai_pick_image'.tr
                              : 'msg_bg_removal_change_photo'.tr,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppDs.textOnDarkPrimary,
                          side: const BorderSide(color: AiStudioChrome.hairline),
                          minimumSize: Size(0, 48.v),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDs.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isUpscale) ...[
                  SizedBox(height: AppDs.space4.v),
                  AiStudioChrome.sectionLabel('lbl_ai_upscale_factor'.tr),
                  SizedBox(height: AppDs.space2.v),
                  AiStudioChrome.segmentChoice<int>(
                    value: _scale,
                    enabled: !_busy,
                    options: [
                      (2, 'lbl_ai_upscale_2x'.tr),
                      (4, 'lbl_ai_upscale_4x'.tr),
                    ],
                    onChanged: (v) => setState(() => _scale = v),
                  ),
                ],
                if (_result != null) ...[
                  SizedBox(height: AppDs.space5.v),
                  AiStudioChrome.sectionLabel('lbl_results'.tr),
                  SizedBox(height: AppDs.space2.v),
                  AiStudioChrome.previewStage(
                    height: 220,
                    child: Image.memory(_result!, fit: BoxFit.contain),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space2.v,
                AppDs.space4.h,
                AppDs.space3.v,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppPrimaryButton(
                    label: _busy
                        ? (_isUpscale
                            ? 'msg_ai_upscaling'.tr
                            : 'msg_ai_inpainting'.tr)
                        : (_isUpscale
                            ? 'lbl_ai_upscale'.tr
                            : 'lbl_ai_inpaint'.tr),
                    onPressed: _busy ? null : _run,
                    isLoading: _busy,
                  ),
                  if (_result != null) ...[
                    SizedBox(height: AppDs.space2.v),
                    SizedBox(
                      width: double.infinity,
                      height: AppDs.buttonHeight,
                      child: OutlinedButton.icon(
                        onPressed: _openInEditor,
                        icon: const Icon(Icons.design_services_outlined),
                        label: Text('lbl_ai_use_in_design'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AiStudioChrome.accent,
                          side: BorderSide(
                            color: AiStudioChrome.accent.withValues(alpha: 0.55),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDs.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
