import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/editor_ai_api_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/editor_ai/editor_ai_api_service.dart';
import 'ai_studio_image_screen.dart';
import 'ai_studio_shared.dart';

/// ChatGPT vision — pick a photo and ask what to improve / extract.
class AiStudioVisionScreen extends StatefulWidget {
  const AiStudioVisionScreen({super.key});

  static Widget builder(BuildContext context) => const AiStudioVisionScreen();

  @override
  State<AiStudioVisionScreen> createState() => _AiStudioVisionScreenState();
}

class _AiStudioVisionScreenState extends State<AiStudioVisionScreen> {
  final _promptCtrl = TextEditingController(
    text: 'Describe this image and suggest design improvements.',
  );
  final _api = EditorAiApiService();
  final _picker = ImagePicker();
  Uint8List? _previewBytes;
  String? _dataUrl;
  String? _answer;
  bool _busy = false;

  static const _suggestions = <String>[
    'What text should go on this poster?',
    'Suggest a color palette from this photo',
    'Is this good for Instagram story?',
    'Describe objects and layout for redesign',
  ];

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final dataUrl = await aiStudioImageToDataUrl(file);
      if (dataUrl == null) {
        showAppToast(
          'msg_ai_vision_image_failed'.tr,
          type: ToastificationType.error,
        );
        return;
      }
      setState(() {
        _previewBytes = bytes;
        _dataUrl = dataUrl;
        _answer = null;
      });
    } catch (_) {
      showAppToast(
        'msg_ai_vision_image_failed'.tr,
        type: ToastificationType.error,
      );
    }
  }

  Future<void> _analyze() async {
    final dataUrl = _dataUrl;
    final prompt = _promptCtrl.text.trim();
    if (dataUrl == null) {
      showAppToast('msg_ai_vision_pick_first'.tr, type: ToastificationType.info);
      return;
    }
    if (prompt.isEmpty) {
      showAppToast('msg_ai_prompt_required'.tr, type: ToastificationType.warning);
      return;
    }
    if (!await AiStudioChrome.guardOpenAiEditor(context)) return;

    setState(() {
      _busy = true;
      _answer = null;
    });
    try {
      final response = await _api.sendOpenAiEditor(
        OpenAiEditorRequest(
          messages: [
            AiMessage.system(
              'You are Musamimuk AI Vision powered by ChatGPT. Analyze the '
              'attached image for design feedback. Be concrete and friendly. '
              'Reply in the same language as the user question when possible.',
            ),
            AiMessage.userWithImage(text: prompt, imageDataUrl: dataUrl),
          ],
        ),
      );
      if (!mounted) return;
      AiStudioChrome.applyWallet(context, _api);
      setState(() => _answer = response.content.trim());
    } catch (error) {
      if (mounted) AiStudioChrome.toastAiError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: AiStudioChrome.appBar(context, 'lbl_ai_vision'.tr),
        body: ListView(
          padding: EdgeInsets.all(AppDs.space4.h),
          children: [
            Row(
              children: [
                AiStudioChrome.poweredByChatGpt(context),
                const Spacer(),
                BlocBuilderCoinHint(feature: WalletFeatureCost.aiOpenaiEditor),
              ],
            ),
            SizedBox(height: AppDs.space3.v),
            AppText(
              'msg_ai_vision_subtitle'.tr,
              variant: AppTextVariant.secondary,
            ),
            SizedBox(height: AppDs.space4.v),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Material(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
                clipBehavior: Clip.antiAlias,
                child: _previewBytes == null
                    ? Center(
                        child: AppText(
                          'msg_ai_vision_empty'.tr,
                          variant: AppTextVariant.secondary,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Image.memory(_previewBytes!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: AppDs.space3.v),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text('lbl_photo_gallery'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      minimumSize: Size(0, 48.v),
                    ),
                  ),
                ),
                SizedBox(width: AppDs.space2.h),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text('lbl_camera'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      minimumSize: Size(0, 48.v),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDs.space4.v),
            AiStudioPromptField(
              controller: _promptCtrl,
              hint: 'msg_ai_vision_prompt_hint'.tr,
              onSubmitted: _busy ? null : _analyze,
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
            AppPrimaryButton(
              label: _busy ? 'msg_ai_analyzing'.tr : 'lbl_ai_analyze'.tr,
              onPressed: _busy ? null : _analyze,
              isLoading: _busy,
            ),
            if (_answer != null) ...[
              SizedBox(height: AppDs.space4.v),
              AppCard(
                elevated: true,
                padding: EdgeInsets.all(AppDs.space4.h),
                child: SelectableText(
                  _answer!,
                  style: TextStyle(
                    color: AppDs.textOnDarkPrimary,
                    fontSize: 14.fSize,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
