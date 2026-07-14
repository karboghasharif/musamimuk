import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/config/ai_debug_config.dart';
import '../../core/utils/app_toast.dart';
import '../../data/services/ai_text_service.dart';
import 'models/ai_caption_theme.dart';
import 'models/translate_target_language.dart';

/// Shared AI actions for Add Text flows (standalone screen + in-editor).
class AddTextAiActions {
  AddTextAiActions({AiTextService? aiText})
      : _aiText = aiText ?? AiTextService();

  final AiTextService _aiText;

  static const int maxLength = 250;

  String languageLabel(bool isUrdu) => isUrdu ? 'Urdu' : 'English';

  /// Opens a sheet so the user picks the target language, then translates.
  Future<void> translateWithLanguagePicker({
    required BuildContext context,
    required TextEditingController controller,
    required bool isUrdu,
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
  }) async {
    final t = controller.text.trim();
    if (t.isEmpty) {
      showAppToast('msg_translate_empty'.tr, type: ToastificationType.warning);
      return;
    }
    if (isBusy || !context.mounted) return;

    final target = await _pickTranslateTargetLanguage(context);
    if (target == null || !isMounted()) return;

    await _translateTo(
      controller: controller,
      target: target,
      sourceHint: TranslateTargetLanguage.fromInputLanguage(isUrdu),
      isMounted: isMounted,
      isBusy: isBusy,
      setBusy: setBusy,
    );
  }

