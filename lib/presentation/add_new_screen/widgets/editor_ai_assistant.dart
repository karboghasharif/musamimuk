import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/config/ai_debug_config.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/design_ai_suggestion.dart';
import '../../../data/services/ai_design_assistant_service.dart';
import '../../../data/services/ai_text_service.dart';
import '../../add_text_screen/add_text_ai_actions.dart';
import '../../add_text_screen/models/ai_caption_theme.dart';
import '../bloc/add_new_bloc.dart';
import '../utils/musami_layer_raster_utils.dart';
import 'editor_ai_compose.dart';

/// Orchestrates canvas-level AI Assist flows in the main editor.
class EditorAiAssistant {
  EditorAiAssistant({
    AiDesignAssistantService? designService,
    AiTextService? textService,
    AddTextAiActions? textActions,
    EditorAiCompose? compose,
  })  : _designService = designService ?? AiDesignAssistantService(),
        _textService = textService ?? AiTextService(),
        _textActions = textActions ?? AddTextAiActions(),
        _compose = compose ?? EditorAiCompose();

  final AiDesignAssistantService _designService;
  final AiTextService _textService;
  final AddTextAiActions _textActions;
  final EditorAiCompose _compose;

  Future<void> openAssist({
    required BuildContext context,
    required ProImageEditorState editor,
    required String presetName,
    required int width,
    required int height,
    required String bgDescription,
    required String languageLabel,
    required bool rtl,
    required Future<void> Function(WidgetLayer layer) onRemoveBackground,
  }) async {
    if (!AiDebugConfig.isConfigured) {
      showAppToast(
        'msg_ai_not_configured'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    if (!context.mounted) return;

    final textSummary = _summarizeTextLayers(editor);
    final imageCount = editor.activeLayers.whereType<WidgetLayer>().length;
    final selectedType = context.read<AddNewBloc>().state.selectedElementType;

    List<DesignAiSuggestion> suggestions;
    try {
      suggestions = await _designService.suggestDesignActions(
        presetName: presetName,
        width: width,
        height: height,
        bgDescription: bgDescription,
        textLayersSummary: textSummary,
        imageLayerCount: imageCount,
        selectedLayerType: selectedType,
        languageLabel: languageLabel,
      );
    } catch (_) {
      suggestions = [];
    }

    if (!context.mounted) return;
    if (suggestions.isEmpty) {
      showAppToast(
        'msg_ai_assist_empty'.tr,
        type: ToastificationType.warning,
      );
      return;
    }

    final picked = await _showSuggestionsSheet(
      context: context,
      suggestions: suggestions,
    );
    if (picked == null || !context.mounted) return;

    await _executeSuggestion(
      context: context,
      editor: editor,
      suggestion: picked,
      languageLabel: languageLabel,
      rtl: rtl,
      onRemoveBackground: onRemoveBackground,
    );
  }

  Future<void> _executeSuggestion({
    required BuildContext context,
    required ProImageEditorState editor,
    required DesignAiSuggestion suggestion,
    required String languageLabel,
    required bool rtl,
    required Future<void> Function(WidgetLayer layer) onRemoveBackground,
  }) async {
    switch (suggestion.action) {
      case DesignAiSuggestionAction.addText:
      case DesignAiSuggestionAction.pickTheme:
        await _runAddCaptionFlow(
          context: context,
          editor: editor,
          languageLabel: languageLabel,
          rtl: rtl,
        );
      case DesignAiSuggestionAction.removeBackground:
        final layer = _firstRasterImageLayer(editor);
        if (layer == null) {
          showAppToast(
            'msg_ai_assist_no_image'.tr,
            type: ToastificationType.warning,
          );
          return;
        }
        _selectLayer(context, editor, layer.id, 'image');
        await onRemoveBackground(layer);
      case DesignAiSuggestionAction.editText:
        final layer = _firstTextLayer(editor);
        if (layer == null) {
          showAppToast(
            'msg_ai_assist_no_text'.tr,
            type: ToastificationType.warning,
          );
          return;
        }
        _selectLayer(context, editor, layer.id, 'text');
        editor.editTextLayer(layer);
      case DesignAiSuggestionAction.addAsset:
      case DesignAiSuggestionAction.composeDesign:
        await _compose.openCompose(
          context: context,
          editor: editor,
          initialPrompt: suggestion.detail.isNotEmpty
              ? suggestion.detail
              : suggestion.title,
        );
      case DesignAiSuggestionAction.setBackground:
        showAppToast(
          'msg_ai_compose_phase2'.tr,
          type: ToastificationType.warning,
        );
    }
  }

  Future<void> _runAddCaptionFlow({
    required BuildContext context,
    required ProImageEditorState editor,
    required String languageLabel,
    required bool rtl,
  }) async {
    if (!context.mounted) return;

    final theme = await _pickCaptionTheme(context);
    if (theme == null || !context.mounted) return;

    try {
      final suggestions = await _textService.captionSuggestions(
        languageLabel: languageLabel,
        theme: theme.aiName,
      );
      if (!context.mounted) return;
      if (suggestions.isEmpty) {
        showAppToast(
          'msg_ai_suggestions_empty'.tr,
          type: ToastificationType.warning,
        );
        return;
      }

      final caption = await _showCaptionPicker(
        context: context,
        suggestions: suggestions,
        rtl: rtl,
      );
      if (caption == null || caption.trim().isEmpty || !context.mounted) {
        return;
      }

      addCaptionTextLayer(
        context: context,
        editor: editor,
        caption: _textActions.applyTextTrim(caption),
        rtl: rtl,
      );
      showAppToast(
        'msg_ai_caption_added'.tr,
        type: ToastificationType.success,
      );
    } on AiTextException catch (e) {
      if (!context.mounted) return;
      showAppToast(
        e.message.isNotEmpty ? e.message : 'msg_ai_failed'.tr,
        type: ToastificationType.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      showAppToast('msg_ai_failed'.tr, type: ToastificationType.error);
    }
  }

  static String _summarizeTextLayers(ProImageEditorState editor) {
    final parts = <String>[];
    for (final layer in editor.activeLayers) {
      if (layer is! TextLayer) continue;
      final t = layer.text.trim();
      if (t.isEmpty) continue;
      parts.add(t.length > 48 ? '${t.substring(0, 48)}…' : t);
    }
    return parts.join('; ');
  }

  static WidgetLayer? _firstRasterImageLayer(ProImageEditorState editor) {
    for (final layer in editor.activeLayers) {
      if (layer is WidgetLayer &&
          musamiWidgetLayerHasRasterCropSource(layer.widget)) {
        return layer;
      }
    }
    for (final layer in editor.activeLayers) {
      if (layer is WidgetLayer) return layer;
    }
    return null;
  }

  static TextLayer? _firstTextLayer(ProImageEditorState editor) {
    for (final layer in editor.activeLayers) {
      if (layer is TextLayer) return layer;
    }
    return null;
  }

  static void _selectLayer(
    BuildContext context,
    ProImageEditorState editor,
    String id,
    String type,
  ) {
    editor.layerInteractionManager.selectedLayerId = id;
    context.read<AddNewBloc>().add(
          EditorSelectionChangedEvent(
            selectedElementId: id,
            selectedElementType: type,
          ),
        );
    editor.setState(() {});
  }

  static void addCaptionTextLayer({
    required BuildContext context,
    required ProImageEditorState editor,
    required String caption,
    required bool rtl,
  }) {
    final body = editor.sizesManager.bodySize;
    final canvasSize = body.isEmpty || body == Size.infinite
        ? MediaQuery.sizeOf(context)
        : body;
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final maxW = canvasSize.width * 0.85;

    final layer = TextLayer(
      text: caption,
      color: const Color(0xFF000000),
      background: const Color(0x00000000),
      colorMode: LayerBackgroundMode.onlyColor,
      align: rtl ? TextAlign.right : TextAlign.center,
      fontScale: 1.0,
      maxTextWidth: maxW,
      textStyle: const TextStyle(
        fontSize: 32,
        color: Color(0xFF000000),
        height: 1.35,
      ),
      offset: Offset(
        center.dx - maxW / 2,
        center.dy - 48,
      ),
    );

    editor.addLayer(layer);
    _selectLayer(context, editor, layer.id, 'text');
  }

  Future<DesignAiSuggestion?> _showSuggestionsSheet({
    required BuildContext context,
    required List<DesignAiSuggestion> suggestions,
  }) {
    return showAppModalBottomSheet<DesignAiSuggestion>(
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
                  'lbl_ai_design_suggestions'.tr,
                  style: AppDs.sheetTitle(
                    theme,
                    color: AppDs.textOnDarkPrimary,
                  ),
                ),
                SizedBox(height: AppDs.space4.v),
                ...suggestions.map(
                  (s) => Padding(
                    padding: EdgeInsets.only(bottom: AppDs.space2.v),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(s),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _iconForAction(s.action),
                                  size: AppDs.iconSm.adaptSize,
                                  color: theme.colorScheme.primary,
                                ),
                                SizedBox(width: AppDs.space2.h),
                                Expanded(
                                  child: AppText(
                                    s.id.startsWith('heuristic_')
                                        ? s.action.labelKey.tr
                                        : s.title,
                                    variant: AppTextVariant.body,
                                  ),
                                ),
                              ],
                            ),
                            if (s.detail.isNotEmpty) ...[
                              SizedBox(height: AppDs.space1.v),
                              AppText(
                                s.detail,
                                variant: AppTextVariant.caption,
                              ),
                            ],
                          ],
                        ),
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

  Future<String?> _showCaptionPicker({
    required BuildContext context,
    required List<String> suggestions,
    required bool rtl,
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
                        alignment: rtl
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

  static IconData _iconForAction(DesignAiSuggestionAction action) {
    return switch (action) {
      DesignAiSuggestionAction.addText => Icons.title_rounded,
      DesignAiSuggestionAction.removeBackground =>
        Icons.layers_clear_rounded,
      DesignAiSuggestionAction.pickTheme => Icons.palette_outlined,
      DesignAiSuggestionAction.editText => Icons.edit_rounded,
      DesignAiSuggestionAction.addAsset => Icons.add_photo_alternate_outlined,
      DesignAiSuggestionAction.setBackground => Icons.format_color_fill,
      DesignAiSuggestionAction.composeDesign => Icons.draw_rounded,
    };
  }
}

extension AddTextAiActionsTrim on AddTextAiActions {
  String applyTextTrim(String text) {
    var out = text.trim();
    if (out.length > AddTextAiActions.maxLength) {
      out = out.substring(0, AddTextAiActions.maxLength);
    }
    return out;
  }
}
