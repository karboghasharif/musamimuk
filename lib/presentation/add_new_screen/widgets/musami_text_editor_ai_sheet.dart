import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/config/editor_ai_config.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/services/editor_ai/editor_ai_api_service.dart';
import '../../../data/services/editor_ai/editor_ai_provider_factory.dart';
import '../../../data/services/editor_ai/editor_ai_text_writing.dart';
import '../../../data/services/editor_ai/editor_ai_text_writing_service.dart';
import '../../ai_studio/ai_studio_shared.dart';
import '../../wallet/wallet_cost_guard.dart';
import 'musami_ai_chrome.dart';
import 'musami_text_editor_script.dart';

/// Opens the AI writing-assistance sheet for the inline text editor.
Future<void> musamiShowTextEditorAiSheet(
  BuildContext context,
  TextEditorState editor,
) async {
  if (!SessionManager.instance.requireAuthenticated()) return;

  await showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return AppDarkSheetTheme(child: _MusamiTextEditorAiSheet(editor: editor));
    },
  );

  if (editor.focusNode.canRequestFocus) {
    editor.focusNode.requestFocus();
  }
}

class _MusamiTextEditorAiSheet extends StatefulWidget {
  const _MusamiTextEditorAiSheet({required this.editor});

  final TextEditorState editor;

  @override
  State<_MusamiTextEditorAiSheet> createState() =>
      _MusamiTextEditorAiSheetState();
}

class _MusamiTextEditorAiSheetState extends State<_MusamiTextEditorAiSheet> {
  bool _isProcessing = false;
  final _promptCtrl = TextEditingController();
  EditorAiTextWritingAction? _promptAction;
  EditorAiProviderKind _providerKind = EditorAiProviderKind.openAi;

  late EditorAiTextWritingService _service;