  Future<TranslateTargetLanguage?> _pickTranslateTargetLanguage(
    BuildContext context,
  ) {
    return showAppModalBottomSheet<TranslateTargetLanguage>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'lbl_translate_select_language'.tr,
                  style: AppDs.sheetTitle(
                    theme,
                    color: AppDs.textOnDarkPrimary,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                AppText(
                  'msg_translate_select_language'.tr,
                  variant: AppTextVariant.secondary,
                ),
                SizedBox(height: AppDs.space4.v),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: TranslateTargetLanguage.pickerOptions
                          .map(
                            (lang) => Padding(
                              padding: EdgeInsets.only(bottom: AppDs.space2.v),
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(lang),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(
                                    double.infinity,
                                    AppDs.buttonHeight.v,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                  foregroundColor: AppDs.textOnDarkPrimary,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.translate_rounded,
                                        size: AppDs.iconSm.adaptSize,
                                        color: theme.colorScheme.primary,
                                      ),
                                      SizedBox(width: AppDs.space3.h),
                                      Expanded(
                                        child: AppText(
                                          lang.labelKey.tr,
                                          variant: AppTextVariant.body,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _translateTo({
    required TextEditingController controller,
    required TranslateTargetLanguage target,
    required TranslateTargetLanguage sourceHint,
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
  }) async {
    final t = controller.text.trim();
    if (t.isEmpty) {
      showAppToast('msg_translate_empty'.tr, type: ToastificationType.warning);
      return;
    }

    await _runTranslateTask(
      isMounted: isMounted,
      isBusy: isBusy,
      setBusy: setBusy,
      task: () async {
        try {
          final withTashkeela = target.requiresArabicTashkeela;
          var translated = await _aiText.translate(
            text: t.length > 450 ? t.substring(0, 450) : t,
            targetLang: target.aiName,
            withArabicTashkeela: withTashkeela,
          );
          if (!isMounted()) return;
          if (withTashkeela && !AiTextService.hasArabicTashkeela(translated)) {
            translated = await _ensureArabicTashkeela(translated);
          }
          applyText(controller, translated);
          showAppToast('msg_translate_done'.tr);
        } on AiTextException catch (e) {
          if (!isMounted()) return;
          final fallbackOk = await _translateWithMyMemory(
            controller: controller,
            sourceHint: sourceHint,
            target: target,
            isMounted: isMounted,
          );
          if (!fallbackOk && isMounted() && e.message.isNotEmpty) {
            showAppToast(e.message, type: ToastificationType.warning);
          }
        } catch (_) {
          if (!isMounted()) return;
          await _translateWithMyMemory(
            controller: controller,
            sourceHint: sourceHint,
            target: target,
            isMounted: isMounted,
          );
        }
      },
    );
  }

  void applyText(TextEditingController controller, String text) {
    var out = text.trim();
    if (out.length > maxLength) {
      out = out.substring(0, maxLength);
    }
    controller.text = out;
    controller.selection = TextSelection.collapsed(offset: out.length);
  }

  String beautifyLocal(String raw, bool isUrdu) {
    var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!isUrdu && s.isNotEmpty) {
      final chunks = s.split(RegExp(r'(?<=[.!?])\s+'));
      return chunks
          .map((p) {
            if (p.isEmpty) return p;
            return p[0].toUpperCase() + p.substring(1);
          })
          .join(' ');
    }
    return s;
  }

  Future<void> beautify({
    required BuildContext context,
    required TextEditingController controller,
    required bool isUrdu,
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
  }) async {
    final t = controller.text.trim();
    if (t.isEmpty) {
      showAppToast('msg_translate_empty'.tr, type: ToastificationType.warning);
      return;
    }

    await _runAiTask(
      isMounted: isMounted,
      isBusy: isBusy,
      setBusy: setBusy,
      task: () async {
        try {
          final improved = await _aiText.beautify(
            text: t,
            languageLabel: languageLabel(isUrdu),
          );
          if (!isMounted()) return;
          applyText(controller, improved);
          showAppToast('msg_translate_done'.tr);
        } on AiTextException catch (e) {
          if (!isMounted()) return;
          applyText(controller, beautifyLocal(t, isUrdu));
          showAppToast(
            e.message.isNotEmpty ? e.message : 'msg_ai_failed'.tr,
            type: ToastificationType.warning,
          );
        } catch (_) {
          if (!isMounted()) return;
          showAppToast('msg_ai_failed'.tr, type: ToastificationType.error);
        }
      },
    );
  }

  Future<void> shorten({
    required BuildContext context,
    required TextEditingController controller,
    required bool isUrdu,
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
  }) async {
    final t = controller.text.trim();
    if (t.isEmpty) {
      showAppToast('msg_translate_empty'.tr, type: ToastificationType.warning);
      return;
    }

    await _runAiTask(
      isMounted: isMounted,
      isBusy: isBusy,
      setBusy: setBusy,
      task: () async {
        try {
          final shortened = await _aiText.shorten(
            text: t,
            languageLabel: languageLabel(isUrdu),
          );
          if (!isMounted()) return;
          applyText(controller, shortened);
          showAppToast('msg_ai_shorten_done'.tr);
        } on AiTextException catch (e) {
          if (!isMounted()) return;
          showAppToast(
            e.message.isNotEmpty ? e.message : 'msg_ai_failed'.tr,
            type: ToastificationType.warning,
          );
        } catch (_) {
          if (!isMounted()) return;
          showAppToast('msg_ai_failed'.tr, type: ToastificationType.error);
        }
      },
    );
  }

  Future<void> makePunchy({
    required BuildContext context,
    required TextEditingController controller,
    required bool isUrdu,
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
  }) async {
    final t = controller.text.trim();
    if (t.isEmpty) {
      showAppToast('msg_translate_empty'.tr, type: ToastificationType.warning);
      return;
    }

    await _runAiTask(
      isMounted: isMounted,
      isBusy: isBusy,
      setBusy: setBusy,
      task: () async {
        try {
          final punchy = await _aiText.makePunchy(
            text: t,
            languageLabel: languageLabel(isUrdu),
          );
          if (!isMounted()) return;
          applyText(controller, punchy);
          showAppToast('msg_ai_punchy_done'.tr);
        } on AiTextException catch (e) {
          if (!isMounted()) return;
          showAppToast(
            e.message.isNotEmpty ? e.message : 'msg_ai_failed'.tr,
            type: ToastificationType.warning,
          );
        } catch (_) {
          if (!isMounted()) return;
          showAppToast('msg_ai_failed'.tr, type: ToastificationType.error);
        }
      },
    );
  }

  Future<AiCaptionTheme?> _pickCaptionTheme(BuildContext context) {
    return showAppModalBottomSheet<AiCaptionTheme>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'lbl_ai_theme_picker_title'.tr,
                  style: AppDs.sheetTitle(
                    theme,
                    color: AppDs.textOnDarkPrimary,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                AppText(
                  'msg_ai_theme_picker'.tr,
                  variant: AppTextVariant.secondary,
                ),
                SizedBox(height: AppDs.space4.v),
                Wrap(
                  spacing: AppDs.space2.h,
                  runSpacing: AppDs.space2.v,
                  children: AiCaptionTheme.pickerOptions.map((chip) {
                    return AppChip(
                      label: chip.labelKey.tr,
                      selected: false,
                      onSelected: (_) => Navigator.of(ctx).pop(chip),
                    );
                  }).toList(),
                ),
                SizedBox(height: AppDs.space2.v),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showSuggestions({
    required BuildContext context,
    required TextEditingController controller,
    required bool isUrdu,
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
  }) async {
    if (isBusy) return;
    if (!AiDebugConfig.isConfigured) {
      showAppToast(
        'msg_ai_not_configured'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    if (!context.mounted) return;

    final captionTheme = await _pickCaptionTheme(context);
    if (captionTheme == null || !isMounted()) return;

    final seed = controller.text.trim();

    await _runAiTask(
      isMounted: isMounted,
      isBusy: isBusy,
      setBusy: setBusy,
      task: () async {
        try {
          final suggestions = await _aiText.captionSuggestions(
            languageLabel: languageLabel(isUrdu),
            seed: seed.isEmpty ? null : seed,
            theme: captionTheme.aiName,
          );
          if (!isMounted()) return;
          if (suggestions.isEmpty) {
            showAppToast(
              'msg_ai_suggestions_empty'.tr,
              type: ToastificationType.warning,
            );
            return;
          }
          if (!context.mounted) return;
          final picked = await _showCaptionPicker(
            context: context,
            suggestions: suggestions,
            isUrdu: isUrdu,
          );
          if (!isMounted() || picked == null || picked.trim().isEmpty) return;
          applyText(controller, picked);
        } catch (_) {
          if (!isMounted()) return;
          showAppToast('msg_ai_failed'.tr, type: ToastificationType.error);
        }
      },
    );
  }

  Future<String?> _showCaptionPicker({
    required BuildContext context,
    required List<String> suggestions,
    required bool isUrdu,
  }) {
    return showAppModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'lbl_ai_suggestions_title'.tr,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: AppDs.space3.v),
                ...suggestions.map(
                  (s) => Padding(
                    padding: EdgeInsets.only(bottom: AppDs.space2.v),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(s),
                      child: Align(
                        alignment: isUrdu
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Text(s, textAlign: TextAlign.start),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _ensureArabicTashkeela(String text) async {
    if (!AiDebugConfig.hasGemini) return text;
    try {
      return await _aiText.applyArabicTashkeela(text);
    } catch (_) {
      return text;
    }
  }

  Future<void> _runAiTask({
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
    required Future<void> Function() task,
  }) async {
    if (isBusy) return;
    if (!AiDebugConfig.isConfigured) {
      showAppToast(
        'msg_ai_not_configured'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    setBusy(true);
    try {
      await task();
    } finally {
      if (isMounted()) setBusy(false);
    }
  }

  Future<void> _runTranslateTask({
    required bool Function() isMounted,
    required bool isBusy,
    required void Function(bool) setBusy,
    required Future<void> Function() task,
  }) async {
    if (isBusy) return;
    if (!AiDebugConfig.hasGemini) {
      showAppToast(
        'msg_gemini_not_configured'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    setBusy(true);
    try {
      await task();
    } finally {
      if (isMounted()) setBusy(false);
    }
  }

  Future<bool> _translateWithMyMemory({
    required TextEditingController controller,
    required TranslateTargetLanguage sourceHint,
    required TranslateTargetLanguage target,
    required bool Function() isMounted,
  }) async {
    final t = controller.text.trim();
    if (t.isEmpty) {
      showAppToast('msg_translate_empty'.tr, type: ToastificationType.warning);
      return false;
    }

    final sourceCode = sourceHint.memoryCode;
    final targetCode = target.memoryCode;
    if (sourceCode == null ||
        targetCode == null ||
        sourceCode == targetCode) {
      if (!isMounted()) return false;
      showAppToast('msg_translate_failed'.tr, type: ToastificationType.error);
      return false;
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 14),
        receiveTimeout: const Duration(seconds: 14),
      ),
    );

    try {
      final pair = '$sourceCode|$targetCode';
      final q = t.length > 450 ? t.substring(0, 450) : t;
      final r = await dio.get<Map<String, dynamic>>(
        'https://api.mymemory.translated.net/get',
        queryParameters: <String, dynamic>{'q': q, 'langpair': pair},
      );
      final data = r.data;
      final block = data?['responseData'];
      final translated = block is Map<String, dynamic>
          ? block['translatedText'] as String?
          : null;
      if (translated == null || translated.isEmpty) {
        throw StateError('empty translation');
      }
      if (!isMounted()) return false;
      var result = translated;
      if (target.requiresArabicTashkeela) {
        result = await _ensureArabicTashkeela(result);
      }
      applyText(controller, result);
      showAppToast('msg_translate_done'.tr);
      return true;
    } catch (_) {
      if (!isMounted()) return false;
      showAppToast('msg_translate_failed'.tr, type: ToastificationType.error);
      return false;
    }
  }
}
