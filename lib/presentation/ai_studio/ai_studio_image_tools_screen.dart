import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/editor_ai_api_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/editor_ai/editor_ai_api_service.dart';
import '../add_new_screen/widgets/musami_ai_inpaint_sheet.dart';
import '../add_new_screen/widgets/musami_ai_upscale_sheet.dart';
import '../wallet/wallet_cost_guard.dart';
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

    int scale = 2;
    String? prompt;
    Uint8List? mask;
    if (_isUpscale) {
      final picked = await showMusamiAiUpscaleSheet(context);
      if (picked == null || !mounted) return;
      scale = picked;
    } else {
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
            scale: scale,
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
    final title =
        _isUpscale ? 'lbl_ai_upscale'.tr : 'lbl_ai_inpaint'.tr;
    return Scaffold(
      backgroundColor: AppDs.surfaceBase,
      appBar: AiStudioChrome.appBar(context, title),
      body: ListView(
        padding: EdgeInsets.all(AppDs.space4.h),
        children: [
          AiStudioChrome.poweredByChatGpt(context),
          SizedBox(height: AppDs.space3.v),
          Text(
            _isUpscale
                ? 'msg_ai_upscale_studio_hint'.tr
                : 'msg_ai_inpaint_studio_hint'.tr,
            style: TextStyle(
              color: AppDs.textOnDarkSecondary,
              fontSize: 13.fSize,
            ),
          ),
          SizedBox(height: AppDs.space4.v),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text('lbl_ai_pick_image'.tr),
          ),
          if (_source != null) ...[
            SizedBox(height: AppDs.space3.v),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDs.radiusMd),
              child: Image.memory(_source!, height: 180, fit: BoxFit.contain),
            ),
          ],
          SizedBox(height: AppDs.space3.v),
          FilledButton(
            onPressed: _busy ? null : _run,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isUpscale ? 'lbl_ai_upscale'.tr : 'lbl_ai_inpaint'.tr),
          ),
          if (_result != null) ...[
            SizedBox(height: AppDs.space4.v),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDs.radiusMd),
              child: Image.memory(_result!, height: 220, fit: BoxFit.contain),
            ),
            SizedBox(height: AppDs.space3.v),
            FilledButton.tonal(
              onPressed: _openInEditor,
              child: Text('lbl_ai_use_in_design'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