  static const _actions = <({EditorAiTextWritingAction action, IconData icon})>[
    (action: EditorAiTextWritingAction.generate, icon: Icons.auto_awesome),
    (action: EditorAiTextWritingAction.rewrite, icon: Icons.refresh_rounded),
    (
      action: EditorAiTextWritingAction.fixSpelling,
      icon: Icons.spellcheck_rounded,
    ),
    (action: EditorAiTextWritingAction.shorten, icon: Icons.compress_rounded),
    (
      action: EditorAiTextWritingAction.expand,
      icon: Icons.open_in_full_rounded,
    ),
    (
      action: EditorAiTextWritingAction.translateArabic,
      icon: Icons.translate_rounded,
    ),
    (
      action: EditorAiTextWritingAction.translateEnglish,
      icon: Icons.g_translate_rounded,
    ),
    (
      action: EditorAiTextWritingAction.professionalTone,
      icon: Icons.business_center_outlined,
    ),
    (
      action: EditorAiTextWritingAction.friendlyTone,
      icon: Icons.emoji_emotions_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _service = EditorAiTextWritingService(
      provider: EditorAiProviderFactory.defaultProvider(),
    );
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  String _labelFor(EditorAiTextWritingAction action) {
    return switch (action) {
      EditorAiTextWritingAction.generate => 'lbl_ai_write_generate'.tr,
      EditorAiTextWritingAction.rewrite => 'lbl_ai_write_rewrite'.tr,
      EditorAiTextWritingAction.fixSpelling => 'lbl_ai_write_fix_spelling'.tr,
      EditorAiTextWritingAction.shorten => 'lbl_ai_write_shorten'.tr,
      EditorAiTextWritingAction.expand => 'lbl_ai_write_expand'.tr,
      EditorAiTextWritingAction.translateArabic =>
        'lbl_ai_write_translate_ar'.tr,
      EditorAiTextWritingAction.translateEnglish =>
        'lbl_ai_write_translate_en'.tr,
      EditorAiTextWritingAction.professionalTone =>
        'lbl_ai_write_tone_professional'.tr,
      EditorAiTextWritingAction.friendlyTone => 'lbl_ai_write_tone_friendly'.tr,
    };
  }

  String _mapError(Object error) {
    if (error is EditorAiApiException) {
      switch (error.message) {
        case 'empty_prompt':
          return 'msg_ai_write_empty_prompt'.tr;
        case 'empty_text':
          return 'msg_ai_write_empty_text'.tr;
        case 'empty_response':
          return 'msg_ai_write_empty_response'.tr;
      }
      switch (error.statusCode) {
        case 401:
          return 'msg_ai_write_sign_in'.tr;
        case 429:
          return 'msg_ai_write_rate_limit'.tr;
        case 502:
        case 503:
        case 504:
          return 'msg_ai_write_unavailable'.tr;
      }
      if (error.retryable) return 'msg_ai_write_network'.tr;
      final lower = error.message.toLowerCase();
      if (lower.contains('api key') || lower.contains('invalid key')) {
        return 'msg_ai_write_invalid_key'.tr;
      }
      return error.message.isNotEmpty
          ? error.message
          : 'msg_ai_write_failed'.tr;
    }
    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection')) {
      return 'msg_ai_write_network'.tr;
    }
    return 'msg_ai_write_failed'.tr;
  }

  Future<void> _onAction(EditorAiTextWritingAction action) async {
    if (_isProcessing) {
      showAppToast('msg_ai_write_busy'.tr, type: ToastificationType.info);
      return;
    }

    if (action == EditorAiTextWritingAction.generate) {
      setState(() => _promptAction = action);
      return;
    }

    final source = resolveAiTextWriteSource(widget.editor.textCtrl.value);
    if (source.text.trim().isEmpty) {
      showAppToast(
        'msg_ai_write_empty_text'.tr,
        type: ToastificationType.warning,
      );
      return;
    }

    await _runWrite(action: action, source: source, generatePrompt: null);
  }

  Future<void> _submitGenerate() async {
    if (_isProcessing) return;
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      showAppToast(
        'msg_ai_write_empty_prompt'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    final source = resolveAiTextWriteSource(widget.editor.textCtrl.value);
    await _runWrite(
      action: EditorAiTextWritingAction.generate,
      source: source,
      generatePrompt: prompt,
    );
  }

  Future<void> _runWrite({
    required EditorAiTextWritingAction action,
    required EditorAiTextWriteSource source,
    required String? generatePrompt,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final allowed = await ensureCanSpendCoins(
        context: context,
        feature: AiStudioChrome.editorFeatureFor(_providerKind),
      );
      if (!allowed || !mounted) return;

      final result = await _service.write(
        action: action,
        sourceText: source.text,
        generatePrompt: generatePrompt,
      );

      if (!mounted) return;

      final next = applyAiTextWriteResult(
        current: widget.editor.textCtrl.value,
        result: result,
        start: source.start,
        end: source.end,
        isPartialSelection: source.isPartialSelection,
      );
      widget.editor.textCtrl.value = next;

      final direction = looksPrimarilyArabicScript(result)
          ? TextDirection.rtl
          : TextDirection.ltr;
      widget.editor.setMusamiScriptDirection(direction);

      Navigator.of(context).pop();
      showAppToast('msg_ai_write_applied'.tr, type: ToastificationType.success);
    } catch (error) {
      if (!mounted) return;
      showAppToast(_mapError(error), type: ToastificationType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return AppSheetPagePadding(
      bottomExtra: AppDs.space2,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MusamiAiSheetHeader(
              title: 'lbl_text_editor_ai_assist'.tr,
              subtitle: 'msg_ai_write_selection_hint'.tr,
              icon: Icons.auto_awesome_rounded,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AiStudioProviderPicker(
                    value: _providerKind,
                    onChanged: (kind) {
                      setState(() {
                        _providerKind = kind;
                        _service = EditorAiTextWritingService(provider: kind);
                      });
                    },
                  ),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: MusamiAiChrome.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: AppDs.space3.v),
            if (_promptAction == EditorAiTextWritingAction.generate) ...[
              TextField(
                controller: _promptCtrl,
                enabled: !_isProcessing,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: AppDs.textOnDarkPrimary,
                  fontSize: 15,
                  height: 1.35,
                ),
                decoration: MusamiAiChrome.fieldDecoration(
                  hint: 'lbl_ai_write_prompt_hint'.tr,
                ),
              ),
              SizedBox(height: AppDs.space3.v),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppDs.buttonHeight,
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => setState(() => _promptAction = null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppDs.textOnDarkPrimary,
                          side: const BorderSide(color: MusamiAiChrome.hairline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDs.radiusMd),
                          ),
                        ),
                        child: Text('lbl_cancel'.tr),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDs.space2.h),
                  Expanded(
                    child: MusamiAiPrimaryButton(
                      label: 'lbl_ai_write_generate_action'.tr,
                      icon: Icons.auto_awesome_rounded,
                      busy: _isProcessing,
                      onPressed: _submitGenerate,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDs.space3.v),
            ],
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _actions.length,
                separatorBuilder: (_, _) => SizedBox(height: AppDs.space2.v),
                itemBuilder: (context, index) {
                  final item = _actions[index];
                  final enabled = !_isProcessing;
                  return Material(
                    color: MusamiAiChrome.panelDeep,
                    borderRadius: BorderRadius.circular(AppDs.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      onTap: enabled ? () => _onAction(item.action) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: MusamiAiChrome.accent
                                    .withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(AppDs.radiusSm),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color: enabled
                                    ? MusamiAiChrome.accent
                                    : AppDs.textOnDarkSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _labelFor(item.action),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: enabled
                                      ? AppDs.textOnDarkPrimary
                                      : AppDs.textOnDarkSecondary,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: enabled
                                  ? AppDs.textOnDarkSecondary
                                  : Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
